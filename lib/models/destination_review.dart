import 'package:cloud_firestore/cloud_firestore.dart';

import 'saved_trip.dart' show parseFirestoreDate;

/// Moderation states for a review.
class ReviewStatus {
  ReviewStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  static const List<String> all = [pending, approved, rejected];

  static String label(String status) => switch (status) {
    pending => 'Pending approval',
    approved => 'Approved',
    rejected => 'Not published',
    _ => status,
  };
}

/// Limits enforced by the app and by the security rules alike.
class ReviewRules {
  ReviewRules._();

  static const int minTextLength = 10;
  static const int maxTextLength = 1000;
  static const int maxNameLength = 60;

  /// Destinations that accept reviews. This must match the destinationId
  /// allow-list in firestore.rules (and firestore.rules.proposed). Destinations
  /// added to the catalogue later show no review section until the rules
  /// allow them, so writes are never sent to Firestore only to be refused.
  static const List<String> reviewableDestinationIds = [
    'manali', 'goa', 'jaipur', 'alappuzha', 'ladakh', 'rishikesh', 'udaipur',
    'varanasi', 'andaman', 'agra', 'darjeeling', 'dubai', 'bali', 'paris',
    'singapore', 'tokyo',
  ];

  static bool isReviewable(String destinationId) =>
      reviewableDestinationIds.contains(destinationId);

  /// Returns an error message, or null if the text is acceptable.
  static String? validateText(String text) {
    final trimmed = text.trim();
    if (trimmed.length < minTextLength) {
      return 'Write at least $minTextLength characters about your experience.';
    }
    if (trimmed.length > maxTextLength) {
      return 'Keep your review under $maxTextLength characters.';
    }
    return null;
  }

  /// Document ID for one user's review of one destination. Using a fixed
  /// ID means a user can only ever have one review per destination.
  static String documentId(String destinationId, String userId) =>
      '${destinationId}_$userId';
}

/// One review in the `reviews` collection.
class DestinationReview {
  final String id;
  final String destinationId;
  final String userId;
  final String displayName;
  final int rating;
  final String text;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DestinationReview({
    required this.id,
    required this.destinationId,
    required this.userId,
    required this.displayName,
    required this.rating,
    required this.text,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DestinationReview.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rating = data['rating'];
    final name = data['displayName']?.toString().trim() ?? '';
    return DestinationReview(
      id: doc.id,
      destinationId: data['destinationId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      displayName: name.isEmpty ? 'Traveller' : name,
      rating: rating is num ? rating.toInt() : 0,
      text: data['text']?.toString() ?? '',
      status: data['status']?.toString() ?? ReviewStatus.pending,
      createdAt: parseFirestoreDate(data['createdAt']),
      updatedAt: parseFirestoreDate(data['updatedAt']),
    );
  }

  bool get isApproved => status == ReviewStatus.approved;
}

/// Statistics derived from review documents.
///
/// Totals and averages are never stored or supplied by the client. They are
/// calculated from the review documents, and only approved reviews count
/// towards the public average.
class ReviewStats {
  final int count;
  final double? average;

  const ReviewStats({required this.count, required this.average});

  /// Statistics over approved reviews only.
  factory ReviewStats.fromApproved(Iterable<DestinationReview> reviews) {
    var count = 0;
    var total = 0;
    for (final review in reviews) {
      if (!review.isApproved) continue;
      if (review.rating < 1 || review.rating > 5) continue;
      count++;
      total += review.rating;
    }
    return ReviewStats(
      count: count,
      average: count == 0 ? null : total / count,
    );
  }
}

/// Counts per moderation state, for the admin statistics.
class ModerationCounts {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final double? averageApproved;

  const ModerationCounts({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.averageApproved,
  });

  factory ModerationCounts.from(List<DestinationReview> reviews) {
    final approved = reviews.where((r) => r.isApproved).toList();
    return ModerationCounts(
      total: reviews.length,
      pending: reviews.where((r) => r.status == ReviewStatus.pending).length,
      approved: approved.length,
      rejected: reviews.where((r) => r.status == ReviewStatus.rejected).length,
      averageApproved: ReviewStats.fromApproved(approved).average,
    );
  }
}
