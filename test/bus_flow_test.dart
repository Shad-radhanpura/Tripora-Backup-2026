// Bus flow: sorting and bus-type filtering on the Travel Services screen, seat
// selection with an exact seat count, and the fixed seat quantity in the
// booking form. Demo data only; Firebase is faked and nothing is booked.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/models/tour_package.dart';
import 'package:tripora/screens/booking_form_screen.dart';
import 'package:tripora/screens/bus_seat_selection_page.dart';
import 'package:tripora/screens/travel_services_page.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/theme/theme.dart';

const _from = 'Ahmedabad';
const _to = 'Mumbai';

/// The Travel Services screen searches with a date seven days ahead and two
/// nights. The demo results depend on both, so the expectations use the same.
DateTime _pageDate() => DateTime.now().add(const Duration(days: 7));

List<ServiceOption> _busesOnPage() => DemoServiceProvider.search(ServiceSearch(
      service: 'Buses',
      from: _from,
      to: _to,
      date: _pageDate(),
      nights: 2,
    ));

/// Price lines of the bus results, in the order they are drawn.
List<String> _renderedBusPrices(WidgetTester tester) => [
      for (final r in tester.widgetList<RichText>(find.byType(RichText)))
        if (r.text.toPlainText().endsWith('per seat')) r.text.toPlainText(),
    ];

String _priceLine(ServiceOption bus) => '${formatInr(bus.price)}  per seat';

/// The first [count] seats that are free on this bus, in layout order.
List<String> _freeSeats(String busId, int count) {
  final booked = BusSeatSelectionPage.bookedSeatsFor(busId);
  final free = <String>[];
  for (var row = 1; row <= BusSeatSelectionPage.rows && free.length < count; row++) {
    for (final letter in BusSeatSelectionPage.rowLetters) {
      final id = '$row$letter';
      if (!booked.contains(id) && free.length < count) free.add(id);
    }
  }
  return free;
}

Widget _app(Widget home) => MaterialApp(theme: TriporaTheme.lightTheme, home: home);

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _searchBuses(WidgetTester tester) async {
  await tester.pumpWidget(_app(const TravelServicesPage(initialService: 'Buses')));
  await tester.pump();
  await tester.enterText(find.byKey(const Key('service-to')), _to);
  await tester.tap(find.byKey(const Key('service-search')));
  await tester.pumpAndSettle();
}

