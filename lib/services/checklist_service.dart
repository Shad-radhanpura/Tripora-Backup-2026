import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist_item.dart';
import 'app_firebase.dart';

/// Reads and writes the travel-documents checklist for one saved trip.
///
/// Location: trips/{tripId}/checklist/{itemId}. The security rules allow
/// only the trip's owner to touch these items.
class ChecklistService {
  ChecklistService._();

  static CollectionReference<Map<String, dynamic>> _items(String tripId) =>
      AppFirebase.db.collection('trips').doc(tripId).collection('checklist');

  static Stream<List<ChecklistItem>> watch(String tripId) {
    return _items(tripId).snapshots().map((snapshot) {
      final items = snapshot.docs.map(ChecklistItem.fromDoc).toList()
        ..sort((a, b) {
          if (a.custom != b.custom) return a.custom ? 1 : -1;
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.label.compareTo(b.label);
        });
      return items;
    });
  }

  /// Creates any default item that does not exist yet. Existing items,
  /// including their ticked state, are never changed. Runs in a transaction
  /// so two opens at once cannot create duplicates.
  static Future<void> ensureDefaults(String tripId) {
    final db = AppFirebase.db;
    return db.runTransaction((transaction) async {
      final refs = [
        for (final item in DefaultChecklist.items) _items(tripId).doc(item.id),
      ];
      final snapshots = [for (final ref in refs) await transaction.get(ref)];
      for (var i = 0; i < refs.length; i++) {
        if (snapshots[i].exists) continue;
        final item = DefaultChecklist.items[i];
        transaction.set(refs[i], {
          'label': item.label,
          'done': false,
          'custom': false,
          'order': i,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static Future<void> setDone(String tripId, String itemId, bool done) {
    return _items(tripId).doc(itemId).update({
      'done': done,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addCustom(String tripId, String label) {
    return _items(tripId).add({
      'label': label.trim(),
      'done': false,
      'custom': true,
      'order': 1000,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a user-added item. Default items are rejected by the rules.
  static Future<void> removeCustom(String tripId, String itemId) {
    return _items(tripId).doc(itemId).delete();
  }
}
