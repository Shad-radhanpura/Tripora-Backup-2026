import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/tour_packages.dart';
import '../models/tour_package.dart';
import 'firestore_service.dart';

/// The tour packages users see: the built-in catalogue merged with the
/// admin-managed `packages` collection.
///
/// A Firestore document with a built-in package's ID replaces that package
/// (so admins can edit prices or hide it); other documents are new
/// admin-created packages. One shared listener serves every screen. If the
/// collection cannot be read (offline, rules not yet deployed), users still
/// see the built-in catalogue instead of a blank screen.
class PackageStore extends ChangeNotifier {
  PackageStore._();

  static final PackageStore instance = PackageStore._();

  StreamSubscription<dynamic>? _sub;
  Map<String, TourPackage> _remote = const {};
  Object? lastError;
  bool loaded = false;

  void start() {
    if (_sub != null) return;
    _sub = FirestoreService.packagesStream().listen(
      (snapshot) {
        _remote = {
          for (final doc in snapshot.docs)
            doc.id: TourPackage.fromMap(
              doc.id,
              doc.data(),
              builtIn: TourPackageCatalog.byId(doc.id) != null,
            ),
        };
        lastError = null;
        loaded = true;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Packages listener failed: $e');
        // A Firestore stream ends after an error; allow start() to retry.
        _sub = null;
        lastError = e;
        loaded = true;
        notifyListeners();
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _remote = const {};
    loaded = false;
    lastError = null;
  }

  /// True when an admin has saved a Firestore copy of this package.
  bool isOverridden(String id) => _remote.containsKey(id);

  /// Every package including hidden ones (Admin Panel).
  List<TourPackage> get allIncludingHidden {
    final merged = <String, TourPackage>{
      for (final p in TourPackageCatalog.all) p.id: p,
      ..._remote,
    };
    return merged.values.toList()
      ..sort((a, b) {
        final byDays = a.durationDays.compareTo(b.durationDays);
        return byDays != 0 ? byDays : a.pricePerPerson.compareTo(b.pricePerPerson);
      });
  }

  /// Packages visible to travellers.
  List<TourPackage> get visible =>
      allIncludingHidden.where((p) => p.active).toList();

  TourPackage? byId(String id) {
    for (final p in allIncludingHidden) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<TourPackage> filter(
    List<TourPackage> packages, {
    String query = '',
    int? days,
    String? category,
    int? maxPrice,
    String sort = 'days',
  }) {
    final result = packages
        .where((p) => p.matches(query))
        .where((p) => days == null || p.durationDays == days)
        .where((p) => category == null || p.category == category)
        .where((p) => maxPrice == null || p.pricePerPerson <= maxPrice)
        .toList();
    switch (sort) {
      case 'price-low':
        result.sort((a, b) => a.pricePerPerson.compareTo(b.pricePerPerson));
      case 'price-high':
        result.sort((a, b) => b.pricePerPerson.compareTo(a.pricePerPerson));
      default:
        result.sort((a, b) => a.durationDays.compareTo(b.durationDays));
    }
    return result;
  }
}
