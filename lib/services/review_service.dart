import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/destination_review.dart';
import 'app_firebase.dart';

/// Reads and writes destination reviews in the `reviews` collection.
///
/// Document ID = "{destinationId}_{userId}", so a user has at most one review
/// per destination. Every save or edit sets the status back to "pending";
/// only an admin can approve or reject a review.
class ReviewService {
  ReviewService._();

  static CollectionReference<Map<String, dynamic>> get _reviews =>
      AppFirebase.db.collection('reviews');

  /// Approved reviews for one destination, newest first.
  static Stream<List<DestinationReview>> approvedFor(String destinationId) {
    return _reviews
        .where('destinationId', isEqualTo: destinationId)
        .where('status', isEqualTo: ReviewStatus.approved)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs.map(DestinationReview.fromDoc).toList()
            ..sort((a, b) => _newestFirst(a.createdAt, b.createdAt));
          return reviews;
        });
  }

  /// The signed-in user's own review of one destination (any status).
  static Stream<DestinationReview?> myReview(
    String destinationId,
    String userId,
  ) {
    return _reviews
        .doc(ReviewRules.documentId(destinationId, userId))
        .snapshots()
        .map((doc) => doc.exists ? DestinationReview.fromDoc(doc) : null);
  }

  /// Creates the user's review, or updates it if one already exists. Either
  /// way the review goes back to "pending". Runs in a transaction, so two
  /// quick taps cannot create two reviews.
  static Future<void> save({
    required String destinationId,
    required String userId,
    required String displayName,
    required int rating,
    required String text,
  }) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'must be 1 to 5');
    }
    final error = ReviewRules.validateText(text);
    if (error != null) throw ArgumentError(error);

    final ref = _reviews.doc(ReviewRules.documentId(destinationId, userId));
    final trimmedName = displayName.trim();
    final name = trimmedName.isEmpty
        ? 'Traveller'
        : trimmedName.length > ReviewRules.maxNameLength
        ? trimmedName.substring(0, ReviewRules.maxNameLength)
        : trimmedName;

    return AppFirebase.db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        transaction.update(ref, {
          'displayName': name,
          'rating': rating,
          'text': text.trim(),
          'status': ReviewStatus.pending,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(ref, {
          'destinationId': destinationId,
          'userId': userId,
          'displayName': name,
          'rating': rating,
          'text': text.trim(),
          'status': ReviewStatus.pending,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// The owner removes their own review.
  static Future<void> deleteOwn(String destinationId, String userId) {
    return _reviews.doc(ReviewRules.documentId(destinationId, userId)).delete();
  }

  // ------------------------------------------------------------ admin only

  /// Every review, for moderation and statistics (admins only).
  static Stream<List<DestinationReview>> allReviews() {
    return _reviews.snapshots().map((snapshot) {
      final reviews = snapshot.docs.map(DestinationReview.fromDoc).toList()
        ..sort((a, b) => _newestFirst(a.createdAt, b.createdAt));
      return reviews;
    });
  }

  /// Admin: approve, reject or set back to pending.
  static Future<void> setStatus(String reviewId, String status) {
    if (!ReviewStatus.all.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    return _reviews.doc(reviewId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: removes a review entirely.
  static Future<void> deleteReview(String reviewId) =>
      _reviews.doc(reviewId).delete();

  static int _newestFirst(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
