import 'package:cloud_firestore/cloud_firestore.dart';

/// One line in a saved trip's travel-documents checklist.
///
/// This tracks preparation only. The app never asks for or stores document
/// scans, ID images, ticket files or document numbers.
class ChecklistItem {
  final String id;
  final String label;
  final bool done;

  /// True for items the user added. Only custom items can be removed.
  final bool custom;

  /// Position for default items; custom items sort after them.
  final int order;

  const ChecklistItem({
    required this.id,
    required this.label,
    required this.done,
    required this.custom,
    required this.order,
  });

  factory ChecklistItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final order = data['order'];
    return ChecklistItem(
      id: doc.id,
      label: data['label']?.toString().trim().isNotEmpty == true
          ? data['label'].toString().trim()
          : 'Untitled item',
      done: data['done'] == true,
      custom: data['custom'] == true,
      order: order is num ? order.toInt() : 0,
    );
  }
}

/// Default checklist items, with fixed IDs so they are created only once.
class DefaultChecklist {
  DefaultChecklist._();

  static const List<({String id, String label, String hint})> items = [
    (
      id: 'government-id',
      label: 'Government ID',
      hint: 'Aadhaar, PAN, driving licence or voter ID',
    ),
    (
      id: 'travel-tickets',
      label: 'Travel tickets',
      hint: 'Flight, train or bus confirmations',
    ),
    (
      id: 'hotel-booking',
      label: 'Hotel booking confirmation',
      hint: 'Check-in details and booking reference',
    ),
    (
      id: 'travel-insurance',
      label: 'Travel insurance',
      hint: 'If you have a policy',
    ),
    (
      id: 'passport-visa',
      label: 'Passport or visa',
      hint: 'Only for international trips',
    ),
    (
      id: 'emergency-contacts',
      label: 'Emergency contact details',
      hint: 'Family or friend to call in an emergency',
    ),
    (
      id: 'other-documents',
      label: 'Other important documents',
      hint: 'Prescriptions, permits or anything else you need',
    ),
  ];
}
