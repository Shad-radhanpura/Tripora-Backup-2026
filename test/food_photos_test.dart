// Food Explorer photos: every dish has a bundled, real JPEG with a credit, and a
// photo that cannot be loaded shows a readable fallback instead of a broken image.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/data/demo_catalogue.dart';
import 'package:tripora/data/destinations.dart';
import 'package:tripora/data/local_food.dart';
import 'package:tripora/screens/food_explorer_page.dart';
import 'package:tripora/theme/theme.dart';
import 'package:tripora/widgets/dish_photo.dart';

void main() {
  group('bundled dish photos', () {
    test('every dish with a photo has a photo file that exists and is a JPEG', () {
      for (final dish in FoodCatalog.all.where((d) => d.hasPhoto)) {
        final image = dish.image!;
        final file = File(image);
        expect(file.existsSync(), isTrue, reason: '${dish.name}: $image');
        expect(image, startsWith('assets/food/'), reason: dish.name);
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(5000), reason: dish.name);
        // JPEG files start with FF D8 FF.
        expect(bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF], reason: dish.name);
      }
    });

    test('every photo is used by one dish only', () {
      final images = <String>[
        for (final dish in FoodCatalog.all)
          if (dish.hasPhoto) dish.image!,
      ];
      expect(images.toSet().length, images.length);
    });

    test('every photo has an author, a licence and a Wikimedia Commons source', () {
      for (final dish in FoodCatalog.all.where((d) => d.hasPhoto)) {
        final credit = dish.credit!;
        expect(credit.author.trim(), isNotEmpty, reason: dish.name);
        expect(
          credit.licence,
          anyOf(startsWith('CC '), equals('Public domain')),
          reason: dish.name,
        );
        expect(
          credit.source,
          startsWith('https://commons.wikimedia.org/wiki/File:'),
          reason: dish.name,
        );
      }
    });

    test('a dish without a verified photo has no image or credit, and is not a photo', () {
      for (final dish in FoodCatalog.all.where((d) => !d.hasPhoto)) {
        expect(dish.image, isNull, reason: dish.name);
        expect(dish.credit, isNull, reason: dish.name);
      }
    });

    test('every Indian destination has at least five dishes, and there are 150 in all', () {
      for (final id in DemoCatalogue.indianDestinationIds) {
        expect(FoodCatalog.forDestination(id).length, greaterThanOrEqualTo(5), reason: id);
      }
      expect(FoodCatalog.all.length, greaterThanOrEqualTo(150));
    });

    test('dish names are unique within each destination', () {
      for (final id in FoodCatalog.destinationIds) {
        final names = FoodCatalog.forDestination(id).map((d) => d.name).toList();
        expect(names.toSet().length, names.length, reason: id);
      }
    });

    test('Manali lists the dishes with photos, and no dish without one', () {
      final names = FoodCatalog.forDestination('manali').map((d) => d.name).toList();
      expect(names, containsAll(['Siddu', 'Madra', 'Dham', 'Veg momos', 'River trout']));
      expect(names, isNot(contains('Chha gosht')));
      expect(names, isNot(contains('Babru')));
    });

    test('every food guide belongs to a catalogue destination', () {
      for (final id in FoodCatalog.destinationIds) {
        expect(DestinationCatalog.byId(id), isNotNull, reason: id);
      }
    });
  });

  group('screens', () {
    testWidgets('a photo that cannot be loaded shows its name, not a broken image', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const Scaffold(
          body: DishPhoto(asset: 'assets/food/does-not-exist.jpg', label: 'Test dish'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Test dish'), findsOneWidget);
      expect(find.byType(DishPhotoFallback), findsOneWidget);
    });

    testWidgets('a bundled photo is shown without the fallback', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const Scaffold(
          body: DishPhoto(asset: 'assets/food/dhokla.jpg', label: 'Dhokla'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(DishPhotoFallback), findsNothing);
    });

    testWidgets('Goa shows a photo and a credit for each dish', (tester) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const FoodExplorerPage(destinationId: 'goa'),
      ));
      await tester.pumpAndSettle();

      final goa = FoodCatalog.forDestination('goa');
      expect(find.byType(DishPhoto), findsNWidgets(goa.where((d) => d.hasPhoto).length));
      for (final dish in goa) {
        expect(find.byKey(Key('food-credit-${dish.name}')), findsOneWidget, reason: dish.name);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a dish with no verified photo shows a labelled placeholder, not a photo', (tester) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const FoodExplorerPage(destinationId: 'kochi'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('food-placeholder-Fish molee')), findsOneWidget);
      expect(find.byKey(const Key('food-photo-Fish molee')), findsNothing);
      expect(
        find.text('Placeholder: no verified photo for this dish yet.'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a photo opens a larger view; × returns to the same page', (tester) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const FoodExplorerPage(destinationId: 'goa'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('food-photo-Goan fish curry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('image-detail-dialog')), findsOneWidget);
      expect(find.text('Destination: Goa'), findsOneWidget);

      await tester.tap(find.byKey(const Key('image-detail-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('image-detail-dialog')), findsNothing);
      expect(find.text('Goan fish curry'), findsOneWidget);
    });

    testWidgets('Escape also closes the larger view', (tester) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const FoodExplorerPage(destinationId: 'goa'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('food-photo-Bebinca')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('image-detail-dialog')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('image-detail-dialog')), findsNothing);
    });
  });
}
