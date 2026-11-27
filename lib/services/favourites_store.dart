import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/destination.dart';
import 'firestore_service.dart';
import 'app_firebase.dart';

/// Keeps the signed-in user's favourite destination IDs in memory, backed by
/// one live Firestore listener, so every heart button in the app shows the
/// same state without opening its own database listener.
class FavouritesStore extends ChangeNotifier {
  FavouritesStore._();

  static final FavouritesStore instance = FavouritesStore._();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _uid;

  final Set<String> _ids = {};
  final Set<String> _pending = {};

  bool _loaded = false;
  Object? _error;

  bool get isLoaded => _loaded;
  Object? get error => _error;
  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavourite(String destinationId) => _ids.contains(destinationId);
  bool isPending(String destinationId) => _pending.contains(destinationId);

  /// Starts listening for the given user. Safe to call repeatedly.
  void start(String uid) {
    if (_uid == uid && _subscription != null) return;
    stop();
    _uid = uid;
    _subscription = FirestoreService.favouritesStream(uid).listen(
      (snapshot) {
        _ids
          ..clear()
          ..addAll(snapshot.docs.map((doc) => doc.id));
        _loaded = true;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Favourites stream failed: $e');
        _error = e;
        _loaded = true;
        notifyListeners();
      },
    );
  }

  /// Stops listening and clears state, e.g. on logout, so one account's
  /// favourites never show in another account.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _ids.clear();
    _pending.clear();
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  /// Adds or removes a favourite. Returns null on success, otherwise a short
  /// message to show the user. Repeated taps while a write is in progress
  /// are ignored.
  Future<String?> toggle(Destination destination) async {
    final uid = _uid ?? AppFirebase.auth.currentUser?.uid;
    if (uid == null) return 'Please sign in to save favourites.';
    if (_pending.contains(destination.id)) return null;

    if (_uid != uid) start(uid);

    final wasFavourite = _ids.contains(destination.id);
    _pending.add(destination.id);
    notifyListeners();

    try {
      if (wasFavourite) {
        await FirestoreService.removeFavourite(uid, destination.id)
            .timeout(const Duration(seconds: 15));
      } else {
        await FirestoreService.addFavourite(uid, destination)
            .timeout(const Duration(seconds: 15));
      }
      return null;
    } on TimeoutException {
      return 'Saving is slow. It will finish when your connection is stable.';
    } on FirebaseException catch (e) {
      debugPrint('Favourite update failed: ${e.code} ${e.message}');
      return e.code == 'permission-denied'
          ? 'Could not update favourites (permission denied).'
          : 'Could not update favourites (${e.code}).';
    } catch (e) {
      debugPrint('Favourite update failed: $e');
      return 'Could not update favourites. Please try again.';
    } finally {
      _pending.remove(destination.id);
      notifyListeners();
    }
  }
}