ServiceOption _firstBus() => _busesOnPage().first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppFirebase.useForTesting(
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'bus-user', email: 'bus@example.com'),
      ),
      db: FakeFirebaseFirestore(),
    );
  });

  group('bus results data', () {
    test('each bus carries departure, duration and type for sorting and filtering', () {
      final buses = _busesOnPage();
      expect(buses, isNotEmpty);
      for (final bus in buses) {
        expect(bus.departMinutes, isNotNull, reason: bus.id);
        expect(bus.durationMinutes, greaterThan(0), reason: bus.id);
        expect(bus.category, isNotEmpty, reason: bus.id);
      }
    });

    test('the seat map is the same every time for the same bus', () {
      final first = BusSeatSelectionPage.bookedSeatsFor('bus-VRL Travels-0');
      final second = BusSeatSelectionPage.bookedSeatsFor('bus-VRL Travels-0');
      expect(first, second);
      expect(first, isNotEmpty);
      expect(first.length, lessThan(BusSeatSelectionPage.rows * BusSeatSelectionPage.rowLetters.length));
    });
  });

  group('Travel Services bus results', () {
    testWidgets('cheapest bus is listed first by default', (tester) async {
      _useTallView(tester);
      await _searchBuses(tester);
      final sorted = [..._busesOnPage()]..sort((a, b) => a.price.compareTo(b.price));
      expect(_renderedBusPrices(tester), [for (final b in sorted) _priceLine(b)]);
    });

    testWidgets('sorting by earliest departure reorders the list', (tester) async {
      _useTallView(tester);
      await _searchBuses(tester);
      await tester.tap(find.byKey(const Key('results-sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Departure: earliest first').last);
      await tester.pumpAndSettle();

      final sorted = [..._busesOnPage()]
        ..sort((a, b) => a.departMinutes!.compareTo(b.departMinutes!));
      expect(_renderedBusPrices(tester), [for (final b in sorted) _priceLine(b)]);
    });

    testWidgets('choosing a bus type shows only that type, and All restores the list', (tester) async {
      _useTallView(tester);
      final buses = _busesOnPage();
      final type = buses.first.category;
      await _searchBuses(tester);

      await tester.tap(find.byKey(Key('bus-type-$type')));
      await tester.pumpAndSettle();
      final ofType = buses.where((b) => b.category == type).toList()
        ..sort((a, b) => a.price.compareTo(b.price));
      expect(_renderedBusPrices(tester), [for (final b in ofType) _priceLine(b)]);

      await tester.tap(find.byKey(const Key('bus-type-all')));
      await tester.pumpAndSettle();
      expect(_renderedBusPrices(tester).length, buses.length);
    });

    testWidgets('Select on a bus opens the seat map for that bus', (tester) async {
      _useTallView(tester);
      await _searchBuses(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Select').first);
      await tester.pumpAndSettle();
      expect(find.byType(BusSeatSelectionPage), findsOneWidget);
      expect(find.byKey(const Key('bus-seat-instructions')), findsOneWidget);
    });
  });

  group('bus seat selection', () {
    testWidgets('Continue needs exactly the passenger count; an extra seat is refused', (tester) async {
      _useTallView(tester);
      final bus = _firstBus();
      await tester.pumpWidget(_app(BusSeatSelectionPage(
        option: bus,
        from: _from,
        to: _to,
        date: _pageDate(),
        passengers: 2,
      )));
      await tester.pump();
      final seats = _freeSeats(bus.id, 3);

      FilledButton continueButton() =>
          tester.widget<FilledButton>(find.byKey(const Key('bus-continue')));

      expect(continueButton().onPressed, isNull);

      await tester.tap(find.byKey(Key('seat-${seats[0]}')));
      await tester.pump();
      expect(continueButton().onPressed, isNull);

      await tester.tap(find.byKey(Key('seat-${seats[1]}')));
      await tester.pump();
      expect(continueButton().onPressed, isNotNull);
      expect(find.text('Total ₹${bus.price * 2} (2 × ₹${bus.price})'), findsOneWidget);

      await tester.tap(find.byKey(Key('seat-${seats[2]}')));
      await tester.pump();
      expect(find.textContaining('You need exactly 2 seats'), findsOneWidget);
      // The third seat was refused, so the first two stay selected.
      expect(find.text('Seats ${([seats[0], seats[1]]..sort()).join(', ')}'), findsOneWidget);
      expect(continueButton().onPressed, isNotNull);
    });

    testWidgets('booked seats cannot be selected', (tester) async {
      _useTallView(tester);
      final bus = _firstBus();
      final booked = BusSeatSelectionPage.bookedSeatsFor(bus.id).first;
      await tester.pumpWidget(_app(BusSeatSelectionPage(
        option: bus,
        from: _from,
        to: _to,
        date: _pageDate(),
        passengers: 1,
      )));
      await tester.pump();

      await tester.tap(find.byKey(Key('seat-$booked')));
      await tester.pump();
      expect(find.text('Seats none'), findsOneWidget);
    });

    testWidgets('Continue opens the booking form with the chosen seats and a fixed quantity', (tester) async {
      _useTallView(tester);
      final bus = _firstBus();
      final seats = _freeSeats(bus.id, 2);
      await tester.pumpWidget(_app(BusSeatSelectionPage(
        option: bus,
        from: _from,
        to: _to,
        date: _pageDate(),
        passengers: 2,
      )));
      await tester.pump();
      for (final seat in seats) {
        await tester.tap(find.byKey(Key('seat-$seat')));
        await tester.pump();
      }

      await tester.tap(find.byKey(const Key('bus-continue')));
      await tester.pumpAndSettle();

      final form = tester.widget<BookingFormScreen>(find.byType(BookingFormScreen));
      expect(form.draft.kind, 'bus');
      expect(form.draft.itemId, bus.id);
      expect(form.draft.unitPrice, bus.price);
      expect(form.draft.fixedQuantity, 2);
      expect(form.draft.dateFixed, isTrue);
      expect(form.draft.details['Seats'], ([...seats]..sort()).join(', '));
    });
  });

  group('booking form with a fixed quantity', () {
    testWidgets('the traveller count cannot be changed when seats are fixed', (tester) async {
      _useTallView(tester);
      final bus = _firstBus();
      await tester.pumpWidget(_app(BookingFormScreen(
        draft: BookingDraft(
          kind: 'bus',
          itemId: bus.id,
          title: bus.title,
          subtitle: '$_from → $_to',
          unitPrice: bus.price,
          unitLabel: 'per seat',
          quantityLabel: 'Passengers',
          initialDate: _pageDate(),
          dateFixed: true,
          initialQuantity: 2,
          fixedQuantity: 2,
          details: const {'Seats': '1A, 1B'},
        ),
      )));
      await tester.pump();

      expect(tester.widget<Text>(find.byKey(const Key('booking-quantity'))).data, '2');
      final plus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add_circle_outline),
      );
      final minus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
      );
      expect(plus.onPressed, isNull);
      expect(minus.onPressed, isNull);
    });
  });
}
