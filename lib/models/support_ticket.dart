import 'package:cloud_firestore/cloud_firestore.dart';

/// What the feedback is about. The first five are offered for new reports.
/// The last four are topics from requests sent before feedback types
/// existed; they are still shown so older requests keep their label.
class SupportCategory {
  SupportCategory._();

  static const String bug = 'bug';
  static const String feature = 'feature';
  static const String improvement = 'improvement';
  static const String ui = 'ui';
  static const String help = 'help';

  static const String booking = 'booking';
  static const String trip = 'trip';
  static const String account = 'account';
  static const String other = 'other';

  static const List<String> all = [bug, feature, improvement, ui, help];
  static const List<String> legacy = [booking, trip, account, other];

  static bool isKnown(String category) =>
      all.contains(category) || legacy.contains(category);

  static String label(String category) => switch (category) {
    bug => 'Report a bug',
    feature => 'Suggest a new feature',
    improvement => 'Improve an existing feature',
    ui => 'Design or usability problem',
    help => 'Ask for help',
    booking => 'Booking (older request)',
    trip => 'Trip planning (older request)',
    account => 'Account (older request)',
    _ => 'Other (older request)',
  };

  /// Short guidance shown under the topic picker.
  static String hint(String category) => switch (category) {
    bug => 'Something broke or showed an error. Say what you did and what happened.',
    feature => 'An idea for something Tripora does not do yet.',
    improvement => 'Something that works but could be clearer or faster.',
    ui => 'A screen that is hard to read, use or find.',
    help => 'A question about how to use Tripora.',
    _ => '',
  };
}

/// How urgent the feedback is, chosen by the traveller.
class SupportPriority {
  SupportPriority._();

  static const String low = 'low';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String urgent = 'urgent';

  static const List<String> all = [low, normal, high, urgent];

  static String label(String priority) => switch (priority) {
    low => 'Low',
    high => 'High',
    urgent => 'Urgent',
    _ => 'Normal',
  };

  /// Requests from before priorities existed count as normal.
  static String fromData(String? value) =>
      all.contains(value) ? value! : normal;
}

/// Workflow states. A new report starts as "Submitted"; the team moves it on.
class SupportStatus {
  SupportStatus._();

  static const String open = 'open';
  static const String inReview = 'in_review';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';

  static const List<String> all = [open, inReview, inProgress, resolved, closed];

  static String label(String status) => switch (status) {
    inReview => 'In review',
    inProgress => 'In progress',
    resolved => 'Resolved',
    closed => 'Closed',
    _ => 'Submitted',
  };
}

/// Input checks shared by the form and the service. The security rules
/// enforce the same limits on the server.
class SupportRules {
  SupportRules._();

  static const int subjectMin = 3;
  static const int subjectMax = 100;
  static const int messageMin = 10;
  static const int messageMax = 1000;

  static String? validateSubject(String? value) {
    final text = (value ?? '').trim();
    if (text.length < subjectMin) {
      return 'Add a short subject (at least $subjectMin characters).';
    }
    if (text.length > subjectMax) {
      return 'Keep the subject under $subjectMax characters.';
    }
    return null;
  }

  static String? validateMessage(String? value) {
    final text = (value ?? '').trim();
    if (text.length < messageMin) {
      return 'Describe the problem in at least $messageMin characters.';
    }
    if (text.length > messageMax) {
      return 'Keep the message under $messageMax characters.';
    }
    return null;
  }
}

/// One feedback report or help request. [adminReply] is empty until the team
/// answers.
class SupportTicket {
  final String id;
  final String userId;
  final String category;
  final String priority;
  final String subject;
  final String message;
  final String status;
  final String adminReply;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? repliedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.category,
    this.priority = SupportPriority.normal,
    required this.subject,
    required this.message,
    required this.status,
    this.adminReply = '',
    this.createdAt,
    this.updatedAt,
    this.repliedAt,
  });

  bool get hasReply => adminReply.trim().isNotEmpty;

  factory SupportTicket.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SupportTicket(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      category: (data['category'] as String?) ?? SupportCategory.other,
      priority: SupportPriority.fromData(data['priority'] as String?),
      subject: (data['subject'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      status: (data['status'] as String?) ?? SupportStatus.open,
      adminReply: (data['adminReply'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      repliedAt: (data['repliedAt'] as Timestamp?)?.toDate(),
    );
  }
}
