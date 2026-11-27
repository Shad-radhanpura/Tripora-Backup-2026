import 'package:cloud_firestore/cloud_firestore.dart';

import 'saved_trip.dart';

/// A document in the existing `users` collection (document ID = Auth UID).
///
/// Signup writes uid, name, email and createdAt. Sign-ins since this update
/// also write lastLoginAt and loginCount. Older documents may not have
/// every field, so each one is optional.
class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final int? loginCount;

  const AppUser({
    required this.uid,
    this.name,
    this.email,
    this.createdAt,
    this.lastLoginAt,
    this.loginCount,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    String? text(Object? value) {
      final result = value?.toString().trim();
      return result == null || result.isEmpty ? null : result;
    }

    final count = data['loginCount'];

    return AppUser(
      uid: id,
      name: text(data['name']) ?? text(data['displayName']),
      email: text(data['email']),
      createdAt: parseFirestoreDate(data['createdAt']),
      lastLoginAt: parseFirestoreDate(data['lastLoginAt']),
      loginCount: count is num ? count.toInt() : null,
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});

  String get displayName => name ?? email ?? 'Unnamed user';

  String get initials {
    final source = (name ?? email ?? '?').trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source[0].toUpperCase();
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [name, email, uid]
        .whereType<String>()
        .any((value) => value.toLowerCase().contains(q));
  }
}
