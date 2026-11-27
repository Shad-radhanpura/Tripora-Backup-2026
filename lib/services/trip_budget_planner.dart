import 'dart:math';

/// The three planning levels. The per-unit rates below are indicative planning
/// figures, not prices. Each rate is labelled with what it is multiplied by.
enum BudgetTier { budget, moderate, luxury }

enum TravelMode { bus, train, flight, privateCar, other }

extension BudgetTierInfo on BudgetTier {
  String get label => switch (this) {
    BudgetTier.budget => 'Budget',
    BudgetTier.moderate => 'Moderate',
    BudgetTier.luxury => 'Luxury',
  };

  /// Per room, per night.
  int get roomPerNight => switch (this) {
    BudgetTier.budget => 1500,
    BudgetTier.moderate => 4000,
    BudgetTier.luxury => 12000,
  };

  /// Per adult, per day.
  int get foodPerAdultPerDay => switch (this) {
    BudgetTier.budget => 600,
    BudgetTier.moderate => 1200,
    BudgetTier.luxury => 3000,
  };

  /// Per adult, per day.
  int get localTransportPerAdultPerDay => switch (this) {
    BudgetTier.budget => 300,
    BudgetTier.moderate => 600,
    BudgetTier.luxury => 2000,
  };

  /// Per adult, per day.
  int get activitiesPerAdultPerDay => switch (this) {
    BudgetTier.budget => 400,
    BudgetTier.moderate => 1000,
    BudgetTier.luxury => 3000,
  };
}

extension TravelModeInfo on TravelMode {
  String get label => switch (this) {
    TravelMode.bus => 'Bus',
    TravelMode.train => 'Train',
    TravelMode.flight => 'Flight',
    TravelMode.privateCar => 'Private car',
    TravelMode.other => 'Other',
  };
}

/// What the traveller has entered. Money fields are whole rupees.
class PlanInputs {
  final DateTime startDate;
  final DateTime endDate;
  final int adults;
  final int children;
  final int rooms;
  final BudgetTier tier;
  final TravelMode mode;

  /// Fare the traveller expects to pay, per person, one way. Entered by the
  /// traveller; the app has no live fares.
  final int outboundFarePerPerson;
  final int returnFarePerPerson;

  /// Entry tickets, per traveller, for the whole trip.
  final int entryTicketsPerTraveller;

  /// Shopping and personal spending, per adult, for the whole trip.
  final int shoppingPerAdult;

  /// Travel insurance, per traveller, for the whole trip.
  final int insurancePerTraveller;

  /// Other costs for the group, for the whole trip.
  final int miscellaneousTotal;

  /// Costs already paid before the trip. They are shown, not counted twice.
  final int prepaidTotal;

  const PlanInputs({
    required this.startDate,
    required this.endDate,
    required this.adults,
    this.children = 0,
    this.rooms = 1,
    this.tier = BudgetTier.moderate,
    this.mode = TravelMode.train,
    this.outboundFarePerPerson = 0,
    this.returnFarePerPerson = 0,
    this.entryTicketsPerTraveller = 0,
    this.shoppingPerAdult = 0,
    this.insurancePerTraveller = 0,
    this.miscellaneousTotal = 0,
    this.prepaidTotal = 0,
  });

  int get nights => _day(endDate).difference(_day(startDate)).inDays;
  int get days => nights + 1;
  int get travellers => adults + children;

  /// Children count as half an adult for food, local travel and activities.
  double get adultEquivalent => adults + children * 0.5;

  static const int maxTripNights = 60;
  static const int maxMoney = 10000000;

  /// Returns the first problem with these inputs, or null when they are valid.
  static String? validate({
    required DateTime? start,
    required DateTime? end,
    required int adults,
    required int children,
    required int rooms,
    required Map<String, int> money,
  }) {
    if (start == null || end == null) return 'Choose the start and end dates.';
    final nights = _day(end).difference(_day(start)).inDays;
    if (nights < 0) return 'The end date cannot be before the start date.';
    if (nights > maxTripNights) return 'Plan trips of up to $maxTripNights nights.';
    if (adults < 1 || adults > 9) return 'Enter 1 to 9 adults.';
    if (children < 0 || children > 9) return 'Enter 0 to 9 children.';
    final travellers = adults + children;
    if (travellers > 12) return 'Plans cover up to 12 travellers. Split larger groups.';
    if (rooms < 1 || rooms > travellers) {
      return 'Enter at least 1 room and no more rooms than travellers.';
    }
    for (final entry in money.entries) {
      if (entry.value < 0) return '${entry.key} cannot be negative.';
      if (entry.value > maxMoney) return '${entry.key} is too large to be correct.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'startDate': _day(startDate).toIso8601String(),
    'endDate': _day(endDate).toIso8601String(),
    'adults': adults,
    'children': children,
    'rooms': rooms,
    'tier': tier.name,
    'mode': mode.name,
    'outboundFarePerPerson': outboundFarePerPerson,
    'returnFarePerPerson': returnFarePerPerson,
    'entryTicketsPerTraveller': entryTicketsPerTraveller,
    'shoppingPerAdult': shoppingPerAdult,
    'insurancePerTraveller': insurancePerTraveller,
    'miscellaneousTotal': miscellaneousTotal,
    'prepaidTotal': prepaidTotal,
  };

  factory PlanInputs.fromJson(Map<String, dynamic> json) {
    int whole(String key) {
      final value = json[key];
      if (value is! int || value < 0) throw FormatException('Bad $key');
      return value;
    }

    DateTime date(String key) {
      final value = json[key];
      if (value is! String) throw FormatException('Missing $key');
      final parsed = DateTime.tryParse(value);
      if (parsed == null) throw FormatException('Bad $key');
      return parsed;
    }

    BudgetTier tierFrom(String? name) => BudgetTier.values.firstWhere(
      (t) => t.name == name,
      orElse: () => BudgetTier.moderate,
    );
    TravelMode modeFrom(String? name) => TravelMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => TravelMode.other,
    );

    return PlanInputs(
      startDate: date('startDate'),
      endDate: date('endDate'),
      adults: whole('adults'),
      children: whole('children'),
      rooms: whole('rooms'),
      tier: tierFrom(json['tier'] as String?),
      mode: modeFrom(json['mode'] as String?),
      outboundFarePerPerson: whole('outboundFarePerPerson'),
      returnFarePerPerson: whole('returnFarePerPerson'),
      entryTicketsPerTraveller: whole('entryTicketsPerTraveller'),
      shoppingPerAdult: whole('shoppingPerAdult'),
      insurancePerTraveller: whole('insurancePerTraveller'),
      miscellaneousTotal: whole('miscellaneousTotal'),
      prepaidTotal: whole('prepaidTotal'),
    );
  }

