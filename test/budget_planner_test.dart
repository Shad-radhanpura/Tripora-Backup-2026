// Trip budget planner: the estimate maths, input checks, the expense log, and
// the planner screen. Storage is an in-memory mock and Firebase is faked.
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/screens/trip_budget_planner_page.dart';
import 'package:tripora/services/app_firebase.dart';
import 'package:tripora/services/budget_store.dart';
import 'package:tripora/services/trip_budget_planner.dart';
import 'package:tripora/theme/theme.dart';

const _me = 'budget-owner';
const _other = 'budget-other';

PlanInputs _plan({
  int adults = 2,
  int children = 0,
  int rooms = 1,
  int nights = 3,
  BudgetTier tier = BudgetTier.moderate,
  int outbound = 0,
  int returnFare = 0,
  int entry = 0,
  int shopping = 0,
  int insurance = 0,
  int misc = 0,
  int prepaid = 0,
}) {
  final start = DateTime(2026, 11, 10);
  return PlanInputs(
    startDate: start,
    endDate: start.add(Duration(days: nights)),
    adults: adults,
    children: children,
    rooms: rooms,
    tier: tier,
    outboundFarePerPerson: outbound,
    returnFarePerPerson: returnFare,
    entryTicketsPerTraveller: entry,
    shoppingPerAdult: shopping,
    insurancePerTraveller: insurance,
    miscellaneousTotal: misc,
    prepaidTotal: prepaid,
  );
}

