import 'dart:math';

import '../data/demo_catalogue.dart';

/// How an offer reduces the price.
enum OfferKind { percent, fixed }

/// A demo offer or coupon. Demo offers are examples only: they are not
/// authorised promotions and cannot be redeemed through a payment provider.
class DemoOffer {
  final String code;
  final String title;
  final String description;
  final OfferKind kind;

  /// Percentage (for example 10) or a fixed rupee amount.
  final int value;
  final int minimumAmount;
  final int? maximumDiscount;
  final DateTime validFrom;
  final DateTime validTo;

  /// Empty means every package category is eligible.
  final Set<TravelGroup> eligibleGroups;
  final Set<String> eligibleCategories;

  /// Total redemptions allowed across all users. Null means no limit.
  final int? totalUsageLimit;

  /// Redemptions allowed per person.
  final int perPersonLimit;
  final bool active;

  const DemoOffer({
    required this.code,
    required this.title,
    required this.description,
    required this.kind,
    required this.value,
    this.minimumAmount = 0,
    this.maximumDiscount,
    required this.validFrom,
    required this.validTo,
    this.eligibleGroups = const {},
    this.eligibleCategories = const {},
    this.totalUsageLimit,
    this.perPersonLimit = 1,
    this.active = true,
  });

  String get valueLabel => kind == OfferKind.percent ? '$value% off' : '₹$value off';
}

enum CouponProblem {
  notFound,
  inactive,
  notStarted,
  expired,
  belowMinimum,
  ineligible,
  alreadyUsed,
  usageLimitReached,
}

/// The result of checking a coupon against a booking.
class CouponCheck {
  final DemoOffer? offer;
  final CouponProblem? problem;
  final int discount;

  const CouponCheck._(this.offer, this.problem, this.discount);

  bool get valid => problem == null;

  factory CouponCheck.ok(DemoOffer offer, int discount) => CouponCheck._(offer, null, discount);
  factory CouponCheck.fail(CouponProblem problem, [DemoOffer? offer]) => CouponCheck._(offer, problem, 0);

