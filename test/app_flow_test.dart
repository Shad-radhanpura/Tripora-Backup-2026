// Widget tests that drive Tripora's real screens against in-memory fakes of
// Firebase Auth and Cloud Firestore. Nothing here touches the live project.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/tour_packages.dart';
import 'package:tripora/data/destinations.dart';
import 'package:tripora/screens/admin_bookings_page.dart';
import 'package:tripora/screens/admin_reviews_page.dart';
import 'package:tripora/screens/destination_details_screen.dart';
import 'package:tripora/screens/admin_dashboard.dart';
import 'package:tripora/screens/admin_packages_page.dart';
import 'package:tripora/screens/travel_services_page.dart';
import 'package:tripora/screens/welcome_screen.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/favourites_store.dart';
import 'package:tripora/services/login_page.dart';
import 'package:tripora/services/package_store.dart';

const adminUid = 'admin-uid';
const userUid = 'user-uid';

late FakeFirebaseFirestore db;

Future<MockFirebaseAuth> setUpFirebase({
  required String uid,
  bool signedIn = true,
  bool seedAdmin = true,
}) async {
  db = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth(
    signedIn: signedIn,
    mockUser: MockUser(
      uid: uid,
      email: '$uid@example.com',
      displayName: uid == adminUid ? 'Admin Person' : 'Test Traveller',
    ),
  );
  AppFirebase.useForTesting(auth: auth, db: db);
  FavouritesStore.instance.stop();
  PackageStore.instance.stop();

  if (seedAdmin) {
    await db.collection('admins').doc(adminUid).set({'role': 'admin'});
  }
  await db.collection('users').doc(userUid).set({
    'uid': userUid,
    'name': 'Test Traveller',
    'email': '$userUid@example.com',
    'createdAt': Timestamp.now(),
    'loginCount': 1,
  });
  await db.collection('trips').add({
    'userId': userUid,
    'destination': 'Goa',
    'budget': 'Moderate',
    'days': 3,
    'interest': 'Beach',
    'itinerary': 'Day 1\nMorning: Beach',
    'createdAt': Timestamp.now(),
  });
  return auth;
}

Future<void> pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pumpAndSettle();
}

/// Lets SnackBar / SafeNav timers finish so no timer is left pending.
Future<void> finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  // SafeNav ignores taps for 600 ms after a navigation.
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> fillAndSubmitBooking(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Mobile number'),
    '9876543210',
  );
  await tapVisible(tester, find.byKey(const Key('demo-ack')));
  await tapVisible(tester, find.byKey(const Key('submit-booking')));
}

