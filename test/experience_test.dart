// Travel experiences: validation, ownership, saving on this device, and the
// screens that create, edit, read and delete them. Storage is an in-memory
// mock and Firebase is faked; nothing touches the live project.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/models/travel_experience.dart';
import 'package:tripora/screens/experience_editor_page.dart';
import 'package:tripora/screens/experiences_page.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/experience_store.dart';
import 'package:tripora/theme/theme.dart';

const _author = 'author-uid';
const _reader = 'reader-uid';

/// A valid experience, with only the parts a test wants to change.
Future<TravelExperience> _add(
  ExperienceStore store, {
  String authorId = _author,
  String destinationId = 'goa',
  String destinationName = 'Goa',
  String title = 'Five days on the Goa coast',
  int rating = 5,
}) {
  return store.create(
    authorId: authorId,
    authorName: 'Test Traveller',
    destinationId: destinationId,
    destinationName: destinationName,
    title: title,
    story: 'We stayed near Palolem and ate fish curry every single evening.',
    tips: 'Book the beach shack early in the season.',
    highlights: const ['Palolem beach', 'Fish curry'],
    rating: rating,
  );
}

Future<ExperienceStore> _store({DateTime Function()? clock}) async {
  final prefs = await SharedPreferences.getInstance();
  final store = ExperienceStore(prefs, clock);
  await store.load();
  return store;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('validation', () {
    test('title, story and rating limits', () {
      expect(ExperienceRules.validateTitle('abc'), isNotNull);
      expect(ExperienceRules.validateTitle('Good trip'), isNull);
      expect(ExperienceRules.validateTitle('x' * 81), isNotNull);
      expect(ExperienceRules.validateStory('too short'), isNotNull);
      expect(ExperienceRules.validateStory('a' * 40), isNull);
      expect(ExperienceRules.validateStory('a' * 2001), isNotNull);
      expect(ExperienceRules.validateRating(null), isNotNull);
      expect(ExperienceRules.validateRating(0), isNotNull);
      expect(ExperienceRules.validateRating(6), isNotNull);
      expect(ExperienceRules.validateRating(3), isNull);
    });

    test('highlights are one per line, trimmed, and at most five', () {
      expect(
        ExperienceRules.parseHighlights('  Goa beach \n\n Dhokla \n'),
        ['Goa beach', 'Dhokla'],
      );
      expect(ExperienceRules.validateHighlights(List.filled(5, 'a')), isNull);
      expect(ExperienceRules.validateHighlights(List.filled(6, 'a')), isNotNull);
    });

    test('check reports the first problem as an ArgumentError', () {
      expect(
        () => ExperienceRules.check(
          title: 'Good trip',
          story: 'a' * 50,
          tips: '',
          highlights: const [],
          rating: 4,
          destinationId: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('store: create, edit and delete', () {
    test('a valid experience is saved with its author and destination', () async {
      final store = await _store();
      final saved = await _add(store);

      expect(store.all.single.id, saved.id);
      expect(saved.authorId, _author);
      expect(saved.destinationName, 'Goa');
      expect(store.byAuthor(_author), hasLength(1));
      expect(store.byAuthor(_reader), isEmpty);
    });

    test('invalid input is refused and nothing is saved', () async {
      final store = await _store();

      await expectLater(
        _add(store, title: 'hi'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        _add(store, rating: 9),
        throwsA(isA<ArgumentError>()),
      );
      expect(store.all, isEmpty);
    });

    test('a signed-out person cannot publish', () async {
      final store = await _store();
      await expectLater(
        _add(store, authorId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(store.all, isEmpty);
    });

    test('the author can edit; updatedAt moves and publishedAt stays', () async {
      var now = DateTime(2026, 10, 1, 9);
      final store = await _store(clock: () => now);
      final original = await _add(store);

      now = DateTime(2026, 10, 3, 9);
      final updated = await store.update(
        uid: _author,
        id: original.id,
        destinationId: 'goa',
        destinationName: 'Goa',
        title: 'Seven days on the Goa coast',
        story: 'We stayed near Palolem and ate fish curry every single evening.',
        tips: '',
        highlights: const [],
        rating: 4,
      );

      expect(updated.title, 'Seven days on the Goa coast');
      expect(updated.rating, 4);
      expect(updated.publishedAt, original.publishedAt);
      expect(updated.updatedAt, DateTime(2026, 10, 3, 9));
      expect(store.byId(original.id)!.title, 'Seven days on the Goa coast');
    });

    test('another person cannot edit the experience', () async {
      final store = await _store();
      final original = await _add(store);

      await expectLater(
        store.update(
          uid: _reader,
          id: original.id,
          destinationId: 'goa',
          destinationName: 'Goa',
          title: 'Changed by someone else',
          story: 'We stayed near Palolem and ate fish curry every single evening.',
          tips: '',
          highlights: const [],
          rating: 1,
        ),
        throwsA(isA<NotAuthorError>()),
      );
      expect(store.byId(original.id)!.title, 'Five days on the Goa coast');
    });

    test('another person cannot delete the experience', () async {
      final store = await _store();
      final original = await _add(store);

      await expectLater(
        store.delete(uid: _reader, id: original.id),
        throwsA(isA<NotAuthorError>()),
      );
      expect(store.byId(original.id), isNotNull);
    });

    test('the author can delete, and the deletion is kept after a restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = ExperienceStore(prefs);
      await store.load();
      final kept = await _add(store, title: 'Trip worth keeping');
      final removed = await _add(store, title: 'Trip to remove soon');

      await store.delete(uid: _author, id: removed.id);

      final reopened = ExperienceStore(prefs);
      await reopened.load();
      expect(reopened.all.map((e) => e.id), [kept.id]);
    });

    test('the feed is newest first', () async {
      var now = DateTime(2026, 9, 1);
      final store = await _store(clock: () => now);
      await _add(store, title: 'First trip to Goa');
      now = DateTime(2026, 9, 20);
      await _add(store, title: 'Second trip to Goa');

      expect(store.all.map((e) => e.title), ['Second trip to Goa', 'First trip to Goa']);
    });
  });

  group('store: storage safety', () {
    test('a damaged record is skipped and the rest still load', () async {
      final prefs = await SharedPreferences.getInstance();
      final good = _sampleJson('exp_good');
      await prefs.setString(
        ExperienceStore.storageKey,
        '[$good, {"id": "broken"}, "not an object"]',
      );

      final store = ExperienceStore(prefs);
      await store.load();

      expect(store.readFailed, isFalse);
      expect(store.all.map((e) => e.id), ['exp_good']);
    });

    test('unreadable storage blocks new saves so the data is not overwritten', () async {
      final prefs = await SharedPreferences.getInstance();
      const broken = '{not valid json';
      await prefs.setString(ExperienceStore.storageKey, broken);

      final store = ExperienceStore(prefs);
      await store.load();
      expect(store.readFailed, isTrue);

      await expectLater(_add(store), throwsA(isA<StateError>()));
      expect(prefs.getString(ExperienceStore.storageKey), broken);
    });
  });

  group('screens', () {
    setUp(() {
      AppFirebase.useForTesting(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: _author, email: 'author@example.com', displayName: 'Ana'),
        ),
        db: FakeFirebaseFirestore(),
      );
    });

    Widget app(Widget home) => MaterialApp(
      theme: TriporaTheme.lightTheme,
      darkTheme: TriporaTheme.darkTheme,
      home: home,
    );

    testWidgets('the feed says the records are kept on this device', (tester) async {
      await tester.runAsync(_resetInstance);
      final store = ExperienceStore.instance;
      await tester.runAsync(() async {
        await store.load();
        await _add(store, title: 'Trip shown in the feed');
      });

      await tester.pumpWidget(app(const ExperienceFeedPage()));
      await tester.pump();

      expect(find.byKey(const Key('experience-device-notice')), findsOneWidget);
      expect(find.textContaining('Saved on this device only'), findsOneWidget);
      expect(find.text('Trip shown in the feed'), findsOneWidget);
    });

    testWidgets('the rating filter hides lower-rated experiences', (tester) async {
      await tester.runAsync(_resetInstance);
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = ExperienceStore.instance;
      await tester.runAsync(() async {
        await store.load();
        await _add(store, title: 'Five star trip', rating: 5);
        await _add(store, title: 'Two star trip', rating: 2);
      });

      await tester.pumpWidget(app(const ExperienceFeedPage()));
      await tester.pump();
      expect(find.text('Two star trip'), findsOneWidget);

      await tester.tap(find.byKey(const Key('feed-rating-4')));
      await tester.pump();
      expect(find.text('Two star trip'), findsNothing);
      expect(find.text('Five star trip'), findsOneWidget);
    });

    testWidgets('the author sees edit and delete on their own experience', (tester) async {
      await tester.runAsync(_resetInstance);
      final store = ExperienceStore.instance;
      late TravelExperience mine;
      late TravelExperience theirs;
      await tester.runAsync(() async {
        await store.load();
        mine = await _add(store, title: 'My own trip story');
        theirs = await _add(store, authorId: _reader, title: 'Somebody else trip');
      });

      await tester.pumpWidget(app(ExperienceDetailPage(experienceId: mine.id)));
      await tester.pump();
      expect(find.byKey(const Key('experience-edit')), findsOneWidget);
      expect(find.byKey(const Key('experience-delete')), findsOneWidget);

      await tester.pumpWidget(app(ExperienceDetailPage(experienceId: theirs.id)));
      await tester.pump();
      expect(find.byKey(const Key('experience-edit')), findsNothing);
      expect(find.byKey(const Key('experience-delete')), findsNothing);
      expect(find.textContaining('By Test Traveller'), findsOneWidget);
    });

    testWidgets('the editor blocks an empty form and shows the problems', (tester) async {
      await tester.runAsync(_resetInstance);
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const ExperienceEditorPage()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('experience-save')));
      await tester.pump();

      expect(find.text('Add a title (at least 4 characters).'), findsOneWidget);
      expect(find.text('Choose the destination you visited.'), findsOneWidget);
      expect(find.text('Choose a rating from 1 to 5 stars.'), findsOneWidget);
      expect(ExperienceStore.instance.byAuthor(_author), isEmpty);
    });

    testWidgets('the editor publishes a valid experience with a rating', (tester) async {
      await tester.runAsync(_resetInstance);
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.runAsync(() => ExperienceStore.instance.load());
      await tester.pumpWidget(app(const ExperienceEditorPage()));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('experience-title')), 'Monsoon days in Goa');
      await tester.enterText(
        find.byKey(const Key('experience-story')),
        'We stayed near the beach for a week and ate fish curry every evening.',
      );
      await tester.tap(find.byKey(const Key('experience-star-4')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('experience-destination')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Goa').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('experience-save')));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      final mine = ExperienceStore.instance.byAuthor(_author);
      expect(mine.map((e) => e.title), contains('Monsoon days in Goa'));
      final saved = mine.firstWhere((e) => e.title == 'Monsoon days in Goa');
      expect(saved.rating, 4);
      expect(saved.destinationId, 'goa');
      expect(saved.authorId, _author);
    });
  });
}

/// The screens use the shared store, so clear it before each widget test.
Future<void> _resetInstance() async {
  final store = ExperienceStore.instance;
  await store.load();
  for (final item in List.of(store.all)) {
    await store.delete(uid: item.authorId, id: item.id);
  }
}

String _sampleJson(String id) =>
    '{"id":"$id","authorId":"$_author","authorName":"Ana","destinationId":"goa",'
    '"destinationName":"Goa","tripId":null,"title":"Saved good trip",'
    '"story":"A saved story that is long enough to read back correctly.",'
    '"tips":"","highlights":[],"rating":5,'
    '"publishedAt":"2026-10-01T09:00:00.000","updatedAt":"2026-10-01T09:00:00.000"}';
