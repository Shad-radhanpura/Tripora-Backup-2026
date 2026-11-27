// End-to-end test of the real app (real Firebase SDKs) against the LOCAL
// Firebase emulators. It never touches the live project.
//
// Run with tool/run_e2e.sh (starts the emulators with
// firestore.rules.proposed, seeds an admin account, then runs this file).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tripora/main.dart' as app;
import 'package:tripora/widgets/favourite_button.dart';

const adminEmail = String.fromEnvironment('E2E_ADMIN_EMAIL');
const adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');

Future<void> settle(WidgetTester tester, [int seconds = 2]) async {
  // Real network calls (to the emulator) finish outside the fake clock, so
  // pump in real time for a while instead of pumpAndSettle.
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> waitFor(WidgetTester tester, Finder finder,
    {int seconds = 20}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder.first);
  await settle(tester, 1);
}

Finder field(String hint) => find.widgetWithText(TextField, hint);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register, book, then admin sees and manages it', (tester) async {
    expect(app.useFirebaseEmulators, isTrue,
        reason: 'must run against the emulators only');
    await app.initFirebase();
    await FirebaseAuth.instance.signOut();
    await tester.pumpWidget(const app.TriporaApp());
    await waitFor(tester, find.text('Login to Tripora'));

    // ---------------------------------------------------------- REGISTER
    final email = 'e2e${DateTime.now().millisecondsSinceEpoch}@example.com';
    await tap(
      tester,
      find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().contains('Create account')),
    );
    await tester.enterText(field('Your name'), 'E2E Traveller');
    await tester.enterText(field('you@example.com'), email);
    await tester.enterText(field('Create a password'), 'secret123');
    await tester.enterText(field('Enter password again'), 'secret123');
    await tap(tester, find.text('Create My Account'));
    await waitFor(tester, find.text('Explore'));

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;
    final profile = await db.collection('users').doc(uid).get();
    expect(profile.data()?['email'], email, reason: 'users/{uid} created');

    // --------------------------------------------------------- FAVOURITE
    await tap(tester, find.byType(FavouriteButton));
    await settle(tester, 2);
    final favs = await db.collection('users/$uid/favourites').get();
    expect(favs.docs, hasLength(1), reason: 'favourite saved');

    // ---------------------------------------- PLANNER (offline fallback)
    await tap(tester, find.text('Create My AI Trip'));
    await tester.enterText(field('e.g. Manali, Goa, Dubai...'), 'Jaipur');
    await tap(tester, find.text('Generate My Trip'));
    // No AI key is passed to this test run, so the planner explains that and
    // offers the labelled offline plan.
    await waitFor(tester, find.text('AI planner unavailable'));
    await tap(tester, find.text('Create offline plan'));
    await settle(tester, 3);
    final trips =
        await db.collection('trips').where('userId', isEqualTo: uid).get();
    expect(trips.docs, hasLength(1), reason: 'trip saved');
    expect(trips.docs.single.data()['destination'], 'Jaipur');
    // Back to the User Panel.
    while (find.text('Explore').evaluate().isEmpty ||
        find.byType(BackButton).evaluate().isNotEmpty) {
      final back = find.byType(BackButton);
      if (back.evaluate().isEmpty) break;
      await tap(tester, back);
    }

    // -------------------------------------------------- PACKAGE BOOKING
    await tap(tester, find.text('Packages'));
    await tap(tester, find.text('Kerala Backwaters & Hills'));
    await tap(tester, find.byKey(const Key('book-package')));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile number'), '9876543210');
    await tap(tester, find.byKey(const Key('demo-ack')));
    await tap(tester, find.byKey(const Key('submit-booking')));
    await waitFor(tester, find.text('Booking request saved'));
    await tap(tester, find.text('Back to home'));

    // ---------------------------------------------------- HOTEL BOOKING
    await tap(tester, find.text('Explore'));
    await tap(tester, find.text('Explore Travel Services'));
    await tap(tester, find.text('Hotels'));
    await tester.enterText(find.byKey(const Key('service-to')), 'Udaipur');
    await tap(tester, find.byKey(const Key('service-search')));
    await tap(tester, find.text('Select'));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile number'), '9876543210');
    await tap(tester, find.byKey(const Key('demo-ack')));
    await tap(tester, find.byKey(const Key('submit-booking')));
    await waitFor(tester, find.text('Booking request saved'));
    await tap(tester, find.text('View my bookings'));
    await waitFor(tester, find.text('Udaipur Grand Residency'));
    await tap(tester, find.byType(BackButton));
    await tap(tester, find.byType(BackButton));

    final bookings =
        await db.collection('bookings').where('userId', isEqualTo: uid).get();
    expect(bookings.docs, hasLength(2), reason: 'two bookings saved');

    // ----------------------------------------------------------- PROFILE
    await tap(tester, find.text('Profile'));
    await tap(tester, find.byKey(const Key('edit-profile')));
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Home city (optional)'), 'Surat');
    await tap(tester, find.byKey(const Key('save-profile')));
    await settle(tester, 2);
    expect((await db.collection('users').doc(uid).get()).data()?['homeCity'],
        'Surat');

    // A normal user must not be able to read admin-only data.
    await expectLater(db.collection('bookings').get(), throwsA(anything));

    // ------------------------------------------------------------ LOGOUT
    await tap(tester, find.text('Log out'));
    await tap(tester, find.widgetWithText(TextButton, 'Log out'));
    await waitFor(tester, find.text('Login to Tripora'));

    // ------------------------------------------------------- ADMIN LOGIN
    expect(adminEmail, isNotEmpty);
    await tester.enterText(field('you@example.com'), adminEmail);
    await tester.enterText(field('Enter your password'), adminPassword);
    await tap(tester, find.text('Login to Tripora'));
    await waitFor(tester, find.text('TRIPORA ADMIN'));
    await waitFor(tester, find.text('Bookings (demo)'));
    await waitFor(tester, find.text('2 awaiting review'));

    // The new user appears in User Management.
    await tap(tester, find.text('User Management'));
    await waitFor(tester, find.text('E2E Traveller'));
    await tap(tester, find.byType(BackButton));

    // Booking Management: confirm the package booking.
    await tap(tester, find.text('Booking Management'));
    await tap(tester, find.text('Kerala Backwaters & Hills'));
    await tap(tester, find.text('Mark confirmed (demo)'));
    await tap(tester, find.text('Update'));
    await settle(tester, 2);
    final confirmed = await db
        .collection('bookings')
        .where('status', isEqualTo: 'confirmed')
        .get();
    expect(confirmed.docs, hasLength(1), reason: 'admin confirmed booking');
    await tap(tester, find.byType(BackButton));

    // Package Management: hide and restore a package.
    await tap(tester, find.text('Package Management'));
    await tap(tester, find.text('Hide'));
    await settle(tester, 2);
    expect((await db.collection('packages').get()).docs, hasLength(1));
    await tap(tester, find.text('Restore default'));
    await tap(tester, find.text('Continue'));
    await settle(tester, 2);
    expect((await db.collection('packages').get()).docs, isEmpty);
  });
}
