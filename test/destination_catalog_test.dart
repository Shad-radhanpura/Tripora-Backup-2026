import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/destinations.dart';
import 'package:tripora/models/app_user.dart';
import 'package:tripora/models/saved_trip.dart';

void main() {
  group('DestinationCatalog', () {
    test('has unique ids and only planner categories', () {
      final ids = DestinationCatalog.all.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length);

      for (final d in DestinationCatalog.all) {
        expect(d.categories, isNotEmpty, reason: d.id);
        for (final c in d.categories) {
          expect(DestinationCatalog.categories, contains(c), reason: d.id);
        }
        expect(d.imageUrl, startsWith('https://'), reason: d.id);
        expect(d.imageCredit, isNotEmpty, reason: d.id);
      }
    });

    test('search matches name, region and highlights, case-insensitive', () {
      expect(
        DestinationCatalog.search(query: 'goa').map((d) => d.id),
        contains('goa'),
      );
      expect(
        DestinationCatalog.search(query: 'RAJASTHAN').map((d) => d.id),
        containsAll(['jaipur', 'udaipur']),
      );
      expect(
        DestinationCatalog.search(query: 'taj mahal').map((d) => d.id),
        contains('agra'),
      );
    });

    test('category filter returns only matching destinations', () {
      final beaches = DestinationCatalog.search(category: 'Beach');
      expect(beaches, isNotEmpty);
      expect(beaches.every((d) => d.categories.contains('Beach')), isTrue);
    });

    test('search and filter combine; unknown text returns nothing', () {
      expect(
        DestinationCatalog.search(query: 'jaipur', category: 'Beach'),
        isEmpty,
      );
      expect(DestinationCatalog.search(query: 'zzzz-not-a-place'), isEmpty);
    });

    test('empty search returns the whole catalogue', () {
      expect(
        DestinationCatalog.search().length,
        DestinationCatalog.all.length,
      );
    });

    test('matchName links free-text trip destinations to the catalogue', () {
      expect(DestinationCatalog.matchName('Manali')?.id, 'manali');
      expect(DestinationCatalog.matchName('alleppey, kerala')?.id, 'alappuzha');
      expect(DestinationCatalog.matchName('Leh')?.id, 'ladakh');
      expect(DestinationCatalog.matchName(''), isNull);
    });
  });

  group('SavedTrip.fromMap', () {
    test('reads the fields written by FirestoreService.saveTrip', () {
      final created = DateTime.utc(2026, 10, 1, 9, 30);
      final trip = SavedTrip.fromMap('t1', {
        'userId': 'u1',
        'destination': 'Goa',
        'budget': 'Moderate',
        'days': 4,
        'interest': 'Beach',
        'itinerary': 'Day 1\nMorning: Beach',
        'createdAt': Timestamp.fromDate(created),
      });

      expect(trip.userId, 'u1');
      expect(trip.days, 4);
      expect(trip.daysLabel, '4 days');
      expect(trip.hasItinerary, isTrue);
      expect(trip.createdAt!.isAtSameMomentAs(created), isTrue);
    });

    test('tolerates missing and differently typed fields', () {
      final trip = SavedTrip.fromMap('t2', {'days': '3'});
      expect(trip.destination, 'Unknown destination');
      expect(trip.budget, 'Not specified');
      expect(trip.days, 3);
      expect(trip.hasItinerary, isFalse);
      expect(trip.createdAt, isNull);
    });

    test('newestFirst puts undated trips last', () {
      final a = SavedTrip.fromMap('a', {
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      final b = SavedTrip.fromMap('b', {
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      });
      final c = SavedTrip.fromMap('c', {});
      final sorted = [a, c, b]..sort(SavedTrip.newestFirst);
      expect(sorted.map((t) => t.id), ['b', 'a', 'c']);
    });
  });

  group('AppUser.fromMap', () {
    test('handles profiles without login tracking fields', () {
      final user = AppUser.fromMap('uid123', {
        'name': 'Asha Patel',
        'email': 'asha@example.com',
      });
      expect(user.displayName, 'Asha Patel');
      expect(user.initials, 'AP');
      expect(user.lastLoginAt, isNull);
      expect(user.loginCount, isNull);
      expect(user.matches('asha@'), isTrue);
      expect(user.matches('nobody'), isFalse);
    });
  });
}
