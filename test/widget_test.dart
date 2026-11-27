import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/tour_packages.dart';
import 'package:tripora/models/tour_package.dart';
import 'package:tripora/screens/travel_services_page.dart';
import 'package:tripora/services/ai_service.dart';
import 'package:tripora/services/offline_planner.dart';
import 'package:tripora/services/package_store.dart';
import 'package:tripora/models/destination_review.dart';
import 'package:tripora/services/trip_share.dart';

void main() {
  test('formatInr uses Indian digit grouping', () {
    expect(formatInr(950), '₹950');
    expect(formatInr(38500), '₹38,500');
    expect(formatInr(165000), '₹1,65,000');
    expect(formatInr(3400000), '₹34,00,000');
  });

  test('catalogue has packages for every duration, with itineraries', () {
    for (final days in TourPackageCatalog.durations) {
      final matching =
          TourPackageCatalog.all.where((p) => p.durationDays == days).toList();
      expect(matching, isNotEmpty, reason: '$days-day packages');
    }
    final ids = TourPackageCatalog.all.map((p) => p.id).toSet();
    expect(ids.length, TourPackageCatalog.all.length, reason: 'unique IDs');
    for (final p in TourPackageCatalog.all) {
      expect(p.itinerary, isNotEmpty, reason: p.id);
      expect(p.facilities, isNotEmpty, reason: p.id);
      expect(p.cities.length, greaterThanOrEqualTo(3), reason: p.id);
      expect(p.imageUrl, isNotEmpty, reason: p.id);
    }
  });

  test('package filters and sorting', () {
    final all = TourPackageCatalog.all;
    final cheap = PackageStore.filter(all, maxPrice: 50000);
    expect(cheap.every((p) => p.pricePerPerson <= 50000), isTrue);
    final intl = PackageStore.filter(all, category: 'International');
    expect(intl.every((p) => p.category == 'International'), isTrue);
    final sorted = PackageStore.filter(all, sort: 'price-high');
    for (var i = 1; i < sorted.length; i++) {
      expect(sorted[i - 1].pricePerPerson >= sorted[i].pricePerPerson, isTrue);
    }
    expect(PackageStore.filter(all, query: 'leh').single.id,
        'manali-leh-adventure-15');
  });

  test('TourPackage survives a Firestore round trip', () {
    final original = TourPackageCatalog.all.first;
    final copy = TourPackage.fromMap(original.id, original.toMap());
    expect(copy.title, original.title);
    expect(copy.itinerary.length, original.itinerary.length);
    expect(copy.facilities, original.facilities);
    expect(copy.pricePerPerson, original.pricePerPerson);
  });

  test('sample service results are stable and priced', () {
    final search = ServiceSearch(
      service: 'Flights',
      from: 'Ahmedabad',
      to: 'Goa',
      date: DateTime(2026, 12, 1),
    );
    final first = DemoServiceProvider.search(search);
    final second = DemoServiceProvider.search(search);
    expect(first, isNotEmpty);
    expect(first.map((o) => o.title), second.map((o) => o.title));
    expect(first.every((o) => o.price > 0), isTrue);

    final hotels = DemoServiceProvider.search(ServiceSearch(
      service: 'Hotels',
      from: '',
      to: 'Jaipur',
      date: DateTime(2026, 12, 1),
      nights: 3,
    ));
    expect(hotels.first.priceLabel, contains('3 nights'));
  });

  test('offline plan is labelled and has one entry per day', () {
    final plan = OfflinePlanner.build(
      destination: 'Jaipur',
      budget: 'Moderate',
      days: 4,
      interest: 'Culture',
    );
    expect(plan, startsWith(OfflinePlanner.label));
    expect(RegExp(r'^Day \d+$', multiLine: true).allMatches(plan).length, 4);
    expect(plan, contains('Amber Fort'));
  });

  test('AI service reports a missing key clearly (tests run without one)',
      () async {
    expect(AiService.isConfigured, isFalse);
    await expectLater(
      AiService.generateItinerary(
        destination: 'Goa',
        budget: 'Moderate',
        days: 2,
        interest: 'Beach',
      ),
      throwsA(isA<AiException>().having(
          (e) => e.message, 'message', contains('not configured'))),
    );
  });

  group('Trip share text', () {
    test('summary uses only stored trip data', () {
      final text = TripShare.buildText(
        destination: 'Goa',
        days: 3,
        budget: 'Moderate',
        interest: 'Beach',
        itinerary: '## Day 1\n**Morning:** Baga beach',
        savedAt: DateTime(2026, 10, 16),
      );
      expect(text, contains('Tripora trip: Goa'));
      expect(text, contains('Duration: 3 days'));
      expect(text, contains('Budget: Moderate'));
      expect(text, contains('Interest: Beach'));
      expect(text, contains('Saved: 16 Oct 2026'));
      expect(text, contains('Day 1'));
      expect(text, contains('Morning: Baga beach'));
      expect(text, isNot(contains('**')));
      expect(text, isNot(contains('## ')));
    });

    test('missing fields are shown as not recorded, never guessed', () {
      final text = TripShare.buildText(
        destination: '  ',
        days: null,
        budget: '',
        interest: '',
        itinerary: '   ',
      );
      expect(text, contains('Destination not recorded'));
      expect(text, contains('Duration: Not recorded'));
      expect(text, contains('Budget: Not recorded'));
      expect(text, contains('No itinerary text is stored for this trip.'));
      expect(text, isNot(contains('Saved:')));
    });

    test('one-day trips use the singular word', () {
      final text = TripShare.buildText(
        destination: 'Pune',
        days: 1,
        budget: 'Low',
        interest: 'Culture',
        itinerary: 'Visit the fort',
      );
      expect(text, contains('Duration: 1 day'));
    });
  });


  group('Review statistics and rules', () {
    DestinationReview r(String status, int rating, [String id = 'x']) =>
        DestinationReview(
          id: id,
          destinationId: 'goa',
          userId: 'u',
          displayName: 'T',
          rating: rating,
          text: 'Some review text here',
          status: status,
          createdAt: null,
          updatedAt: null,
        );

    test('average and count use approved reviews only', () {
      final stats = ReviewStats.fromApproved([
        r('approved', 5, 'a'),
        r('approved', 3, 'b'),
        r('pending', 1, 'c'),
        r('rejected', 1, 'd'),
      ]);
      expect(stats.count, 2);
      expect(stats.average, 4.0);
    });

    test('no approved reviews gives no average', () {
      final stats = ReviewStats.fromApproved([r('pending', 5)]);
      expect(stats.count, 0);
      expect(stats.average, isNull);
    });

    test('moderation counts add up', () {
      final counts = ModerationCounts.from([
        r('pending', 4, 'a'),
        r('approved', 5, 'b'),
        r('approved', 3, 'c'),
        r('rejected', 1, 'd'),
      ]);
      expect(counts.total, 4);
      expect(counts.pending, 1);
      expect(counts.approved, 2);
      expect(counts.rejected, 1);
      expect(counts.averageApproved, 4.0);
    });

    test('review IDs are one per user per destination', () {
      expect(ReviewRules.documentId('goa', 'abc'), 'goa_abc');
    });

    test('review text limits match the rules', () {
      expect(ReviewRules.validateText('short'), isNotNull);
      expect(ReviewRules.validateText('This is long enough.'), isNull);
      expect(ReviewRules.validateText('x' * 1001), isNotNull);
      expect(ReviewRules.validateText('   '), isNotNull);
    });
  });

}
