import 'dart:math';

import '../data/destinations.dart';
import '../models/destination.dart';

// Pure calculations behind the Travel Tools screens.
//
// Nothing in this file talks to the network or to Firestore. Every number is
// either an input from the user or a labelled estimate defined here, so the
// logic can be unit tested and never presents a guess as live data.

// ============================================================
// CURRENCY
// ============================================================

/// Converts between currencies using fixed sample rates.
///
/// The rates are NOT live. They are written into the app and must not be used
/// for payments or money transfers. The UI shows [CurrencyConverter.notice]
/// next to every result.
class CurrencyConverter {
  CurrencyConverter._();

  static const String notice =
      'Sample rates for planning only. These are not live exchange rates, '
      'so check your bank or provider before exchanging money.';

  /// Units of each currency per 1 US dollar (sample values).
  static const Map<String, double> unitsPerUsd = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'INR': 83.5,
    'JPY': 150.0,
    'THB': 36.0,
    'AED': 3.67,
    'SGD': 1.34,
  };

  static List<String> get currencies => unitsPerUsd.keys.toList();

  /// Converts [amount] from one currency to another. Returns null if either
  /// currency is unknown or the amount is not a finite number.
  static double? convert({
    required double amount,
    required String from,
    required String to,
  }) {
    final fromRate = unitsPerUsd[from];
    final toRate = unitsPerUsd[to];
    if (fromRate == null || toRate == null || !amount.isFinite) return null;
    return amount / fromRate * toRate;
  }
}

// ============================================================
// LUGGAGE
// ============================================================

/// One item in the luggage planner.
class LuggageItem {
  final String name;
  final double kg;
  final int quantity;

  const LuggageItem({
    required this.name,
    required this.kg,
    this.quantity = 1,
  });

  double get totalKg => kg * quantity;
}

/// Adds up luggage weight against a check-in allowance.
class LuggagePlan {
  final List<LuggageItem> items;
  final double allowanceKg;

  const LuggagePlan({required this.items, required this.allowanceKg});

  double get totalKg => items.fold(0, (sum, item) => sum + item.totalKg);

  /// Positive when there is room left, negative when over the allowance.
  double get remainingKg => allowanceKg - totalKg;

  bool get isOverAllowance => remainingKg < 0;

  /// Typical check-in allowances. Airlines and fare types differ, so the
  /// screen tells the user to check their own ticket.
  static const List<double> typicalAllowancesKg = [15, 20, 23, 25, 30];

  /// Rough typical weights for common items, in kilograms. Estimates only.
  static const List<({String name, double kg})> suggestedItems = [
    (name: 'Cabin bag (empty)', kg: 3.0),
    (name: 'Medium suitcase (empty)', kg: 4.5),
    (name: 'Large suitcase (empty)', kg: 6.0),
    (name: 'Clothes (per outfit set)', kg: 0.7),
    (name: 'Shoes (pair)', kg: 0.8),
    (name: 'Toiletries', kg: 1.0),
    (name: 'Laptop', kg: 1.8),
    (name: 'Jacket', kg: 0.9),
  ];
}

// ============================================================
// BUDGET ESTIMATE
// ============================================================

/// Per-day cost estimate for one traveller, in Indian rupees.
///
/// These are rough planning figures for each budget tier. Real prices vary by
/// season, city and booking date.
class BudgetEstimate {
  final String tier;
  final int stayPerNight;
  final int foodPerDay;
  final int localTransportPerDay;
  final int activitiesPerDay;

  const BudgetEstimate({
    required this.tier,
    required this.stayPerNight,
    required this.foodPerDay,
    required this.localTransportPerDay,
    required this.activitiesPerDay,
  });

  static const String notice =
      'Rough planning estimates in Indian rupees per person. They are not '
      'quotes or live prices. A 10% buffer is added for surprises.';

  static const Map<String, BudgetEstimate> tiers = {
    'Budget': BudgetEstimate(
      tier: 'Budget',
      stayPerNight: 1500,
      foodPerDay: 600,
      localTransportPerDay: 300,
      activitiesPerDay: 400,
    ),
    'Moderate': BudgetEstimate(
      tier: 'Moderate',
      stayPerNight: 4000,
      foodPerDay: 1200,
      localTransportPerDay: 600,
      activitiesPerDay: 1000,
    ),
    'Luxury': BudgetEstimate(
      tier: 'Luxury',
      stayPerNight: 12000,
      foodPerDay: 3000,
      localTransportPerDay: 2000,
      activitiesPerDay: 3000,
    ),
  };

  /// Estimated total for [days] days and [nights] nights, including a 10%
  /// buffer. Nights default to days - 1 (never negative).
  BreakdownResult breakdown({
    required int days,
    int travellers = 1,
    int? nights,
  }) {
    final safeDays = max(days, 1);
    final safeTravellers = max(travellers, 1);
    final safeNights = max(nights ?? safeDays - 1, 0);

    final stay = stayPerNight * safeNights * safeTravellers;
    final food = foodPerDay * safeDays * safeTravellers;
    final transport = localTransportPerDay * safeDays * safeTravellers;
    final activities = activitiesPerDay * safeDays * safeTravellers;
    final subtotal = stay + food + transport + activities;
    final buffer = (subtotal * 0.10).round();

    return BreakdownResult(
      stay: stay,
      food: food,
      transport: transport,
      activities: activities,
      buffer: buffer,
    );
  }
}

