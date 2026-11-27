import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_ticket.dart';
import 'app_firebase.dart';
import 'audit_service.dart';
import 'feedback_outbox.dart';

/// Where a report ended up.
enum SubmitOutcome {
  /// Written to the Tripora team's database.
  sent,

  /// Could not reach the team, so it is kept on this device. Nothing is
  /// sent to the admin until it is sent again from My feedback & issues.
  savedOnDevice,
}

/// Writes one support_tickets document. Injected in tests.
typedef TicketWriter = Future<void> Function(Map<String, dynamic> data);

/// Feedback and help requests stored in support_tickets.
///
/// Users create and withdraw their own tickets. Admins change the status and
/// reply; every admin change is written together with an audit entry.
class SupportService {
  SupportService._();

  static CollectionReference<Map<String, dynamic>> get _tickets =>
      AppFirebase.db.collection('support_tickets');

  /// Checks a new report. Throws [ArgumentError] with the first problem found.
  static void validate({
    required String category,
    required String priority,
    required String subject,
    required String message,
  }) {
    if (!SupportCategory.all.contains(category)) {
      throw ArgumentError('Choose what your feedback is about.');
    }
    if (!SupportPriority.all.contains(priority)) {
      throw ArgumentError('Choose how urgent this is.');
    }
    final subjectError = SupportRules.validateSubject(subject.trim());
    if (subjectError != null) throw ArgumentError(subjectError);
    final messageError = SupportRules.validateMessage(message.trim());
    if (messageError != null) throw ArgumentError(messageError);
  }

  /// Sends a new report to the Tripora team.
  ///
  /// If the cloud write fails (for example the database rules do not accept
  /// the report yet, or the device is offline), the report is kept on this
  /// device and [SubmitOutcome.savedOnDevice] is returned. It is never shown
  /// as sent. Throws [ArgumentError] for invalid input, and [StateError] when
  /// the report could not be sent or saved on the device either.
  static Future<SubmitOutcome> submit({
    required String userId,
    required String category,
    required String priority,
    required String subject,
    required String message,
    TicketWriter? writer,
    FeedbackOutbox? outbox,
  }) async {
    validate(
      category: category,
      priority: priority,
      subject: subject,
      message: message,
    );
    final data = _newTicketData(
      userId: userId,
      category: category,
      priority: priority,
      subject: subject.trim(),
      message: message.trim(),
    );
    try {
      await (writer ?? _writeToCloud)(data);
      return SubmitOutcome.sent;
    } catch (_) {
      // Keep the report on the device rather than losing it.
    }

    final draft = FeedbackDraft(
      id: 'local_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      userId: userId,
      category: category,
      priority: priority,
      subject: subject.trim(),
      message: message.trim(),
      savedAt: DateTime.now(),
    );
    try {
      await (outbox ?? FeedbackOutbox.instance).add(draft);
      return SubmitOutcome.savedOnDevice;
    } catch (_) {
      throw StateError(
        'Your report could not be sent, and this device could not save it. '
        'Check your connection and try again.',
      );
    }
  }

  /// Tries again to send a report that is saved on this device. Returns true
  /// when it reached the team; the device copy is then removed.
  static Future<bool> sendDraft(
    FeedbackDraft draft, {
    TicketWriter? writer,
    FeedbackOutbox? outbox,
  }) async {
    final data = _newTicketData(
      userId: draft.userId,
      category: draft.category,
      priority: draft.priority,
      subject: draft.subject,
      message: draft.message,
    );
    try {
      await (writer ?? _writeToCloud)(data);
    } catch (_) {
      return false;
    }
    await (outbox ?? FeedbackOutbox.instance).remove(draft.id);
    return true;
  }

  /// Creates an open ticket for [userId]. Throws [ArgumentError] when the
  /// input breaks the rules, before anything is sent to Firestore.
  static Future<void> create({
    required String userId,
    required String category,
    required String subject,
    required String message,
  }) async {
    final cleanSubject = subject.trim();
    final cleanMessage = message.trim();
    if (!SupportCategory.isKnown(category)) {
      throw ArgumentError('Choose a topic for your request.');
    }
    final subjectError = SupportRules.validateSubject(cleanSubject);
    if (subjectError != null) throw ArgumentError(subjectError);
    final messageError = SupportRules.validateMessage(cleanMessage);
    if (messageError != null) throw ArgumentError(messageError);

    await _tickets.doc().set({
      'userId': userId,
      'category': category,
      'subject': cleanSubject,
      'message': cleanMessage,
      'status': SupportStatus.open,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// The signed-in user's own tickets, newest first.
  static Stream<List<SupportTicket>> myTickets(String uid) {
    return _tickets
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) => _sorted(s.docs.map(SupportTicket.fromDoc).toList()));
  }

  /// Every ticket, newest first. Admins only.
  static Stream<List<SupportTicket>> allTickets() {
    return _tickets.snapshots().map(
      (s) => _sorted(s.docs.map(SupportTicket.fromDoc).toList()),
    );
  }

  /// Lets the owner withdraw a ticket that has not been answered yet.
  static Future<void> withdraw(SupportTicket ticket) {
    return _tickets.doc(ticket.id).delete();
  }

  /// Admin action: change the status and/or send a reply. The ticket update
  /// and its audit entry are committed together.
  static Future<void> adminUpdate({
    required String adminUid,
    required SupportTicket ticket,
    required String status,
    String? reply,
  }) async {
    if (!SupportStatus.all.contains(status)) {
      throw ArgumentError('Unknown status: $status');
    }
    final cleanReply = reply?.trim();
    if (cleanReply != null && cleanReply.length > SupportRules.messageMax) {
      throw ArgumentError(
        'Keep the reply under ${SupportRules.messageMax} characters.',
      );
    }

    final data = <String, Object?>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final replying = cleanReply != null && cleanReply.isNotEmpty;
    if (replying) {
      data['adminReply'] = cleanReply;
      data['repliedAt'] = FieldValue.serverTimestamp();
    }

    final batch = AppFirebase.db.batch();
    batch.update(_tickets.doc(ticket.id), data);
    AuditService.addTo(
      batch,
      actorUid: adminUid,
      action: replying ? 'support_reply' : 'support_status',
      target: 'support_tickets/${ticket.id}',
      summary: replying
          ? 'Replied and set status to ${SupportStatus.label(status)}'
          : 'Set status to ${SupportStatus.label(status)}',
    );
    await batch.commit();
  }

  static Map<String, dynamic> _newTicketData({
    required String userId,
    required String category,
    required String priority,
    required String subject,
    required String message,
  }) {
    return {
      'userId': userId,
      'category': category,
      'priority': priority,
      'subject': subject,
      'message': message,
      'status': SupportStatus.open,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> _writeToCloud(Map<String, dynamic> data) =>
      _tickets.doc().set(data).timeout(const Duration(seconds: 15));

  static List<SupportTicket> _sorted(List<SupportTicket> tickets) {
    tickets.sort((a, b) {
      final left = a.createdAt;
      final right = b.createdAt;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
    return tickets;
  }
}