  /// A short message that explains the outcome to the user.
  String get message {
    final o = offer;
    return switch (problem) {
      null => '${o!.code} applied: you save ₹$discount.',
      CouponProblem.notFound => 'That code is not recognised. Check it and try again.',
      CouponProblem.inactive => 'This code is not active at the moment.',
      CouponProblem.notStarted => 'This code is not valid yet. It starts ${_date(o!.validFrom)}.',
      CouponProblem.expired => 'This code expired on ${_date(o!.validTo)}.',
      CouponProblem.belowMinimum => 'This code needs a booking of at least ₹${o!.minimumAmount}.',
      CouponProblem.ineligible => 'This code does not apply to this package or traveller group.',
      CouponProblem.alreadyUsed => 'You have already used this code the maximum number of times.',
      CouponProblem.usageLimitReached => 'This code has reached its usage limit.',
    };
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

/// A full price breakdown for a package booking.
class PriceBreakdown {
  final int pricePerPerson;
  final int travellers;
  final int subtotal;
  final int couponDiscount;
  final int giftCardApplied;
  final int total;

  const PriceBreakdown({
    required this.pricePerPerson,
    required this.travellers,
    required this.subtotal,
    required this.couponDiscount,
    required this.giftCardApplied,
    required this.total,
  });

  int get totalSavings => couponDiscount + giftCardApplied;

  /// Calculates the breakdown. Discounts never exceed the subtotal, so the
  /// total cannot go negative.
  static PriceBreakdown calculate({
    required int pricePerPerson,
    required int travellers,
    int couponDiscount = 0,
    int giftCardBalance = 0,
  }) {
    final safeTravellers = max(travellers, 1);
    final subtotal = pricePerPerson * safeTravellers;
    final coupon = min(max(couponDiscount, 0), subtotal);
    final afterCoupon = subtotal - coupon;
    final giftCard = min(max(giftCardBalance, 0), afterCoupon);
    return PriceBreakdown(
      pricePerPerson: pricePerPerson,
      travellers: safeTravellers,
      subtotal: subtotal,
      couponDiscount: coupon,
      giftCardApplied: giftCard,
      total: afterCoupon - giftCard,
    );
  }
}

/// Checks coupons. Pure logic: the caller supplies how many times each code has
/// already been used, so the rules can be tested without storage.
class CouponValidator {
  CouponValidator._();

  static DemoOffer? find(String code, {Iterable<DemoOffer>? offers}) {
    final wanted = code.trim().toUpperCase();
    if (wanted.isEmpty) return null;
    for (final o in offers ?? DemoOffers.all) {
      if (o.code == wanted) return o;
    }
    return null;
  }

  static CouponCheck check({
    required String code,
    required DemoPackage package,
    required TravelGroup? group,
    required int travellers,
    required DateTime today,
    required int usesByPerson,
    required int totalUses,
    Iterable<DemoOffer>? offers,
  }) {
    final offer = find(code, offers: offers);
    if (offer == null) return CouponCheck.fail(CouponProblem.notFound);
    if (!offer.active) return CouponCheck.fail(CouponProblem.inactive, offer);
    final day = DateTime(today.year, today.month, today.day);
    if (day.isBefore(DateTime(offer.validFrom.year, offer.validFrom.month, offer.validFrom.day))) {
      return CouponCheck.fail(CouponProblem.notStarted, offer);
    }
    if (day.isAfter(DateTime(offer.validTo.year, offer.validTo.month, offer.validTo.day))) {
      return CouponCheck.fail(CouponProblem.expired, offer);
    }
    final int subtotal = package.pricePerPerson * max<int>(travellers, 1);
    if (subtotal < offer.minimumAmount) return CouponCheck.fail(CouponProblem.belowMinimum, offer);

    final groupOk = offer.eligibleGroups.isEmpty || (group != null && offer.eligibleGroups.contains(group));
    final categoryOk = offer.eligibleCategories.isEmpty || offer.eligibleCategories.contains(package.category);
    if (!groupOk || !categoryOk) return CouponCheck.fail(CouponProblem.ineligible, offer);

    if (usesByPerson >= offer.perPersonLimit) return CouponCheck.fail(CouponProblem.alreadyUsed, offer);
    if (offer.totalUsageLimit != null && totalUses >= offer.totalUsageLimit!) {
      return CouponCheck.fail(CouponProblem.usageLimitReached, offer);
    }

    int discount = offer.kind == OfferKind.percent
        ? (subtotal * offer.value / 100).floor()
        : offer.value;
    if (offer.maximumDiscount != null) discount = min<int>(discount, offer.maximumDiscount!);
    discount = min<int>(discount, subtotal);
    return CouponCheck.ok(offer, discount);
  }
}

/// The demo offers shown in the app.
class DemoOffers {
  DemoOffers._();

  static final List<DemoOffer> all = [
    DemoOffer(
      code: 'DEMO10',
      title: 'Ten percent off any package (demo)',
      description: 'A demo percentage offer for packages of ₹5,000 or more.',
      kind: OfferKind.percent,
      value: 10,
      minimumAmount: 5000,
      maximumDiscount: 2000,
      validFrom: DateTime(2026, 10, 1),
      validTo: DateTime(2027, 3, 31),
      totalUsageLimit: 500,
    ),
    DemoOffer(
      code: 'WEEKEND500',
      title: 'Rs 500 off weekend escapes (demo)',
      description: 'A demo fixed-amount offer for the Weekend Escape packages.',
      kind: OfferKind.fixed,
      value: 500,
      minimumAmount: 3000,
      validFrom: DateTime(2026, 10, 1),
      validTo: DateTime(2027, 2, 28),
      eligibleCategories: {'Weekend'},
    ),
    DemoOffer(
      code: 'FAMILY15',
      title: 'Fifteen percent off family holidays (demo)',
      description: 'A demo percentage offer for family packages, capped at ₹4,000.',
      kind: OfferKind.percent,
      value: 15,
      minimumAmount: 15000,
      maximumDiscount: 4000,
      validFrom: DateTime(2026, 10, 1),
      validTo: DateTime(2027, 4, 30),
      eligibleGroups: {TravelGroup.family},
    ),
    DemoOffer(
      code: 'COUPLE1000',
      title: 'Rs 1,000 off romantic retreats (demo)',
      description: 'A demo fixed-amount offer for couples.',
      kind: OfferKind.fixed,
      value: 1000,
      minimumAmount: 10000,
      validFrom: DateTime(2026, 10, 1),
      validTo: DateTime(2027, 1, 31),
      eligibleGroups: {TravelGroup.couple},
    ),
    DemoOffer(
      code: 'SUMMER50',
      title: 'Fifty percent off (demo, expired)',
      description: 'A demo offer that has already expired. It is shown so the expired state can be seen.',
      kind: OfferKind.percent,
      value: 50,
      validFrom: DateTime(2026, 4, 1),
      validTo: DateTime(2026, 9, 30),
    ),
    DemoOffer(
      code: 'LIMITED5',
      title: 'First five bookings (demo)',
      description: 'A demo offer with a total usage limit of five, to show the limit state.',
      kind: OfferKind.fixed,
      value: 750,
      validFrom: DateTime(2026, 10, 1),
      validTo: DateTime(2027, 6, 30),
      totalUsageLimit: 5,
    ),
  ];
}