Future<BudgetStore> _store() async {
  final prefs = await SharedPreferences.getInstance();
  final store = BudgetStore(prefs);
  await store.load();
  return store;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('estimate', () {
    test('accommodation is priced per room, not per traveller', () {
      final small = BudgetPlanResult.calculate(_plan(adults: 2, rooms: 1, nights: 3));
      final large = BudgetPlanResult.calculate(_plan(adults: 4, rooms: 1, nights: 3));
      expect(small.amountFor('stay'), BudgetTier.moderate.roomPerNight * 3);
      expect(large.amountFor('stay'), small.amountFor('stay'));
    });

    test('two rooms double the accommodation', () {
      final one = BudgetPlanResult.calculate(_plan(adults: 4, rooms: 1, nights: 2));
      final two = BudgetPlanResult.calculate(_plan(adults: 4, rooms: 2, nights: 2));
      expect(two.amountFor('stay'), one.amountFor('stay') * 2);
    });

    test('food and activities count children as half an adult', () {
      final adultsOnly = BudgetPlanResult.calculate(_plan(adults: 2, children: 0, nights: 1, rooms: 1));
      final withChild = BudgetPlanResult.calculate(_plan(adults: 2, children: 2, nights: 1, rooms: 1));
      // 2 adults + 2 children = 3 adult equivalents, so food is 1.5 × the 2-adult figure.
      expect(withChild.amountFor('food'), (adultsOnly.amountFor('food') * 1.5).round());
    });

    test('fares are per person, both ways, for every traveller', () {
      final result = BudgetPlanResult.calculate(_plan(adults: 2, children: 1, outbound: 500, returnFare: 400));
      expect(result.amountFor('transport'), (500 + 400) * 3);
    });

    test('contingency is 10% of the subtotal and the total adds it back', () {
      final result = BudgetPlanResult.calculate(_plan(outbound: 1000));
      expect(result.contingency, (result.subtotal * 0.10).round());
      expect(result.total, result.subtotal + result.contingency);
    });

    test('per person divides the total by the number of travellers', () {
      final result = BudgetPlanResult.calculate(_plan(adults: 3, children: 1, outbound: 300));
      expect(result.perPerson, (result.total / 4).round());
    });

    test('money already paid is shown and not counted twice', () {
      final result = BudgetPlanResult.calculate(_plan(prepaid: 2000));
      expect(result.prepaid, 2000);
      expect(result.stillToPay, (result.total - 2000).clamp(0, result.total));
    });

    test('a same-day trip has no accommodation', () {
      final result = BudgetPlanResult.calculate(_plan(nights: 0));
      expect(result.amountFor('stay'), 0);
      expect(_plan(nights: 0).days, 1);
    });

    test('the three tiers differ and the Luxury estimate is the largest', () {
      final base = _plan(adults: 2, nights: 4);
      final budget = BudgetPlanResult.calculate(base, tier: BudgetTier.budget);
      final moderate = BudgetPlanResult.calculate(base, tier: BudgetTier.moderate);
      final luxury = BudgetPlanResult.calculate(base, tier: BudgetTier.luxury);
      expect(budget.total, lessThan(moderate.total));
      expect(moderate.total, lessThan(luxury.total));
    });

    test('the breakdown explains each line', () {
      final result = BudgetPlanResult.calculate(_plan(adults: 2, rooms: 1, nights: 3));
      final stay = result.lines.firstWhere((l) => l.category == 'stay');
      expect(stay.basis, contains('per room per night'));
    });
  });

  group('input checks', () {
    final money = {'Outbound fare': 0};

    test('the end date cannot be before the start date', () {
      expect(
        PlanInputs.validate(
          start: DateTime(2026, 11, 10),
          end: DateTime(2026, 11, 9),
          adults: 1,
          children: 0,
          rooms: 1,
          money: money,
        ),
        isNotNull,
      );
    });

    test('dates are required', () {
      expect(
        PlanInputs.validate(start: null, end: null, adults: 1, children: 0, rooms: 1, money: money),
        isNotNull,
      );
    });

    test('rooms cannot exceed travellers, and there must be an adult', () {
      expect(
        PlanInputs.validate(
          start: DateTime(2026, 11, 10), end: DateTime(2026, 11, 12),
          adults: 2, children: 0, rooms: 3, money: money,
        ),
        isNotNull,
      );
      expect(
        PlanInputs.validate(
          start: DateTime(2026, 11, 10), end: DateTime(2026, 11, 12),
          adults: 0, children: 2, rooms: 1, money: money,
        ),
        isNotNull,
      );
    });

    test('negative amounts are refused', () {
      expect(
        PlanInputs.validate(
          start: DateTime(2026, 11, 10), end: DateTime(2026, 11, 12),
          adults: 1, children: 0, rooms: 1, money: {'Shopping': -5},
        ),
        isNotNull,
      );
    });

    test('a valid plan passes', () {
      expect(
        PlanInputs.validate(
          start: DateTime(2026, 11, 10), end: DateTime(2026, 11, 13),
          adults: 2, children: 1, rooms: 1, money: {'Shopping': 500},
        ),
        isNull,
      );
    });

    test('a saved plan reads back exactly', () {
      final plan = _plan(adults: 3, children: 1, rooms: 2, tier: BudgetTier.luxury, outbound: 900);
      final back = PlanInputs.fromJson(plan.toJson());
      expect(back.adults, 3);
      expect(back.children, 1);
      expect(back.rooms, 2);
      expect(back.tier, BudgetTier.luxury);
      expect(back.outboundFarePerPerson, 900);
      expect(back.nights, plan.nights);
    });
  });

  group('expense log', () {
    test('an expense is saved for its owner and only the owner sees it', () async {
      final store = await _store();
      await store.addExpense(uid: _me, amount: 450, category: 'food', date: DateTime(2026, 11, 11));

      expect(store.expensesFor(_me), hasLength(1));
      expect(store.expensesFor(_other), isEmpty);
    });

    test('invalid expenses are refused', () async {
      final store = await _store();
      await expectLater(
        store.addExpense(uid: _me, amount: 0, category: 'food', date: DateTime(2026, 11, 11)),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        store.addExpense(uid: _me, amount: 100, category: 'unknown', date: DateTime(2026, 11, 11)),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        store.addExpense(uid: _me, amount: 100, category: 'food', date: DateTime(2026, 11, 11), paymentMethod: 'bitcoin'),
        throwsA(isA<ArgumentError>()),
      );
      expect(store.expensesFor(_me), isEmpty);
    });

    test('an expense can be edited and deleted by its owner only', () async {
      final store = await _store();
      final added = await store.addExpense(uid: _me, amount: 450, category: 'food', date: DateTime(2026, 11, 11));

      await store.updateExpense(
        uid: _me, id: added.id, amount: 600, category: 'local', date: DateTime(2026, 11, 12), note: 'Auto fare',
      );
      expect(store.expensesFor(_me).single.amount, 600);
      expect(store.expensesFor(_me).single.category, 'local');

      await expectLater(store.deleteExpense(uid: _other, id: added.id), throwsA(isA<StateError>()));
      await store.deleteExpense(uid: _me, id: added.id);
      expect(store.expensesFor(_me), isEmpty);
    });

    test('the plan and the expenses survive a restart', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = BudgetStore(prefs);
      await store.load();
      await store.savePlan(_me, _plan(adults: 2, tier: BudgetTier.budget));
      await store.addExpense(uid: _me, amount: 300, category: 'entry', date: DateTime(2026, 11, 11), note: 'Fort ticket');

      final reopened = BudgetStore(prefs);
      await reopened.load();
      expect(reopened.planFor(_me)!.tier, BudgetTier.budget);
      expect(reopened.expensesFor(_me).single.note, 'Fort ticket');
      expect(reopened.planFor(_other), isNull);
    });

    test('unreadable saved data blocks writes so it is not overwritten', () async {
      final prefs = await SharedPreferences.getInstance();
      const broken = '{not json';
      await prefs.setString(BudgetStore.storageKey, broken);
      final store = BudgetStore(prefs);
      await store.load();

      expect(store.readFailed, isTrue);
      await expectLater(
        store.addExpense(uid: _me, amount: 100, category: 'food', date: DateTime(2026, 11, 11)),
        throwsA(isA<StateError>()),
      );
      expect(prefs.getString(BudgetStore.storageKey), broken);
    });
  });

  group('planner screen', () {
    setUp(() {
      AppFirebase.useForTesting(
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: _me, email: 'me@example.com')),
        db: FakeFirebaseFirestore(),
      );
    });

    testWidgets('shows the estimate and the three levels', (tester) async {
      tester.view.physicalSize = const Size(900, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const TripBudgetPlannerPage(),
      ));
      await tester.pump();

      expect(find.byKey(const Key('budget-estimate')), findsOneWidget);
      expect(find.byKey(const Key('compare-budget')), findsOneWidget);
      expect(find.byKey(const Key('compare-moderate')), findsOneWidget);
      expect(find.byKey(const Key('compare-luxury')), findsOneWidget);
      expect(find.textContaining('Taxes, booking fees'), findsOneWidget);
    });

    testWidgets('a bad number is flagged and the estimate is hidden', (tester) async {
      tester.view.physicalSize = const Size(900, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const TripBudgetPlannerPage(),
      ));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('budget-outbound')), 'abc');
      await tester.pump();

      expect(find.text('Outbound fare: enter a whole number.'), findsOneWidget);
      expect(find.byKey(const Key('budget-estimate')), findsNothing);
    });

    testWidgets('adding an adult changes the traveller count shown', (tester) async {
      tester.view.physicalSize = const Size(900, 4200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: TriporaTheme.lightTheme,
        home: const TripBudgetPlannerPage(),
      ));
      await tester.pump();

      expect(find.byKey(const Key('budget-adults')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
      await tester.pump();

      expect(tester.widget<Text>(find.byKey(const Key('budget-adults'))).data, '3');
    });
  });
}
