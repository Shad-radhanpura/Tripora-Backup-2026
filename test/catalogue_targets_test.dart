// Catalogue targets from the completion brief: at least 100 demo packages in at
// least 30 Indian cities, the required price points, departures after 30 October
// 2026, unique IDs, and a deterministic list that does not change between calls.
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/demo_catalogue.dart';
import 'package:tripora/data/destinations.dart';

void main() {
  final packages = DemoCatalogue.all;

  test('there are at least 100 demo packages', () {
    expect(packages.length, greaterThanOrEqualTo(100));
  });

  test('packages cover at least 30 Indian cities, all in the destination catalogue', () {
    final cities = {for (final p in packages) p.destinationId};
    expect(cities.length, greaterThanOrEqualTo(30));
    expect(DemoCatalogue.indianDestinationIds.length, greaterThanOrEqualTo(30));
    for (final id in cities) {
      expect(DestinationCatalog.byId(id), isNotNull, reason: id);
    }
  });

  test('the required price points appear in the catalogue', () {
    final prices = {for (final p in packages) p.pricePerPerson};
    for (final point in [4999, 9999, 14999, 19999, 24999, 29999]) {
      expect(prices, contains(point), reason: '₹$point');
    }
  });

  test('prices run from ₹4,999 to ₹1,49,000 and are not all identical', () {
    final prices = packages.map((p) => p.pricePerPerson).toList();
    expect(prices.reduce((a, b) => a < b ? a : b), 4999);
    expect(prices.reduce((a, b) => a > b ? a : b), 149000);
    expect(prices.toSet().length, greaterThan(10));
  });

  test('every departure is after 30 October 2026 (first allowed: 31 October)', () {
    final earliestAllowed = DateTime(2026, 10, 31);
    for (final p in packages) {
      expect(p.departures, isNotEmpty, reason: p.id);
      for (final d in p.departures) {
        expect(d.date.isBefore(earliestAllowed), isFalse, reason: '${p.id} ${d.date}');
      }
    }
  });

  test('package IDs are unique', () {
    final ids = packages.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('the list is the same on every call (deterministic seed)', () {
    final first = DemoCatalogue.all.map((p) => '${p.id}|${p.pricePerPerson}').toList();
    final second = DemoCatalogue.all.map((p) => '${p.id}|${p.pricePerPerson}').toList();
    expect(second, first);
  });

  test('each package has a duration of 3 to 15 days and at least one day of itinerary', () {
    for (final p in packages) {
      expect(p.durationDays, inInclusiveRange(3, 15), reason: p.id);
      expect(p.itinerary, isNotEmpty, reason: p.id);
    }
  });
}
