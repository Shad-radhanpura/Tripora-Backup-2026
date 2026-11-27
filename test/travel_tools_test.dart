import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tripora/services/travel_tools.dart';

void main() {
  group('CurrencyConverter', () {
    test('converts through USD and returns null for unknown codes', () {
      final usdToInr = CurrencyConverter.convert(
        amount: 10,
        from: 'USD',
        to: 'INR',
      );
      expect(usdToInr, closeTo(835, 0.0001));

      final same = CurrencyConverter.convert(
        amount: 42,
        from: 'EUR',
        to: 'EUR',
      );
      expect(same, closeTo(42, 0.0001));

      expect(
        CurrencyConverter.convert(amount: 1, from: 'XXX', to: 'INR'),
        isNull,
      );
      expect(
        CurrencyConverter.convert(
          amount: double.nan,
          from: 'USD',
          to: 'INR',
        ),
        isNull,
      );
    });
  });

  group('LuggagePlan', () {
    test('adds quantities and reports the remaining allowance', () {
      const plan = LuggagePlan(
        allowanceKg: 15,
        items: [
          LuggageItem(name: 'Cabin bag', kg: 3, quantity: 1),
          LuggageItem(name: 'Clothes', kg: 0.7, quantity: 6),
        ],
      );
      expect(plan.totalKg, closeTo(7.2, 0.0001));
      expect(plan.remainingKg, closeTo(7.8, 0.0001));
      expect(plan.isOverAllowance, isFalse);
    });

    test('flags an overweight bag', () {
      const plan = LuggagePlan(
        allowanceKg: 15,
        items: [LuggageItem(name: 'Suitcase', kg: 16)],
      );
      expect(plan.isOverAllowance, isTrue);
      expect(plan.remainingKg, closeTo(-1, 0.0001));
    });
  });

  group('BudgetEstimate', () {
    test('uses nights = days - 1 and adds a 10% buffer', () {
      final result = BudgetEstimate.tiers['Budget']!.breakdown(days: 3);
      // 2 nights x 1500 = 3000; food 3 x 600 = 1800;
      // transport 3 x 300 = 900; activities 3 x 400 = 1200.
      expect(result.stay, 3000);
      expect(result.food, 1800);
      expect(result.transport, 900);
      expect(result.activities, 1200);
      expect(result.buffer, 690);
      expect(result.total, 7590);
    });

    test('never returns negative nights or zero days', () {
      final result = BudgetEstimate.tiers['Luxury']!.breakdown(
        days: 0,
        travellers: 0,
      );
      expect(result.stay, 0);
      expect(result.food, 3000);
    });

    test('scales with travellers', () {
      final one = BudgetEstimate.tiers['Moderate']!.breakdown(days: 4);
      final two = BudgetEstimate.tiers['Moderate']!.breakdown(
        days: 4,
        travellers: 2,
      );
      expect(two.stay, one.stay * 2);
    });
  });

  group('ExpenseSplitter', () {
    test('balances always sum to zero, even with uneven cents', () {
      final expenses = [
        const SharedExpense(
          payer: 'Asha',
          amountCents: 1000,
          participants: ['Asha', 'Ben', 'Chen'],
        ),
        const SharedExpense(
          payer: 'Ben',
          amountCents: 250,
          participants: ['Asha', 'Ben'],
        ),
      ];
      final balance = ExpenseSplitter.balances(expenses);
      expect(balance.values.fold(0, (a, b) => a + b), 0);
      expect(balance['Asha']! > 0, isTrue);
      expect(balance['Chen'], -333);
    });

    test('settlements clear every balance', () {
      final expenses = [
        const SharedExpense(
          payer: 'Asha',
          amountCents: 9000,
          participants: ['Asha', 'Ben', 'Chen'],
        ),
        const SharedExpense(
          payer: 'Ben',
          amountCents: 3000,
          participants: ['Ben', 'Chen'],
        ),
      ];
      final balance = ExpenseSplitter.balances(expenses);
      final payments = ExpenseSplitter.settlements(expenses);

      final after = Map<String, int>.from(balance);
      for (final p in payments) {
        after[p.from] = after[p.from]! + p.amountCents;
        after[p.to] = after[p.to]! - p.amountCents;
      }
      expect(after.values.every((v) => v == 0), isTrue);
    });

    test('no expenses means no settlements', () {
      expect(ExpenseSplitter.settlements(const []), isEmpty);
    });

    test('ignores expenses with no participants or non-positive amounts', () {
      final balance = ExpenseSplitter.balances(const [
        SharedExpense(payer: 'A', amountCents: 500, participants: []),
        SharedExpense(payer: 'A', amountCents: 0, participants: ['A', 'B']),
      ]);
      expect(balance, isEmpty);
    });
  });

  group('TripReadiness', () {
    test('a fully prepared trip scores 100 with nothing missing', () {
      final result = TripReadiness.calculate(
        checklistDone: 7,
        checklistTotal: 7,
        hasItinerary: true,
        hasBooking: true,
      );
      expect(result.score, 100);
      expect(result.missing, isEmpty);
    });

    test('an empty trip lists what is missing', () {
      final result = TripReadiness.calculate(
        checklistDone: 0,
        checklistTotal: 0,
        hasItinerary: false,
        hasBooking: false,
      );
      expect(result.score, 0);
      expect(result.missing.length, 3);
    });

    test('partial checklist gives proportional points', () {
      final result = TripReadiness.calculate(
        checklistDone: 3,
        checklistTotal: 6,
        hasItinerary: true,
        hasBooking: false,
      );
      expect(result.score, 50); // 30 + 20 + 0
    });
  });

  group('SurprisePicker', () {
    test('returns a catalogue destination and respects category', () {
      final pick = SurprisePicker.pick(random: Random(1), category: 'Beach');
      expect(pick.hasCategory('Beach'), isTrue);
    });

    test('avoids the destination it was asked to avoid when possible', () {
      final first = SurprisePicker.pick(random: Random(7));
      for (var seed = 0; seed < 20; seed++) {
        final next = SurprisePicker.pick(
          random: Random(seed),
          avoid: first,
        );
        expect(next.id, isNot(first.id));
      }
    });
  });
}
