import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/screens/travel_services_page.dart';
import 'package:tripora/theme/theme.dart';

List<ServiceOption> _sampleHotels() {
  final hotels = DemoServiceProvider.search(
    ServiceSearch(
      service: 'Hotels',
      from: '',
      to: 'Goa',
      date: DateTime(2026, 11, 1),
      nights: 2,
    ),
  );
  return hotels.take(2).toList();
}

void main() {
  test('sample hotels carry structured stars and rating for comparison', () {
    for (final hotel in _sampleHotels()) {
      expect(hotel.details.containsKey('Stars'), isTrue);
      expect(hotel.details['Guest rating'], endsWith('/ 5'));
      expect(hotel.details['Rate'], contains('per night'));
    }
  });

  testWidgets('compare sheet shows each hotel and is labelled as sample data', (
    tester,
  ) async {
    final hotels = _sampleHotels();
    await tester.pumpWidget(
      MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: Scaffold(
          body: HotelCompareSheet(options: hotels),
        ),
      ),
    );

    expect(find.text('Compare hotels'), findsOneWidget);
    expect(find.textContaining('Sample prices and ratings'), findsOneWidget);
    for (final label in ['Total price', 'Rate', 'Stars', 'Guest rating']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final hotel in hotels) {
      expect(find.text(hotel.title), findsOneWidget);
    }
    expect(find.text(hotels.first.details['Stars']!), findsOneWidget);
  });
}
