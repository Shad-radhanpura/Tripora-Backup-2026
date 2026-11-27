import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// The Firebase Auth and Firestore instances the whole app uses.
///
/// In the app these are always the real `FirebaseAuth.instance` and
/// `FirebaseFirestore.instance`. Widget tests replace them with in-memory
/// fakes through [useForTesting], so screens can be tested without ever
/// touching the live project.
class AppFirebase {
  AppFirebase._();

  static FirebaseAuth? _auth;
  static FirebaseFirestore? _db;

  static FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  static FirebaseFirestore get db => _db ??= FirebaseFirestore.instance;

  @visibleForTesting
  static void useForTesting({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
  }) {
    _auth = auth;
    _db = db;
  }
}
