import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_firebase.dart';

/// One administrative action, as stored in admin_audit.
class AuditEntry {
  final String id;
  final String actorUid;
  final String action;
  final String target;
  final String summary;
  final DateTime? createdAt;

  const AuditEntry({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.target,
    required this.summary,
    this.createdAt,
  });

  factory AuditEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AuditEntry(
      id: doc.id,
      actorUid: (data['actorUid'] as String?) ?? '',
      action: (data['action'] as String?) ?? '',
      target: (data['target'] as String?) ?? '',
      summary: (data['summary'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Writes and reads the admin audit trail.
///
/// Entries are added in the same batch as the change they describe, so a
/// change can never be saved without its record. Only verified admins can
/// write or read entries (see firestore.rules.proposed).
class AuditService {
  AuditService._();

  static const int pageSize = 100;

  static CollectionReference<Map<String, dynamic>> get _entries =>
      AppFirebase.db.collection('admin_audit');

  /// Adds an audit entry to [batch]. Call batch.commit() to save it.
  static void addTo(
    WriteBatch batch, {
    required String actorUid,
    required String action,
    required String target,
    required String summary,
  }) {
    batch.set(_entries.doc(), {
      'actorUid': actorUid,
      'action': action,
      'target': target,
      'summary': summary,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Most recent entries first. Admins only.
  static Stream<List<AuditEntry>> recent() {
    return _entries
        .orderBy('createdAt', descending: true)
        .limit(pageSize)
        .snapshots()
        .map((s) => s.docs.map(AuditEntry.fromDoc).toList());
  }
}