void main() {
  group('Login and role routing', () {
    testWidgets('admin account opens the Admin Dashboard', (tester) async {
      await setUpFirebase(uid: adminUid, signedIn: false);
      await pumpApp(tester, const LoginPage());

      await tester.enterText(find.byType(TextField).at(0), 'admin@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tapVisible(tester, find.text('Login to Tripora'));

      expect(find.text('TRIPORA ADMIN'), findsOneWidget);
      expect(find.text('User profiles'), findsOneWidget);
      // Login activity was recorded on the admin's profile.
      final profile = await db.collection('users').doc(adminUid).get();
      expect(profile.data()?['loginCount'], 1);
      await finish(tester);
    });

    testWidgets('normal account opens the User Panel', (tester) async {
      await setUpFirebase(uid: userUid, signedIn: false);
      await pumpApp(tester, const LoginPage());

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tapVisible(tester, find.text('Login to Tripora'));

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('TRIPORA ADMIN'), findsNothing);
      final profile = await db.collection('users').doc(userUid).get();
      expect(profile.data()?['loginCount'], 2);
      await finish(tester);
    });

    testWidgets('non-admin opening the Admin Dashboard is refused', (
      tester,
    ) async {
      await setUpFirebase(uid: userUid);
      await pumpApp(tester, const AdminDashboard());
      expect(find.text('Admin access required'), findsOneWidget);
      expect(find.text('TRIPORA ADMIN'), findsNothing);
    });

    testWidgets('admin dashboard shows live Firestore counts', (tester) async {
      await setUpFirebase(uid: adminUid);
      await db.collection('bookings').add({
        'userId': userUid,
        'kind': 'hotel',
        'title': 'Goa Grand Residency',
        'status': 'pending',
        'totalPrice': 5000,
        'createdAt': Timestamp.now(),
      });
      await pumpApp(tester, const AdminDashboard());

      expect(find.text('TRIPORA ADMIN'), findsOneWidget);
      expect(find.text('Bookings (demo)'), findsOneWidget);
      expect(find.text('1 awaiting review'), findsOneWidget);
      expect(find.text('Booking Management'), findsOneWidget);
      expect(find.text('Package Management'), findsOneWidget);
      expect(find.text('NOT CONFIGURED'), findsNothing);
      await finish(tester);
    });
  });

  group('User Panel', () {
    testWidgets('all five tabs open', (tester) async {
      await setUpFirebase(uid: userUid);
      await pumpApp(tester, const WelcomeScreen());

      await tapVisible(tester, find.text('Packages').last);
      expect(find.text('Tour Packages'), findsWidgets);

      await tapVisible(tester, find.text('My Trips').last);
      expect(find.text('Goa'), findsWidgets);

      await tapVisible(tester, find.text('Bookings').last);
      expect(find.text('No bookings yet'), findsOneWidget);

      await tapVisible(tester, find.text('Profile').last);
      expect(find.text('Test Traveller'), findsWidgets);
      await finish(tester);
    });

    testWidgets('package filters, details and booking save to Firestore', (
      tester,
    ) async {
      await setUpFirebase(uid: userUid);
      await pumpApp(tester, const WelcomeScreen());
      await tapVisible(tester, find.text('Packages').last);

      for (final days in TourPackageCatalog.durations) {
        await tapVisible(tester, find.widgetWithText(ChoiceChip, '$days days'));
        final expected = TourPackageCatalog.all
            .where((p) => p.durationDays == days)
            .length;
        expect(expected, greaterThan(0));
        expect(
          find.text('$expected ${expected == 1 ? 'package' : 'packages'}'),
          findsOneWidget,
        );
      }

      await tapVisible(tester, find.text('Incredible India Grand Tour').first);
      expect(find.text('Day-by-day itinerary'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('book-package')));
      expect(find.text('Booking details'), findsOneWidget);
      await fillAndSubmitBooking(tester);

      expect(find.text('Booking request saved'), findsOneWidget);
      final saved = await db.collection('bookings').get();
      expect(saved.docs, hasLength(1));
      final data = saved.docs.single.data();
      expect(data['userId'], userUid);
      expect(data['kind'], 'package');
      expect(data['status'], 'pending');
      expect(data['isDemo'], true);
      expect(data['travellers'], 2);
      expect(data['totalPrice'], 2 * 165000);
      expect(data['reference'], startsWith('TRP-'));

      await tapVisible(tester, find.text('View my bookings'));
      expect(find.text('Incredible India Grand Tour'), findsOneWidget);
      await finish(tester);
    });

    testWidgets(
      'booking form will not submit without the demo acknowledgement',
      (tester) async {
        await setUpFirebase(uid: userUid);
        await pumpApp(tester, const WelcomeScreen());
        await tapVisible(tester, find.text('Packages').last);
        await tapVisible(tester, find.text('Golden Triangle & Udaipur').first);
        await tapVisible(tester, find.byKey(const Key('book-package')));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mobile number'),
          '9876543210',
        );
        await tapVisible(tester, find.byKey(const Key('submit-booking')));

        expect(find.text('Booking request saved'), findsNothing);
        expect((await db.collection('bookings').get()).docs, isEmpty);
        await finish(tester);
      },
    );

    for (final service in ['Flights', 'Trains', 'Buses', 'Cabs', 'Hotels']) {
      testWidgets('$service search returns results and books', (tester) async {
        await setUpFirebase(uid: userUid);
        await pumpApp(tester, TravelServicesPage(initialService: service));

        await tester.enterText(find.byKey(const Key('service-to')), 'Goa');
        await tapVisible(tester, find.byKey(const Key('service-search')));
        expect(find.text('Select'), findsWidgets);

        await tapVisible(tester, find.text('Select').first);
        if (service == 'Buses') {
          // Buses open the seat map first; choose one free seat, then continue.
          final freeSeat = find.byWidgetPredicate((w) =>
              w is InkWell &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('seat-') &&
              w.onTap != null);
          await tapVisible(tester, freeSeat.first);
          await tapVisible(tester, find.byKey(const Key('bus-continue')));
        }
        await fillAndSubmitBooking(tester);
        expect(find.text('Booking request saved'), findsOneWidget);

        final saved = (await db.collection('bookings').get()).docs.single
            .data();
        expect(saved['kind'], switch (service) {
          'Flights' => 'flight',
          'Trains' => 'train',
          'Buses' => 'bus',
          'Cabs' => 'cab',
          _ => 'hotel',
        });
        expect(saved['totalPrice'], saved['unitPrice'] * saved['travellers']);
        await finish(tester);
      });
    }

    testWidgets('travel search rejects identical from and to', (tester) async {
      await setUpFirebase(uid: userUid);
      await pumpApp(tester, const TravelServicesPage());
      await tester.enterText(find.byKey(const Key('service-to')), 'ahmedabad');
      await tapVisible(tester, find.byKey(const Key('service-search')));
      expect(find.text('Select'), findsNothing);
      expect(
        find.text('Starting point and destination must be different.'),
        findsOneWidget,
      );
      await finish(tester);
    });

    testWidgets('profile edit is saved to users/{uid}', (tester) async {
      await setUpFirebase(uid: userUid);
      await pumpApp(tester, const WelcomeScreen());
      await tapVisible(tester, find.text('Profile').last);
      await tapVisible(tester, find.byKey(const Key('edit-profile')));

      await tester.enterText(
        find.byKey(const Key('profile-name')),
        'Asha Patel',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mobile (optional)'),
        '9876500000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Home city (optional)'),
        'Surat',
      );
      await tapVisible(tester, find.byKey(const Key('save-profile')));

      final data = (await db.collection('users').doc(userUid).get()).data()!;
      expect(data['name'], 'Asha Patel');
      expect(data['phone'], '9876500000');
      expect(data['homeCity'], 'Surat');
      expect(data['loginCount'], 1, reason: 'existing fields are preserved');
      expect(find.text('Asha Patel'), findsWidgets);
      await finish(tester);
    });

    testWidgets('owner can delete a saved trip', (tester) async {
      await setUpFirebase(uid: userUid);
      await pumpApp(tester, const WelcomeScreen());
      await tapVisible(tester, find.text('My Trips').last);
      await tapVisible(tester, find.byTooltip('Delete trip'));
      await tapVisible(tester, find.text('Delete'));
      expect((await db.collection('trips').get()).docs, isEmpty);
      await finish(tester);
    });
  });

  group('Admin tools', () {
    testWidgets('admin confirms a booking and the user sees it', (
      tester,
    ) async {
      await setUpFirebase(uid: adminUid);
      final ref = await db.collection('bookings').add({
        'userId': userUid,
        'userEmail': '$userUid@example.com',
        'kind': 'flight',
        'title': 'IndiGo 6E 2345',
        'subtitle': 'Ahmedabad → Goa',
        'travellers': 1,
        'unitPrice': 4500,
        'totalPrice': 4500,
        'status': 'pending',
        'reference': 'TRP-TEST01',
        'isDemo': true,
        'createdAt': Timestamp.now(),
      });
      await pumpApp(tester, const AdminBookingsPage());

      expect(find.text('IndiGo 6E 2345'), findsOneWidget);
      await tapVisible(tester, find.text('IndiGo 6E 2345'));
      await tapVisible(tester, find.text('Mark confirmed (demo)'));
      await tester.enterText(find.byType(TextField).last, 'Seats held');
      await tapVisible(tester, find.text('Update'));

      final data = (await ref.get()).data()!;
      expect(data['status'], 'confirmed');
      expect(data['adminNote'], 'Seats held');
      await finish(tester);
    });

    testWidgets('admin hides a built-in package; travellers no longer see it', (
      tester,
    ) async {
      await setUpFirebase(uid: adminUid);
      await pumpApp(tester, const AdminPackagesPage());

      final first = PackageStore.instance.allIncludingHidden.first;
      await tapVisible(tester, find.text('Hide').first);
      final doc = await db.collection('packages').doc(first.id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['active'], isFalse);
      expect(
        PackageStore.instance.visible.any((p) => p.id == first.id),
        isFalse,
      );
      expect(find.text('Restore default'), findsOneWidget);

      await tapVisible(tester, find.text('Restore default'));
      await tapVisible(tester, find.text('Continue'));
      expect(
        (await db.collection('packages').doc(first.id).get()).exists,
        isFalse,
      );
      expect(
        PackageStore.instance.visible.any((p) => p.id == first.id),
        isTrue,
      );
      await finish(tester);
    });

    testWidgets('admin creates a new package', (tester) async {
      await setUpFirebase(uid: adminUid);
      await pumpApp(tester, const AdminPackagesPage());
      await tapVisible(tester, find.byKey(const Key('new-package')));

      await tester.enterText(
        find.byKey(const Key('pkg-title')),
        'Gujarat Gems',
      );
      await tester.enterText(find.byKey(const Key('pkg-price')), '25000');
      await tester.enterText(
        find.byKey(const Key('pkg-cities')),
        'Ahmedabad, Dwarka, Somnath',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Region (e.g. North India)'),
        'West India',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Temples and coast',
      );
      await tester.enterText(
        find.byKey(const Key('pkg-itinerary')),
        'Days 1–3 | Ahmedabad | Heritage walk\nDays 4–10 | Dwarka | Temples',
      );
      await tapVisible(tester, find.widgetWithText(FilterChip, 'Hotel stay'));
      await tapVisible(tester, find.byKey(const Key('save-package')));

      final docs = (await db.collection('packages').get()).docs;
      expect(docs, hasLength(1));
      expect(docs.single.data()['title'], 'Gujarat Gems');
      expect(docs.single.data()['cities'], ['Ahmedabad', 'Dwarka', 'Somnath']);
      expect(
        PackageStore.instance.visible.any((p) => p.title == 'Gujarat Gems'),
        isTrue,
      );
      await finish(tester);
    });
  });

  group('Travel documents checklist', () {
    testWidgets(
      'defaults are created once, ticks persist, custom items add and remove',
      (tester) async {
        await setUpFirebase(uid: userUid);
        final tripId = (await db.collection('trips').get()).docs.single.id;
        await pumpApp(tester, const WelcomeScreen());
        await tapVisible(tester, find.text('My Trips').last);
        await tapVisible(tester, find.text('Goa').first);

        await tester.ensureVisible(find.byKey(const Key('checklist-percent')));
        await tester.pumpAndSettle();
        expect(find.text('Government ID'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);

        final checklist = db
            .collection('trips')
            .doc(tripId)
            .collection('checklist');
        expect((await checklist.get()).docs, hasLength(7));

        await tapVisible(
          tester,
          find.byKey(const Key('checklist-item-government-id')),
        );
        await tapVisible(
          tester,
          find.byKey(const Key('checklist-item-travel-tickets')),
        );
        final gov = await checklist.doc('government-id').get();
        expect(gov.data()!['done'], isTrue);
        expect(find.text('29%'), findsOneWidget); // 2 of 7 done

        // Reopen the saved trip: progress is kept and nothing is duplicated.
        await tapVisible(tester, find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Goa'), findsWidgets);
        await tapVisible(tester, find.text('Goa').first);
        await tester.ensureVisible(find.byKey(const Key('checklist-percent')));
        await tester.pumpAndSettle();
        expect(find.text('29%'), findsOneWidget);
        expect((await checklist.get()).docs, hasLength(7));

        // Add and remove a custom item.
        await tester.enterText(
          find.byKey(const Key('checklist-add-field')),
          'Vaccination certificate',
        );
        await tapVisible(tester, find.byKey(const Key('checklist-add')));
        await tester.pumpAndSettle();
        expect((await checklist.get()).docs, hasLength(8));
        expect(find.text('Vaccination certificate'), findsOneWidget);

        final custom = (await checklist.get()).docs.firstWhere(
          (d) => d.data()['custom'] == true,
        );
        await tapVisible(tester, find.byTooltip('Remove').first);
        await tapVisible(tester, find.text('Remove'));
        await tester.pumpAndSettle();
        expect((await checklist.doc(custom.id).get()).exists, isFalse);
        expect((await checklist.get()).docs, hasLength(7));
        await finish(tester);
      },
    );

    testWidgets('admin Trip view does not show the checklist', (tester) async {
      await setUpFirebase(uid: adminUid);
      final tripId = (await db.collection('trips').get()).docs.single.id;
      expect(tripId, isNotEmpty);
      await pumpApp(tester, const AdminDashboard());
      await tapVisible(tester, find.text('Trip Management'));
      await tapVisible(tester, find.text('Goa').first);
      expect(find.text('Travel documents'), findsNothing);
      await finish(tester);
    });
  });

  group('Share trip button', () {
    testWidgets('owner saved trip shows Share trip; admin view does not',
        (tester) async {
      await setUpFirebase(uid: userUid);
      await pumpApp(tester, const WelcomeScreen());
      await tapVisible(tester, find.text('My Trips').last);
      await tapVisible(tester, find.text('Goa').first);
      expect(find.byKey(const Key('share-trip')), findsOneWidget);
      await finish(tester);
    });

    testWidgets('admin trip view has no share button', (tester) async {
      await setUpFirebase(uid: adminUid);
      await pumpApp(tester, const AdminDashboard());
      await tapVisible(tester, find.text('Trip Management'));
      await tapVisible(tester, find.text('Goa').first);
      expect(find.byKey(const Key('share-trip')), findsNothing);
      await finish(tester);
    });
  });


  group('Ratings and reviews', () {
    final goa = DestinationCatalog.byId('goa')!;

    testWidgets('user sees approved average, writes a review, and it stays pending',
        (tester) async {
      await setUpFirebase(uid: userUid);
      await db.collection('reviews').doc('goa_other-uid').set({
        'destinationId': 'goa',
        'userId': 'other-uid',
        'displayName': 'Ravi',
        'rating': 4,
        'text': 'Great beaches and food stalls.',
        'status': 'approved',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await db.collection('reviews').doc('goa_pending-uid').set({
        'destinationId': 'goa',
        'userId': 'pending-uid',
        'displayName': 'Asha',
        'rating': 1,
        'text': 'Not yet approved review.',
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await pumpApp(tester, DestinationDetailsScreen(destination: goa));

      await tester.ensureVisible(find.byKey(const Key('review-average')));
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('(1 review)'), findsOneWidget);
      expect(find.text('Great beaches and food stalls.'), findsOneWidget);
      expect(find.text('Not yet approved review.'), findsNothing);

      await tapVisible(tester, find.byKey(const Key('write-review')));
      await tapVisible(tester, find.byKey(const Key('review-star-5')));
      await tester.enterText(
          find.byKey(const Key('review-text')), 'Wonderful sunsets and calm water.');
      await tapVisible(tester, find.byKey(const Key('review-submit')));
      await tester.pumpAndSettle();

      final mine = await db.collection('reviews').doc('goa_$userUid').get();
      expect(mine.data()!['status'], 'pending');
      expect(mine.data()!['rating'], 5);
      expect(find.byKey(const Key('my-review-status')), findsOneWidget);
      // Pending reviews do not change the public average.
      expect(find.text('4.0'), findsOneWidget);

      // Editing updates the same document (no duplicate) and keeps it pending.
      await tapVisible(tester, find.byKey(const Key('write-review')));
      await tapVisible(tester, find.byKey(const Key('review-star-3')));
      await tapVisible(tester, find.byKey(const Key('review-submit')));
      await tester.pumpAndSettle();
      final all = await db.collection('reviews').get();
      expect(all.docs.length, 3, reason: 'editing never creates a second review');
      expect((await db.collection('reviews').doc('goa_$userUid').get()).data()!['rating'], 3);
      await finish(tester);
    });

    testWidgets('admin approves a pending review and the statistics update',
        (tester) async {
      await setUpFirebase(uid: adminUid);
      await db.collection('reviews').doc('goa_u1').set({
        'destinationId': 'goa',
        'userId': 'u1',
        'displayName': 'Meera',
        'rating': 5,
        'text': 'Loved the old churches.',
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await db.collection('reviews').doc('goa_u2').set({
        'destinationId': 'goa',
        'userId': 'u2',
        'displayName': 'Kiran',
        'rating': 3,
        'text': 'Crowded but fun overall.',
        'status': 'approved',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      await pumpApp(tester, const AdminReviewsPage());

      expect(find.byKey(const Key('stat-total')), findsOneWidget);
      expect(find.text('3.0'), findsOneWidget); // approved average before moderation

      await tapVisible(tester, find.byKey(const Key('approve-goa_u1')));
      await tester.pumpAndSettle();
      expect((await db.collection('reviews').doc('goa_u1').get()).data()!['status'],
          'approved');
      expect(find.text('4.0'), findsOneWidget); // (5 + 3) / 2
      await finish(tester);
    });
  });

}