  static DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
}

/// One line of the estimate, with how it was worked out.
class BudgetLine {
  final String category;
  final int amount;
  final String basis;

  const BudgetLine({required this.category, required this.amount, required this.basis});
}

/// The full estimate for one set of inputs and one tier.
class BudgetPlanResult {
  final BudgetTier tier;
  final List<BudgetLine> lines;
  final int subtotal;
  final int contingency;
  final int total;
  final int perPerson;
  final int prepaid;
  final int stillToPay;

  const BudgetPlanResult({
    required this.tier,
    required this.lines,
    required this.subtotal,
    required this.contingency,
    required this.total,
    required this.perPerson,
    required this.prepaid,
    required this.stillToPay,
  });

  int amountFor(String category) =>
      lines.where((l) => l.category == category).fold(0, (sum, l) => sum + l.amount);

  static const String notice =
      'Estimate only, in Indian rupees. Not a quote and not a live price. The app '
      'has no live fares, hotel rates or ticket prices, so fares are the amounts you '
      'enter. Taxes and booking fees are not included. A 10% contingency is added.';

  /// Works the estimate out from [inputs] for [tier]. Accommodation is priced
  /// per room, not per person; food, local travel and activities per adult.
  static BudgetPlanResult calculate(PlanInputs inputs, {BudgetTier? tier}) {
    final t = tier ?? inputs.tier;
    final nights = inputs.nights;
    final days = inputs.days;
    final travellers = inputs.travellers;
    final adultEq = inputs.adultEquivalent;

    final lines = <BudgetLine>[
      BudgetLine(
        category: 'transport',
        amount: (inputs.outboundFarePerPerson + inputs.returnFarePerPerson) * travellers,
        basis: 'Fares you entered × $travellers traveller(s), both ways',
      ),
      BudgetLine(
        category: 'stay',
        amount: t.roomPerNight * nights * inputs.rooms,
        basis: '₹${t.roomPerNight} per room per night × $nights night(s) × ${inputs.rooms} room(s)',
      ),
      BudgetLine(
        category: 'food',
        amount: (t.foodPerAdultPerDay * days * adultEq).round(),
        basis: '₹${t.foodPerAdultPerDay} per adult per day × $days day(s), children half',
      ),
      BudgetLine(
        category: 'local',
        amount: (t.localTransportPerAdultPerDay * days * adultEq).round(),
        basis: '₹${t.localTransportPerAdultPerDay} per adult per day × $days day(s), children half',
      ),
      BudgetLine(
        category: 'activities',
        amount: (t.activitiesPerAdultPerDay * days * adultEq).round(),
        basis: '₹${t.activitiesPerAdultPerDay} per adult per day × $days day(s), children half',
      ),
      BudgetLine(
        category: 'entry',
        amount: inputs.entryTicketsPerTraveller * travellers,
        basis: 'Entry tickets you entered × $travellers traveller(s)',
      ),
      BudgetLine(
        category: 'shopping',
        amount: inputs.shoppingPerAdult * inputs.adults,
        basis: 'Shopping you entered × ${inputs.adults} adult(s)',
      ),
      BudgetLine(
        category: 'insurance',
        amount: inputs.insurancePerTraveller * travellers,
        basis: 'Insurance you entered × $travellers traveller(s)',
      ),
      BudgetLine(
        category: 'misc',
        amount: inputs.miscellaneousTotal,
        basis: 'Group total you entered, counted once',
      ),
    ];

    final subtotal = lines.fold(0, (sum, l) => sum + l.amount);
    final contingency = (subtotal * 0.10).round();
    final total = subtotal + contingency;
    return BudgetPlanResult(
      tier: t,
      lines: lines,
      subtotal: subtotal,
      contingency: contingency,
      total: total,
      perPerson: travellers == 0 ? 0 : (total / travellers).round(),
      prepaid: inputs.prepaidTotal,
      stillToPay: max(total - inputs.prepaidTotal, 0),
    );
  }
}

/// Labels for the planner's spending categories, used by the expense log too.
const Map<String, String> budgetCategoryLabels = {
  'transport': 'Intercity travel',
  'stay': 'Accommodation',
  'food': 'Food',
  'local': 'Local transport',
  'activities': 'Activities and sightseeing',
  'entry': 'Entry tickets',
  'shopping': 'Shopping and personal',
  'insurance': 'Insurance',
  'misc': 'Miscellaneous',
  'other': 'Other',
};

const Map<String, String> paymentMethodLabels = {
  'cash': 'Cash',
  'card': 'Card',
  'upi': 'UPI',
  'wallet': 'Wallet',
  'other': 'Other',
};