class BreakdownResult {
  final int stay;
  final int food;
  final int transport;
  final int activities;
  final int buffer;

  const BreakdownResult({
    required this.stay,
    required this.food,
    required this.transport,
    required this.activities,
    required this.buffer,
  });

  int get total => stay + food + transport + activities + buffer;
}

// ============================================================
// EXPENSE SPLITTING
// ============================================================

/// One shared expense. [payer] paid [amountCents] for [participants].
class SharedExpense {
  final String payer;
  final int amountCents;
  final List<String> participants;

  const SharedExpense({
    required this.payer,
    required this.amountCents,
    required this.participants,
  });
}

/// A payment that settles part of the group's balance.
class Settlement {
  final String from;
  final String to;
  final int amountCents;

  const Settlement({
    required this.from,
    required this.to,
    required this.amountCents,
  });
}

/// Splits shared expenses equally and works out who should pay whom.
///
/// Money is kept in whole cents so totals always add up. Any leftover cent
/// from an uneven split goes to the first participants in the list.
class ExpenseSplitter {
  ExpenseSplitter._();

  /// Net balance per person: positive means they are owed money, negative
  /// means they owe money. The values always sum to zero.
  static Map<String, int> balances(List<SharedExpense> expenses) {
    final balance = <String, int>{};
    for (final expense in expenses) {
      final people = expense.participants.toSet().toList();
      if (people.isEmpty || expense.amountCents <= 0) continue;

      final share = expense.amountCents ~/ people.length;
      var leftover = expense.amountCents - share * people.length;

      balance[expense.payer] =
          (balance[expense.payer] ?? 0) + expense.amountCents;
      for (final person in people) {
        var owed = share;
        if (leftover > 0) {
          owed += 1;
          leftover -= 1;
        }
        balance[person] = (balance[person] ?? 0) - owed;
      }
    }
    return balance;
  }

  /// The smallest simple set of payments that clears all balances.
  static List<Settlement> settlements(List<SharedExpense> expenses) {
    final balance = balances(expenses);
    final creditors = <MapEntry<String, int>>[];
    final debtors = <MapEntry<String, int>>[];
    balance.forEach((person, value) {
      if (value > 0) creditors.add(MapEntry(person, value));
      if (value < 0) debtors.add(MapEntry(person, -value));
    });
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final result = <Settlement>[];
    var c = 0;
    var d = 0;
    final owedLeft = [for (final e in creditors) e.value];
    final oweLeft = [for (final e in debtors) e.value];
    while (c < creditors.length && d < debtors.length) {
      final pay = min(owedLeft[c], oweLeft[d]);
      if (pay > 0) {
        result.add(
          Settlement(
            from: debtors[d].key,
            to: creditors[c].key,
            amountCents: pay,
          ),
        );
      }
      owedLeft[c] -= pay;
      oweLeft[d] -= pay;
      if (owedLeft[c] == 0) c++;
      if (oweLeft[d] == 0) d++;
    }
    return result;
  }
}

// ============================================================
// TRIP READINESS
// ============================================================

/// A 0–100 score showing how ready a trip is, with the reasons it is not
/// higher. Every part is based on something the user has actually recorded.
class TripReadiness {
  final int score;
  final List<String> missing;

  const TripReadiness({required this.score, required this.missing});

  /// [checklistDone] and [checklistTotal] come from the trip's checklist.
  /// [hasItinerary] is true when the trip has saved itinerary text.
  /// [hasBooking] is true when at least one booking exists for the trip's
  /// destination.
  static TripReadiness calculate({
    required int checklistDone,
    required int checklistTotal,
    required bool hasItinerary,
    required bool hasBooking,
  }) {
    final missing = <String>[];

    // Checklist is worth 60 points, itinerary 20, bookings 20.
    var checklistPoints = 0.0;
    if (checklistTotal > 0) {
      checklistPoints = 60 * min(max(checklistDone / checklistTotal, 0.0), 1.0);
      if (checklistDone < checklistTotal) {
        missing.add(
          'Finish your travel checklist '
          '($checklistDone of $checklistTotal done)',
        );
      }
    } else {
      missing.add('Add the travel checklist to this trip');
    }

    final itineraryPoints = hasItinerary ? 20 : 0;
    if (!hasItinerary) missing.add('Save a day-wise itinerary');

    final bookingPoints = hasBooking ? 20 : 0;
    if (!hasBooking) missing.add('Request a stay or travel service');

    final score = (checklistPoints + itineraryPoints + bookingPoints).round();
    return TripReadiness(score: min(max(score, 0), 100), missing: missing);
  }
}

// ============================================================
// SURPRISE ME
// ============================================================

/// Picks a random destination from the catalogue.
class SurprisePicker {
  SurprisePicker._();

  static Destination pick({
    Random? random,
    String? category,
    Destination? avoid,
  }) {
    final pool = DestinationCatalog.all
        .where((d) => d.hasCategory(category))
        .where((d) => avoid == null || d.id != avoid.id)
        .toList();
    final candidates = pool.isEmpty ? DestinationCatalog.all : pool;
    return candidates[(random ?? Random()).nextInt(candidates.length)];
  }
}
