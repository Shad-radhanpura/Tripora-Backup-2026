// Vehicle photos on the cab, bus, train and flight booking screens: the bundled
// files and their credits, the photo chosen for each result, the fallback when a
// photo cannot be loaded, and the wiring into the results, seat map and form.
import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/data/vehicle_photos.dart';
import 'package:tripora/screens/booking_form_screen.dart';
import 'package:tripora/screens/bus_seat_selection_page.dart';
import 'package:tripora/screens/travel_services_page.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/theme/theme.dart';
import 'package:tripora/widgets/vehicle_photo.dart';

const _bundled = [
  VehiclePhotos.cabHatchback,
  VehiclePhotos.cabSedan,
  VehiclePhotos.cabSuv,
  VehiclePhotos.cabPremium,
  VehiclePhotos.busAcSleeper,
  VehiclePhotos.busVolvoSeater,
  VehiclePhotos.busNonAc,
  VehiclePhotos.trainChairCar,
  VehiclePhotos.trainAcCoach,
  VehiclePhotos.flight,
];

Widget _app(Widget home) => MaterialApp(theme: TriporaTheme.lightTheme, home: home);

/// A phone-width view (360 px wide) tall enough for the whole results list, so
/// every card is built. Width is what matters for overflow checks.
void _phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppFirebase.useForTesting(
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'photo-user', email: 'photo@example.com'),
      ),
      db: FakeFirebaseFirestore(),
    );
  });

  group('bundled vehicle photos', () {
    test('every photo file exists in assets/vehicles', () {
      for (final path in _bundled) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('every photo has an author, a licence and a Commons source', () {
      for (final path in _bundled) {
        final credit = VehiclePhotos.credits[path];
        expect(credit, isNotNull, reason: path);
        expect(credit!.artist.trim(), isNotEmpty, reason: path);
        expect(
          credit.licence == 'CC0' ||
              credit.licence.startsWith('CC BY') ||
              credit.licence.startsWith('Public domain'),
          isTrue,
          reason: '$path: ${credit.licence}',
        );
        expect(
          credit.sourceUrl,
          startsWith('https://commons.wikimedia.org/wiki/File:'),
          reason: path,
        );
      }
    });

    test('assets/vehicles/credits.json lists the same files as the code', () {
      final json = jsonDecode(
        File('assets/vehicles/credits.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final fromCode = {for (final p in _bundled) p.split('/').last};
      expect(json.keys.toSet(), fromCode);
    });

    test('the credit line names the author and the licence', () {
      expect(
        VehiclePhotos.credits[VehiclePhotos.cabSedan]!.line,
        'Photo: Ethan Llamas, CC BY-SA 4.0',
      );
    });
  });

  group('choosing a photo for a result', () {
    test('cab models map to their vehicle type', () {
      String? cab(String car) =>
          VehiclePhotos.forService(service: 'Cabs', details: {'Car': car});
      expect(cab('Hatchback (WagonR or similar)'), VehiclePhotos.cabHatchback);
      expect(cab('Sedan (Dzire or similar)'), VehiclePhotos.cabSedan);
      expect(cab('SUV (Ertiga or similar)'), VehiclePhotos.cabSuv);
      expect(cab('Premium SUV (Innova Crysta)'), VehiclePhotos.cabPremium);
      expect(cab('Unknown car'), isNull);
    });

    test('bus types map to a photo, and unknown types get none', () {
      String? bus(String type) =>
          VehiclePhotos.forService(service: 'Buses', category: type);
      expect(bus('AC Sleeper (2+1)'), VehiclePhotos.busAcSleeper);
      expect(bus('Volvo AC Seater (2+2)'), VehiclePhotos.busVolvoSeater);
      expect(bus('Non-AC Sleeper'), VehiclePhotos.busNonAc);
      expect(bus('Mystery coach'), isNull);
    });

    test('train classes map to a chair car photo or an AC coach photo', () {
      String? train(String travelClass) => VehiclePhotos.forService(
            service: 'Trains',
            details: {'Class': travelClass},
          );
      expect(train('AC Chair Car (CC)'), VehiclePhotos.trainChairCar);
      expect(train('AC 2 Tier (2A)'), VehiclePhotos.trainAcCoach);
      expect(train('Sleeper (SL)'), VehiclePhotos.trainAcCoach);
      expect(train(''), isNull);
    });

    test('flights get the aircraft photo and hotels get none', () {
      expect(VehiclePhotos.forService(service: 'Flights'), VehiclePhotos.flight);
      expect(VehiclePhotos.forService(service: 'Hotels'), isNull);
    });

    test('every demo cab, bus, train and flight result has a photo that exists', () {
      final date = DateTime(2026, 11, 5);
      for (final service in ['Cabs', 'Buses', 'Trains', 'Flights']) {
        final results = DemoServiceProvider.search(ServiceSearch(
          service: service,
          from: 'Ahmedabad',
          to: 'Mumbai',
          date: date,
          nights: 2,
        ));
        expect(results, isNotEmpty, reason: service);
        for (final option in results) {
          final photo = VehiclePhotos.forService(
            service: service,
            category: option.category,
            details: option.details,
          );
          expect(photo, isNotNull, reason: '$service ${option.id}');
          expect(File(photo!).existsSync(), isTrue, reason: photo);
        }
      }
    });
  });

  group('VehiclePhoto widget', () {
    testWidgets('shows the bundled photo, not the fallback', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
        body: VehiclePhoto(asset: VehiclePhotos.cabSedan, label: 'Sedan cab'),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(VehiclePhotoFallback), findsNothing);
    });

    testWidgets('shows a clean fallback when the photo cannot be loaded', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
        body: VehiclePhoto(
          asset: 'assets/vehicles/does-not-exist.jpg',
          label: 'Missing cab',
          icon: Icons.local_taxi_rounded,
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(VehiclePhotoFallback), findsOneWidget);
      expect(find.text('Missing cab'), findsOneWidget);
    });

    testWidgets('the caption gives the credit, or a plain note for an unknown photo', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
        body: Column(children: [
          VehiclePhotoCaption(asset: VehiclePhotos.cabSedan),
          VehiclePhotoCaption(asset: 'assets/vehicles/unknown.jpg'),
        ]),
      )));
      await tester.pump();
      expect(find.textContaining('Ethan Llamas'), findsOneWidget);
      expect(find.textContaining('Illustrative photo'), findsNWidgets(2));
    });
  });

  group('photos in the booking flows', () {
    testWidgets('each cab result shows a photo, and Select passes it to the form', (tester) async {
      _phoneView(tester);
      await tester.pumpWidget(_app(const TravelServicesPage(initialService: 'Cabs')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('service-to')), 'Pune');
      await tester.tap(find.byKey(const Key('service-search')));
      await tester.pumpAndSettle();

      expect(find.byType(VehiclePhoto), findsNWidgets(4));
      expect(tester.takeException(), isNull, reason: 'no overflow at phone width');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Select').first);
      await tester.pumpAndSettle();
      final form = tester.widget<BookingFormScreen>(find.byType(BookingFormScreen));
      expect(form.draft.imageAsset, isNotNull);
      expect(find.byType(VehiclePhoto), findsOneWidget);
    });

    testWidgets('hotel results show no vehicle photo', (tester) async {
      _phoneView(tester);
      await tester.pumpWidget(_app(const TravelServicesPage(initialService: 'Hotels')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('service-to')), 'Goa');
      await tester.tap(find.byKey(const Key('service-search')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'Select'), findsWidgets);
      expect(find.byType(VehiclePhoto), findsNothing);
    });

    testWidgets('the seat map shows the bus type photo', (tester) async {
      _tallView(tester);
      final bus = DemoServiceProvider.search(ServiceSearch(
        service: 'Buses',
        from: 'Ahmedabad',
        to: 'Mumbai',
        date: DateTime(2026, 11, 5),
        nights: 2,
      )).first;
      await tester.pumpWidget(_app(BusSeatSelectionPage(
        option: bus,
        from: 'Ahmedabad',
        to: 'Mumbai',
        date: DateTime(2026, 11, 5),
        passengers: 1,
      )));
      await tester.pumpAndSettle();
      expect(find.byType(VehiclePhoto), findsOneWidget);
      expect(find.byType(VehiclePhotoCaption), findsOneWidget);
    });
  });
}
