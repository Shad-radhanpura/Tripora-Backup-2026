// Destination Explorer: attraction data, review gating, search of the new
// destinations, and the details screens. Runs on in-memory fakes only.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/attractions.dart';
import 'package:tripora/data/destinations.dart';
import 'package:tripora/models/destination_review.dart';
import 'package:tripora/models/tourist_attraction.dart';
import 'package:tripora/screens/destination_details_screen.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/theme/theme.dart';
import 'package:tripora/widgets/attraction_section.dart';
import 'package:tripora/widgets/destination_reviews_section.dart';

const _commonsThumb = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/';

void main() {
  group('attraction data', () {
    test('every attraction belongs to a catalogue destination', () {
      for (final id in AttractionCatalog.destinationIds) {
        expect(DestinationCatalog.byId(id), isNotNull, reason: id);
      }
    });

    test('every attraction has a name, location, description and credit', () {
      for (final id in AttractionCatalog.destinationIds) {
        for (final a in AttractionCatalog.forDestination(id)) {
          expect(a.name, isNotEmpty, reason: id);
          expect(a.location, isNotEmpty, reason: a.name);
          expect(a.description, isNotEmpty, reason: a.name);
          expect(a.imageCredit, contains('Wikimedia Commons'), reason: a.name);
        }
      }
    });

    test('photos are checked Commons thumbnails and are never reused', () {
      final urls = [
        for (final id in AttractionCatalog.destinationIds)
          for (final a in AttractionCatalog.forDestination(id))
            if (a.imageUrl != null) a.imageUrl!,
      ];
      expect(urls, isNotEmpty);
      expect(urls.toSet().length, urls.length, reason: 'a photo is reused');
      for (final url in urls) {
        expect(url, startsWith(_commonsThumb));
      }
    });

    test('place names are unique within each destination', () {
      for (final id in AttractionCatalog.destinationIds) {
        final names = AttractionCatalog.forDestination(id).map((a) => a.name);
        expect(names.toSet().length, names.length, reason: id);
      }
    });

    test('Ahmedabad places are not listed under Goa or Jaipur', () {
      final goa = AttractionCatalog.forDestination('goa').map((a) => a.name);
      final jaipur = AttractionCatalog.forDestination('jaipur').map((a) => a.name);
      for (final name in ['Sabarmati Ashram', 'Adalaj Stepwell', 'Kankaria Lake']) {
        expect(goa, isNot(contains(name)));
        expect(jaipur, isNot(contains(name)));
      }
      final ahmedabad = AttractionCatalog.forDestination('ahmedabad').map((a) => a.name);
      expect(
        ahmedabad,
        containsAll([
          'Sabarmati Ashram',
          'Adalaj Stepwell',
          'Kankaria Lake',
          'Sabarmati Riverfront',
        ]),
      );
    });

    test('an unknown destination has no attractions', () {
      expect(AttractionCatalog.forDestination('atlantis'), isEmpty);
    });

    test('every destination with attractions has a hero photo', () {
      for (final id in AttractionCatalog.destinationIds) {
        final destination = DestinationCatalog.byId(id)!;
        expect(destination.imageUrl, startsWith('https://'), reason: id);
      }
    });
  });

  group('reviews and search', () {
    test('reviews are offered only for destinations the rules allow', () {
      expect(ReviewRules.reviewableDestinationIds.length, 16);
      for (final id in ReviewRules.reviewableDestinationIds) {
        expect(DestinationCatalog.byId(id), isNotNull, reason: id);
      }
      expect(ReviewRules.isReviewable('goa'), isTrue);
      expect(ReviewRules.isReviewable('ahmedabad'), isFalse);
      expect(ReviewRules.isReviewable('mumbai'), isFalse);
      expect(ReviewRules.isReviewable('delhi'), isFalse);
    });

    test('new destinations can be found by name and alias', () {
      expect(DestinationCatalog.matchName('Ahmedabad')?.id, 'ahmedabad');
      expect(DestinationCatalog.matchName('amdavad')?.id, 'ahmedabad');
      expect(DestinationCatalog.matchName('Mumbai')?.id, 'mumbai');
      expect(DestinationCatalog.matchName('Bombay')?.id, 'mumbai');
      expect(DestinationCatalog.matchName('Delhi')?.id, 'delhi');
      expect(
        DestinationCatalog.search(query: 'Sabarmati').map((d) => d.id),
        contains('ahmedabad'),
      );
    });
  });

  group('screens', () {
    setUp(() {
      AppFirebase.useForTesting(
        auth: MockFirebaseAuth(signedIn: false),
        db: FakeFirebaseFirestore(),
      );
    });

    void useTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Future<void> pumpDetails(WidgetTester tester, String id) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: TriporaTheme.lightTheme,
          home: DestinationDetailsScreen(destination: DestinationCatalog.byId(id)!),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Ahmedabad shows its attractions and no review section', (tester) async {
      await pumpDetails(tester, 'ahmedabad');

      expect(find.text('Tourist attractions'), findsOneWidget);
      expect(find.text('Sabarmati Ashram'), findsOneWidget);
      expect(find.text('Adalaj Stepwell'), findsOneWidget);
      expect(find.text('Kankaria Lake'), findsOneWidget);
      expect(find.text('Sabarmati Riverfront'), findsOneWidget);
      expect(find.text('Basilica of Bom Jesus'), findsNothing);
      expect(find.byType(DestinationReviewsSection), findsNothing);
    });

    testWidgets('Goa shows Goa attractions, not Ahmedabad ones', (tester) async {
      await pumpDetails(tester, 'goa');

      expect(find.text('Basilica of Bom Jesus'), findsOneWidget);
      expect(find.text('Sabarmati Ashram'), findsNothing);
      expect(find.byType(DestinationReviewsSection), findsOneWidget);
    });

    testWidgets('a place without a verified photo shows a placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TriporaTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: AttractionSection(
                destinationName: 'Testville',
                attractions: [
                  TouristAttraction(
                    name: 'Unphotographed Temple',
                    location: 'Testville',
                    description: 'No checked photo exists yet.',
                    imageCredit: '',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unphotographed Temple'), findsWidgets);
      // No network image is requested for a place without a verified photo.
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Plan My Trip passes the destination to the trip planner', (tester) async {
      await pumpDetails(tester, 'ahmedabad');

      await tester.tap(find.text('Plan My Trip to Ahmedabad'));
      // Let the navigation and the SafeNav timer finish.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(
        fields.any((f) => f.controller?.text == 'Ahmedabad'),
        isTrue,
        reason: 'the planner destination field should be filled in',
      );
    });
  });
}
