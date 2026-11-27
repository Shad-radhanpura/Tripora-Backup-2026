import 'package:cloud_firestore/cloud_firestore.dart';

import 'saved_trip.dart';

/// A booking request stored in the `bookings` collection.
///
/// Tripora has no connection to a real airline, railway, bus operator,
/// hotel or tour operator. Every booking is a DEMO booking ([isDemo] is
/// always true): it records the request and lets an admin move it through
/// a status workflow, but no seat, room or tour is reserved and no payment
/// is taken. The UI says so wherever a booking is shown.
class Booking {
  static const kinds = ['package', 'hotel', 'flight', 'train', 'bus', 'cab'];
  static const statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

  final String id;
  final String userId;
  final String userEmail;
  final String kind;
  final String itemId;
  final String title;
  final String subtitle;
  final DateTime? travelDate;
  final int travellers;
  final int unitPrice;
  final int totalPrice;
  final String contactName;
  final String contactPhone;
  final String notes;
  final Map<String, String> details;
  final String status;
  final String reference;
  final String adminNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.kind,
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.travelDate,
    required this.travellers,
    required this.unitPrice,
    required this.totalPrice,
    required this.contactName,
    required this.contactPhone,
    required this.notes,
    required this.details,
    required this.status,
    required this.reference,
    this.adminNote = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get canUserCancel => status == 'pending' || status == 'confirmed';

  String get kindLabel => switch (kind) {
        'package' => 'Tour package',
        'hotel' => 'Hotel',
        'flight' => 'Flight',
        'train' => 'Train',
        'bus' => 'Bus',
        'cab' => 'Cab',
        _ => kind,
      };

  String get statusLabel => switch (status) {
        'pending' => 'Requested',
        'confirmed' => 'Confirmed (demo)',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => status,
      };

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [title, subtitle, reference, userEmail, contactName, kindLabel]
        .any((value) => value.toLowerCase().contains(q));
  }

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    int number(Object? value) => value is num ? value.toInt() : 0;
    String text(Object? value) => value?.toString() ?? '';
    final rawDetails = data['details'];

    return Booking(
      id: doc.id,
      userId: text(data['userId']),
      userEmail: text(data['userEmail']),
      kind: text(data['kind']),
      itemId: text(data['itemId']),
      title: text(data['title']),
      subtitle: text(data['subtitle']),
      travelDate: parseFirestoreDate(data['travelDate']),
      travellers: number(data['travellers']),
      unitPrice: number(data['unitPrice']),
      totalPrice: number(data['totalPrice']),
      contactName: text(data['contactName']),
      contactPhone: text(data['contactPhone']),
      notes: text(data['notes']),
      details: rawDetails is Map
          ? rawDetails.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      status: text(data['status']).isEmpty ? 'pending' : text(data['status']),
      reference: text(data['reference']),
      adminNote: text(data['adminNote']),
      createdAt: parseFirestoreDate(data['createdAt']),
      updatedAt: parseFirestoreDate(data['updatedAt']),
    );
  }
}
