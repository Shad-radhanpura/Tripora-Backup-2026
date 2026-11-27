// Travel journal: validation, private ownership, saving on this device, the
// calendar, and the editor. Storage is an in-memory mock and Firebase is faked;
// nothing touches the live project.
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/models/journal_entry.dart';
import 'package:tripora/screens/journal_editor_page.dart';
import 'package:tripora/screens/journal_pages.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/journal_store.dart';
import 'package:tripora/theme/theme.dart';

const _me = 'journal-owner';
const _other = 'journal-other';

Future<JournalStore> _store({DateTime Function()? clock}) async {
  final prefs = await SharedPreferences.getInstance();
  final store = JournalStore(prefs, clock);
  await store.load();
  return store;
}

Future<JournalEntry> _add(
  JournalStore store, {
  String uid = _me,
  String title = 'Monsoon week in Kerala',
  String place = 'Munnar',
  DateTime? start,
  DateTime? end,
  List<JournalExpense> expenses = const [],
}) {
  return store.create(
    uid: uid,
    title: title,
    place: place,
    city: 'Munnar',
    state: 'Kerala',
    tripDate: start,
    endDate: end,
    description: 'Tea gardens in the mist and long walks before the rain.',
    highlights: const ['Tea museum'],
    placesVisited: const ['Eravikulam'],
    expenses: expenses,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('validation', () {
    test('title and place are required', () {
      expect(JournalRules.validateTitle('ab'), isNotNull);
      expect(JournalRules.validateTitle('Good trip'), isNull);
      expect(JournalRules.validatePlace('  '), isNotNull);
      expect(JournalRules.validatePlace('Goa'), isNull);
    });

    test('an end date before the start date is refused', () {
      expect(
        JournalRules.validateDates(start: DateTime(2026, 11, 5), end: DateTime(2026, 11, 4)),
        isNotNull,
      );
      expect(
        JournalRules.validateDates(start: DateTime(2026, 11, 5), end: DateTime(2026, 11, 5)),
        isNull,
      );
      expect(JournalRules.validateDates(start: null, end: DateTime(2026, 11, 4)), isNull);
    });

    test('lists keep one item per line and respect the limits', () {
      expect(JournalRules.cleanList('  Tea museum \n\n Lake \n'), ['Tea museum', 'Lake']);
      expect(JournalRules.validateList(List.filled(JournalRules.listMax + 1, 'a'), 'highlights'), isNotNull);
    });
  });

  group('store', () {
    test('an entry is saved for its owner and only the owner sees it', () async {
      final store = await _store();
      final saved = await _add(store);

      expect(store.forUser(_me).single.id, saved.id);
      expect(store.forUser(_other), isEmpty);
    });

    test('invalid input is refused and nothing is saved', () async {
      final store = await _store();

      await expectLater(_add(store, title: 'no'), throwsA(isA<ArgumentError>()));
      await expectLater(
        _add(store, start: DateTime(2026, 11, 5), end: DateTime(2026, 11, 1)),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        _add(store, expenses: const [JournalExpense(label: 'Hotel', amount: -10)]),
        throwsA(isA<ArgumentError>()),
      );
      expect(store.forUser(_me), isEmpty);
    });

    test('signing out (no account) cannot write an entry', () async {
      final store = await _store();
      await expectLater(_add(store, uid: ''), throwsA(isA<ArgumentError>()));
    });

    test('the owner can edit; another person cannot', () async {
      final store = await _store();
      final entry = await _add(store);

      final edited = await store.update(
        uid: _me,
        id: entry.id,
        title: 'Monsoon week in Kerala, revised',
        place: 'Munnar',
        tripDate: DateTime(2026, 11, 2),
      );
      expect(edited.title, 'Monsoon week in Kerala, revised');
      expect(edited.createdAt, entry.createdAt);

      await expectLater(
        store.update(uid: _other, id: entry.id, title: 'Changed by someone else', place: 'Goa'),
        throwsA(isA<NotOwnerError>()),
      );
      expect(store.byId(entry.id)!.title, 'Monsoon week in Kerala, revised');
    });

    test('clearing the start date keeps the end date as entered', () async {
      final store = await _store();
      final entry = await _add(store, start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 6));

      final cleared = await store.update(
        uid: _me,
        id: entry.id,
        title: entry.title,
        place: entry.place,
        tripDate: null,
        endDate: DateTime(2026, 11, 6),
      );
      expect(cleared.tripDate, isNull);
      expect(cleared.endDate, DateTime(2026, 11, 6));
    });

    test('another person cannot delete; the owner can, and it stays deleted after a restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = JournalStore(prefs);
      await store.load();
      final kept = await _add(store, title: 'Trip worth keeping');
      final removed = await _add(store, title: 'Trip to remove');

      await expectLater(store.delete(uid: _other, id: removed.id), throwsA(isA<NotOwnerError>()));
      await store.delete(uid: _me, id: removed.id);

      final reopened = JournalStore(prefs);
      await reopened.load();
      expect(reopened.forUser(_me).map((e) => e.id), [kept.id]);
    });

    test('expenses are saved and totalled', () async {
      final store = await _store();
      final entry = await _add(
        store,
        expenses: const [
          JournalExpense(label: 'Homestay', amount: 2400),
          JournalExpense(label: 'Tea museum ticket', amount: 150),
        ],
      );
      expect(entry.expenseTotal, 2550);
    });

    test('a damaged entry is skipped and the rest still load', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        JournalStore.storageKey,
        '[${_sampleJson('jrn_good', _me)}, {"id": "broken"}]',
      );
      final store = JournalStore(prefs);
      await store.load();

      expect(store.readFailed, isFalse);
      expect(store.forUser(_me).map((e) => e.id), ['jrn_good']);
    });

    test('unreadable storage blocks writes so the saved data is not overwritten', () async {
      final prefs = await SharedPreferences.getInstance();
      const broken = '{not valid json';
      await prefs.setString(JournalStore.storageKey, broken);
      final store = JournalStore(prefs);
      await store.load();

      expect(store.readFailed, isTrue);
      await expectLater(_add(store), throwsA(isA<StateError>()));
      expect(prefs.getString(JournalStore.storageKey), broken);
    });
  });

  group('calendar coverage', () {
    test('a single-date entry covers only its day', () async {
      final store = await _store();
      final entry = await _add(store, start: DateTime(2026, 11, 2));
      expect(journalCoversDay(entry, DateTime(2026, 11, 2)), isTrue);
      expect(journalCoversDay(entry, DateTime(2026, 11, 3)), isFalse);
    });

    test('a journey covers every day from start to end', () async {
      final store = await _store();
      final entry = await _add(store, start: DateTime(2026, 11, 2), end: DateTime(2026, 11, 4));
      expect(journalCoversDay(entry, DateTime(2026, 11, 1)), isFalse);
      expect(journalCoversDay(entry, DateTime(2026, 11, 3)), isTrue);
      expect(journalCoversDay(entry, DateTime(2026, 11, 4)), isTrue);
      expect(journalCoversDay(entry, DateTime(2026, 11, 5)), isFalse);
    });

    test('an entry without a date is not on the calendar', () async {
      final store = await _store();
      final entry = await _add(store);
      expect(journalCoversDay(entry, DateTime(2026, 11, 2)), isFalse);
    });
  });

  group('screens', () {
    setUpAll(() {
      // Create the fake database before any FieldValue is used in this file.
      FakeFirebaseFirestore();
    });

    setUp(() {
      AppFirebase.useForTesting(
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: _me, email: 'owner@example.com'),
        ),
        db: FakeFirebaseFirestore(),
      );
    });

    testWidgets('the editor blocks an empty entry and shows the problems', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const JournalEditorPage(),
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('journal-save')));
      await tester.pump();

      expect(find.text('Add a title (at least 3 characters).'), findsOneWidget);
      expect(find.text('Enter the place you visited.'), findsOneWidget);
    });

    testWidgets('the calendar lists the entries on a selected day', (tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = JournalStore.instance;
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, 10);
      await tester.runAsync(() async {
        await store.load();
        for (final e in store.forUser(_me)) {
          await store.delete(uid: _me, id: e.id);
        }
        await store.create(
          uid: _me,
          title: 'Calendar day trip',
          place: 'Lonavala',
          tripDate: day,
        );
      });

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const JournalCalendarPage(),
      ));
      await tester.pump();

      await tester.tap(find.byKey(const Key('calendar-day-10')));
      await tester.pump();

      expect(find.text('Calendar day trip'), findsWidgets);
      expect(find.byKey(Key('journal-card-${store.forUser(_me).first.id}')), findsOneWidget);
    });
  });
}

String _sampleJson(String id, String uid) =>
    '{"id":"$id","userId":"$uid","title":"Saved good entry","place":"Munnar",'
    '"city":"","state":"","tripDate":null,"endDate":null,"companions":"",'
    '"description":"","notes":"","highlights":[],"placesVisited":[],"expenses":[],'
    '"createdAt":"2026-10-01T09:00:00.000","updatedAt":"2026-10-01T09:00:00.000"}';
