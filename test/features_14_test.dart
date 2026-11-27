// Tests for the new travel features: local food, budget estimate, checklist
// progress, Trip Readiness, Explore Places and the food explorer.
// Runs on in-memory fakes only; nothing touches the live project.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/attractions.dart';
import 'package:tripora/data/destinations.dart';
import 'package:tripora/data/local_food.dart';
import 'package:tripora/models/checklist_item.dart';
import 'package:tripora/models/saved_trip.dart';
import 'package:tripora/screens/explore_places_page.dart';
import 'package:tripora/screens/food_explorer_page.dart';
import 'package:tripora/screens/trip_readiness_page.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/checklist_progress.dart';
import 'package:tripora/theme/theme.dart';
import 'package:tripora/widgets/budget_estimate_card.dart';

ChecklistItem _item(String id, {bool done = false}) => ChecklistItem(
      id: id,
      label: 'Item $id',
      done: done,
      custom: false,
      order: 0,
    );

void main() {
  group('local food data', () {
    test('every food guide belongs to a catalogue destination', () {
      for (final id in FoodCatalog.destinationIds) {
        expect(DestinationCatalog.byId(id), isNotNull, reason: id);
        expect(FoodCatalog.forDestination(id).length, greaterThanOrEqualTo(3), reason: id);
      }
    });

    test('every dish has a name, category and description and no price', () {
      for (final id in FoodCatalog.destinationIds) {
        for (final dish in FoodCatalog.forDestination(id)) {
          expect(dish.name, isNotEmpty, reason: id);
          expect(dish.category, isNotEmpty, reason: dish.name);
          expect(dish.description, isNotEmpty, reason: dish.name);
          expect(dish.description, isNot(contains('₹')), reason: dish.name);
        }
      }
    });

    test('food is specific to each destination', () {
      final goa = FoodCatalog.forDestination('goa').map((d) => d.name);
      final ahmedabad = FoodCatalog.forDestination('ahmedabad').map((d) => d.name);
      final mumbai = FoodCatalog.forDestination('mumbai').map((d) => d.name);
      expect(goa, contains('Goan fish curry'));
      expect(goa, isNot(contains('Dhokla')));
      expect(ahmedabad, contains('Dhokla'));
      expect(ahmedabad, contains('Gujarati thali'));
      expect(mumbai, contains('Vada pav'));
      expect(mumbai, isNot(contains('Dhokla')));
    });

    test('the requested destinations have their signature dishes', () {
      expect(FoodCatalog.forDestination('jaipur').map((d) => d.name), contains('Dal baati churma'));
      expect(FoodCatalog.forDestination('delhi').map((d) => d.name), contains('Chole bhature'));
      expect(FoodCatalog.forDestination('manali').map((d) => d.name), contains('Siddu'));
    });

    test('an unknown destination has no food guide', () {
      expect(FoodCatalog.hasFood('atlantis'), isFalse);
      expect(FoodCatalog.forDestination('atlantis'), isEmpty);
    });

    test('diet filters keep only the matching dishes', () {
      final goa = FoodCatalog.forDestination('goa');
      final veg = filterDishes(goa, DietFilter.vegetarian);
      final nonVeg = filterDishes(goa, DietFilter.nonVegetarian);
      expect(veg, isNotEmpty);
      expect(nonVeg, isNotEmpty);
      expect(veg.every((d) => d.vegetarian), isTrue);
      expect(nonVeg.every((d) => !d.vegetarian), isTrue);
      expect(filterDishes(goa, DietFilter.all).length, goa.length);
      expect(veg.map((d) => d.name), contains('Vegetable xacuti'));
    });
  });

  group('checklist progress', () {
    test('summary counts only completed items', () {
      final items = [
        _item('a', done: true),
        _item('b', done: true),
        _item('c'),
        _item('d'),
        _item('e'),
      ];
      expect(ChecklistProgress.completed(items), 2);
      expect(ChecklistProgress.summary(items), '2 of 5 tasks completed');
      expect(ChecklistProgress.fraction(items), closeTo(0.4, 0.0001));
    });

    test('no items gives zero progress without dividing by zero', () {
      expect(ChecklistProgress.fraction(const []), 0);
      expect(ChecklistProgress.summary(const []), '0 of 0 tasks completed');
    });

    test('a single task uses the singular word', () {
      expect(ChecklistProgress.summary([_item('a', done: true)]), '1 of 1 task completed');
    });
  });

  group('budget estimate card', () {
    testWidgets('shows the moderate 4-day estimate with clear labels', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: BudgetEstimateCard(budget: 'Moderate', days: 4),
          ),
        ),
      ));
      await tester.pump();

      // 4 nights, food, local travel, activities, 10% buffer = 25,520.
      expect(find.text('₹25,520'), findsOneWidget);
      expect(find.text('Estimated total'), findsOneWidget);
      expect(find.text('Attractions and activities'), findsOneWidget);
      expect(find.text('ESTIMATE'), findsOneWidget);
      expect(
        find.textContaining('Flights, trains and buses between cities are not included'),
        findsOneWidget,
      );
    });
  });

  group('screens', () {
    setUp(() {
      AppFirebase.useForTesting(
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1', email: 'u1@x.com')),
        db: FakeFirebaseFirestore(),
      );
    });

    testWidgets('food explorer shows Goa dishes and switches by diet filter', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const FoodExplorerPage(destinationId: 'goa'),
      ));
      await tester.pump();

      expect(find.text('Goan fish curry'), findsOneWidget);
      expect(find.text('Dhokla'), findsNothing);

      await tester.tap(find.byKey(const Key('food-filter-vegetarian')));
      await tester.pump();
      expect(find.text('Goan fish curry'), findsNothing);
      expect(find.text('Vegetable xacuti'), findsOneWidget);
    });

    testWidgets('explore places finds destinations and filters by search', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const ExplorePlacesPage(),
      ));
      await tester.pump();

      expect(find.text('Goa'), findsWidgets);

      // Ahmedabad is near the end of the list, so search for it directly.
      await tester.enterText(find.byKey(const Key('explore-search')), 'ahmedabad');
      await tester.pump();
      expect(find.text('Ahmedabad'), findsWidgets);
      expect(find.text('Goa'), findsNothing);

      await tester.enterText(find.byKey(const Key('explore-search')), 'mumbai');
      await tester.pump();
      expect(find.text('Mumbai'), findsWidgets);
      expect(find.text('Goa'), findsNothing);
    });

    testWidgets('trip readiness progress comes from stored checklist items', (tester) async {
      // Tall screen so the lower guidance cards are built as well.
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const trip = SavedTrip(
        id: 'trip-readiness-1',
        userId: 'u1',
        destination: 'Goa',
        budget: 'Moderate',
        days: 3,
        interest: 'Beach',
        itinerary: 'Day 1',
        createdAt: null,
      );

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const TripReadinessPage(trip: trip),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byKey(const Key('readiness-summary')), findsOneWidget);
      expect(find.text('0 of 7 tasks completed'), findsOneWidget);

      await tester.tap(find.byKey(const Key('readiness-check-government-id')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('1 of 7 tasks completed'), findsOneWidget);
      expect(find.textContaining('not a live forecast'), findsOneWidget);
    });

    test('the guidance is limited to real destination data', () {
      // Every destination with an attraction guide also exists in the catalogue.
      for (final id in AttractionCatalog.destinationIds) {
        expect(DestinationCatalog.byId(id), isNotNull, reason: id);
      }
    });
  });
}
