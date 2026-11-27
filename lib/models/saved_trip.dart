import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts the different date shapes found in Firestore into a [DateTime].
///
/// Older or hand-made documents may store dates as a Timestamp, an ISO
/// string or milliseconds; anything else is treated as "not recorded".
DateTime? parseFirestoreDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? _cleanString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _parseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// A document in the existing `trips` collection.
///
/// Field names follow what `FirestoreService.saveTrip` writes:
/// userId, destination, budget, days, interest, itinerary, createdAt.
class SavedTrip {
  final String id;
  final String userId;
  final String destination;
  final String budget;
  final int? days;
  final String interest;
  final String itinerary;
  final DateTime? createdAt;

  const SavedTrip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.budget,
    required this.days,
    required this.interest,
    required this.itinerary,
    required this.createdAt,
  });

  factory SavedTrip.fromMap(String id, Map<String, dynamic> data) {
    return SavedTrip(
      id: id,
      userId: _cleanString(data['userId']) ?? '',
      destination: _cleanString(data['destination']) ?? 'Unknown destination',
      budget: _cleanString(data['budget']) ?? 'Not specified',
      days: _parseInt(data['days']),
      interest: _cleanString(data['interest']) ?? 'Not specified',
      itinerary: data['itinerary']?.toString() ?? '',
      createdAt: parseFirestoreDate(data['createdAt']),
    );
  }

  factory SavedTrip.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      SavedTrip.fromMap(doc.id, doc.data() ?? const {});

  bool get hasItinerary => itinerary.trim().isNotEmpty;

  String get daysLabel {
    if (days == null) return 'Days not recorded';
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  /// Sorts newest first; trips without a date go to the end.
  static int newestFirst(SavedTrip a, SavedTrip b) =>
      compareNewestFirst(a.createdAt, b.createdAt);
}

int compareNewestFirst(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

String formatDate(DateTime? date, {bool withTime = false}) {
  if (date == null) return 'Not recorded';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = date.toLocal();
  final day = '${local.day} ${months[local.month - 1]} ${local.year}';
  if (!withTime) return day;
  String two(int n) => n.toString().padLeft(2, '0');
  return '$day, ${two(local.hour)}:${two(local.minute)}';
}
