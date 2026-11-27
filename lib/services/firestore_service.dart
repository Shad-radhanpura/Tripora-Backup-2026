import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/destination.dart';
import '../models/tour_package.dart';
import 'app_firebase.dart';

/// Single place for Tripora's Firestore reads and writes.
///
/// Collections used (all existing except the two marked new):
///   users/{uid}                     profile written at signup
///   users/{uid}/favourites/{destId} NEW: a user's liked destinations
///   trips/{autoId}                  AI itineraries, linked by userId
///   admins/{uid}                    NEW: marks an admin account; created by
///                                   the project owner in the Firebase Console
class FirestoreService {
  static FirebaseFirestore get _db => AppFirebase.db;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  static CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  // ============================================================
  // USERS
  // ============================================================

  // Create or update a user document
  static Future<void> createUser({
    required String uid,
    required String email,
  }) async {
    await _users.doc(uid).set({
      'uid': uid,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Records a successful sign-in on the user's own profile document.
  ///
  /// Uses merge so existing fields (including the original createdAt) are
  /// never overwritten. If the profile document is missing (for example an
  /// account whose signup write failed), this re-creates it from the Auth
  /// account, without inventing a registration date.
  static Future<void> recordLogin(User user) async {
    final data = <String, dynamic>{
      'uid': user.uid,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'loginCount': FieldValue.increment(1),
    };

    final email = user.email;
    if (email != null && email.isNotEmpty) data['email'] = email;

    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) data['name'] = name;

    await _users.doc(user.uid).set(data, SetOptions(merge: true));
  }

  /// Checks whether this account is an administrator.
  ///
  /// Returns true only when `admins/{uid}` exists AND its `role` field is
  /// exactly the string "admin". Returns false only when the server
  /// confirms the account is not an admin (document missing, or another
  /// role).
  ///
  /// It reads from the server, not the offline cache, so a stale or missing
  /// cache can never decide the role. Any failure (permission-denied,
  /// offline, timeout) is THROWN to the caller instead of being treated
  /// as "not an admin".
  ///
  /// The document is created by hand in the Firebase Console; the proposed
  /// security rules stop app users from creating or editing it.
  static Future<bool> isAdmin(String uid) async {
    final doc = await _db
        .collection('admins')
        .doc(uid)
        .get(const GetOptions(source: Source.server));

    if (!doc.exists) return false;
    return doc.data()?['role'] == 'admin';
  }

  // ============================================================
  // TRIPS
  // ============================================================

  // Save a generated trip
  static Future<String> saveTrip({
    required String userId,
    required String destination,
    required String budget,
    required int days,
    required String interest,
    required String itinerary,
  }) async {
    final docRef = await _trips.add({
      'userId': userId,
      'destination': destination,
      'budget': budget,
      'days': days,
      'interest': interest,
      'itinerary': itinerary,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Get all trips of a particular user
  static Future<List<Map<String, dynamic>>> getUserTrips(
    String userId,
  ) async {
    final snapshot = await _trips.where('userId', isEqualTo: userId).get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  // Get one trip by document ID
  static Future<Map<String, dynamic>?> getTrip(String tripId) async {
    final doc = await _trips.doc(tripId).get();

    if (!doc.exists) {
      return null;
    }

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  /// Live list of one user's saved trips (used by My Trips).
  ///
  /// Only an equality filter is used, so no composite index is needed;
  /// screens sort the results by createdAt themselves.
  static Stream<QuerySnapshot<Map<String, dynamic>>> userTripsStream(
    String userId,
  ) {
    return _trips.where('userId', isEqualTo: userId).snapshots();
  }

  // ============================================================
  // FAVOURITES  (users/{uid}/favourites/{destinationId})
  // ============================================================

  static CollectionReference<Map<String, dynamic>> _favourites(String uid) =>
      _users.doc(uid).collection('favourites');

  static Stream<QuerySnapshot<Map<String, dynamic>>> favouritesStream(
    String uid,
  ) {
    return _favourites(uid).snapshots();
  }

  /// Adds a favourite. The destination ID is the document ID, so saving the
  /// same destination twice can never create a duplicate.
  static Future<void> addFavourite(String uid, Destination destination) {
    return _favourites(uid).doc(destination.id).set({
      'destinationId': destination.id,
      'name': destination.name,
      'location': destination.location,
      'imageUrl': destination.imageUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes only this user's favourite marker. Trips and the destination
  /// itself are not touched.
  static Future<void> removeFavourite(String uid, String destinationId) {
    return _favourites(uid).doc(destinationId).delete();
  }

  // ============================================================
  // ADMIN (reads are allowed only for admins by the proposed rules)
  // ============================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> allUsersStream() =>
      _users.snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> allTripsStream() =>
      _trips.snapshots();

  /// Every favourite across all users, for the admin total.
  static Stream<QuerySnapshot<Map<String, dynamic>>> allFavouritesStream() =>
      _db.collectionGroup('favourites').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> adminsStream() =>
      _db.collection('admins').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> allBookingsStream() =>
      _bookings.snapshots();

  /// Admin: deletes any trip. Owners can delete their own (see deleteTrip).
  static Future<void> deleteTrip(String tripId) => _trips.doc(tripId).delete();

  // ============================================================
  // PROFILE  (users/{uid}: name, phone, homeCity)
  // ============================================================

  static Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(
    String uid,
  ) =>
      _users.doc(uid).snapshots();

  /// Updates the editable profile fields. Merge keeps createdAt, login
  /// activity and anything else already on the document.
  static Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String homeCity,
  }) {
    return _users.doc(uid).set({
      'uid': uid,
      'name': name,
      'phone': phone,
      'homeCity': homeCity,
    }, SetOptions(merge: true));
  }

  // ============================================================
  // TOUR PACKAGES  (packages/{packageId}, written by admins only)
  // ============================================================

  static CollectionReference<Map<String, dynamic>> get _packages =>
      _db.collection('packages');

  static Stream<QuerySnapshot<Map<String, dynamic>>> packagesStream() =>
      _packages.snapshots();

  /// Creates or replaces a package. Using a built-in package's ID overrides
  /// that built-in package for every user.
  static Future<void> savePackage(TourPackage package) =>
      _packages.doc(package.id).set(package.toMap());

  /// Deletes the Firestore copy. For a built-in package this restores the
  /// bundled version; for an admin-created package it removes it entirely.
  static Future<void> deletePackage(String packageId) =>
      _packages.doc(packageId).delete();

  static String newPackageId() => _packages.doc().id;

  // ============================================================
  // BOOKINGS  (bookings/{autoId}; DEMO bookings, see models/booking.dart)
  // ============================================================

  static CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  static final Random _random = Random();

  /// A readable reference such as "TRP-7KQ2MX". Not a real PNR.
  static String newBookingReference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (_) => chars[_random.nextInt(chars.length)]);
    return 'TRP-${code.join()}';
  }

  /// Saves a booking request with status "pending". Returns the reference.
  static Future<String> createBooking({
    required User user,
    required String kind,
    required String itemId,
    required String title,
    required String subtitle,
    required DateTime travelDate,
    required int travellers,
    required int unitPrice,
    required int totalPrice,
    required String contactName,
    required String contactPhone,
    required String notes,
    required Map<String, String> details,
  }) async {
    final reference = newBookingReference();
    await _bookings.add({
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'kind': kind,
      'itemId': itemId,
      'title': title,
      'subtitle': subtitle,
      'travelDate': Timestamp.fromDate(
        DateTime(travelDate.year, travelDate.month, travelDate.day),
      ),
      'travellers': travellers,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'notes': notes,
      'details': details,
      'status': 'pending',
      'reference': reference,
      'isDemo': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> userBookingsStream(
    String uid,
  ) =>
      _bookings.where('userId', isEqualTo: uid).snapshots();

  /// The owner cancels their own booking request.
  static Future<void> cancelBooking(String bookingId) {
    return _bookings.doc(bookingId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: moves a booking through the workflow.
  static Future<void> setBookingStatus(
    String bookingId,
    String status, {
    String? adminNote,
  }) {
    return _bookings.doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'adminNote': ?adminNote,
    });
  }

  static Future<void> deleteBooking(String bookingId) =>
      _bookings.doc(bookingId).delete();
}
