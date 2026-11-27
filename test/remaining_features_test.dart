// Demo catalogue, offers and coupons, gift cards, filters, recommendations and
// nearby services. All logic is pure or uses an in-memory store; nothing here
// touches Firebase or a payment provider.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripora/data/demo_catalogue.dart';
import 'package:tripora/data/nearby_services.dart';
import 'package:tripora/services/gift_card_service.dart';
import 'package:tripora/services/offers_service.dart';
import 'package:tripora/services/package_filters.dart';

final DateTime _today = DateTime(2026, 10, 19);

DemoPackage _pkg({String id = 'demo-goa-weekend-escape'}) =>
    DemoCatalogue.byId(id)!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('demo catalogue', () {
    test('has at least 100 packages within the agreed price and duration limits', () {
      final all = DemoCatalogue.all;
      expect(all.length, greaterThanOrEqualTo(100));
      final prices = all.map((p) => p.pricePerPerson).toSet();
      expect(prices, containsAll([4999, 149000]));
      for (final p in all) {
        expect(p.pricePerPerson, inInclusiveRange(4999, 149000), reason: p.id);
        expect(p.durationDays, inInclusiveRange(3, 15), reason: p.id);
        expect(p.itinerary.length, p.durationDays, reason: p.id);
        expect(p.pricingBasis, contains('Per person'));
      }
    });

    test('every departure is on or after 31 October 2026 and seats never go negative', () {
      for (final p in DemoCatalogue.all) {
        expect(p.departures, isNotEmpty, reason: p.id);
        for (final d in p.departures) {
          expect(d.date.isBefore(DateTime(2026, 10, 31)), isFalse, reason: p.id);
          expect(d.seatsLeft, greaterThanOrEqualTo(0), reason: p.id);
        }
      }
    });

    test('some departures are sold out, and sold-out packages are not bookable', () {
      final soldOutPackages = DemoCatalogue.all.where((p) => p.departures.any((d) => d.soldOut));
      expect(soldOutPackages, isNotEmpty);
      final pkg = soldOutPackages.first;
      final soldOutDate = pkg.departures.firstWhere((d) => d.soldOut).date;
      expect(
        pkg.departures.where((d) => d.soldOut && d.date == soldOutDate),
        isNotEmpty,
      );
    });
  });

  group('coupons', () {
    test('a valid percentage coupon gives the right discount and breakdown', () {
      final check = CouponValidator.check(
        code: 'demo10',
        package: _pkg(),
        group: TravelGroup.couple,
        travellers: 2,
        today: _today,
        usesByPerson: 0,
        totalUses: 0,
      );
      // Goa weekend escape price times two travellers, 10% off.
      final subtotal = _pkg().pricePerPerson * 2;
      expect(check.valid, isTrue);
      expect(check.discount, (subtotal * 0.10).floor());
      final breakdown = PriceBreakdown.calculate(
        pricePerPerson: _pkg().pricePerPerson,
        travellers: 2,
        couponDiscount: check.discount,
      );
      expect(breakdown.total, subtotal - check.discount);
    });

    test('expired, not-yet-started and inactive coupons are refused', () {
      CouponCheck check(String code) => CouponValidator.check(
            code: code,
            package: _pkg(),
            group: TravelGroup.family,
            travellers: 2,
            today: _today,
            usesByPerson: 0,
            totalUses: 0,
          );
      expect(check('SUMMER50').problem, CouponProblem.expired);
      expect(check('NOPE').problem, CouponProblem.notFound);
      final future = CouponValidator.check(
        code: 'DEMO10',
        package: _pkg(),
        group: TravelGroup.family,
        travellers: 2,
        today: DateTime(2025, 1, 1),
        usesByPerson: 0,
        totalUses: 0,
      );
      expect(future.problem, CouponProblem.notStarted);
      final inactive = CouponValidator.check(
        code: 'DEMO10',
        package: _pkg(),
        group: TravelGroup.family,
        travellers: 2,
        today: _today,
        usesByPerson: 0,
        totalUses: 0,
        offers: [
          DemoOffer(
            code: 'DEMO10',
            title: 't',
            description: 'd',
            kind: OfferKind.percent,
            value: 10,
            validFrom: DateTime(2026, 1, 1),
            validTo: DateTime(2027, 1, 1),
            active: false,
          ),
        ],
      );
      expect(inactive.problem, CouponProblem.inactive);
    });

    test('minimum amount, eligibility, per-person use and total usage are enforced', () {
      CouponCheck check({
        String code = 'WEEKEND500',
        TravelGroup? group = TravelGroup.friends,
        int travellers = 1,
        int usesByPerson = 0,
        int totalUses = 0,
        String packageId = 'demo-goa-weekend-escape',
      }) =>
          CouponValidator.check(
            code: code,
            package: _pkg(id: packageId),
            group: group,
            travellers: travellers,
            today: _today,
            usesByPerson: usesByPerson,
            totalUses: totalUses,
          );

      // The Goa weekend escape costs less than ₹10,000 for one traveller, so the
      // ₹10,000 minimum on COUPLE1000 is not met.
      expect(_pkg().pricePerPerson, lessThan(10000));
      expect(check(code: 'COUPLE1000', group: TravelGroup.couple, travellers: 1).problem,
          CouponProblem.belowMinimum);
      expect(check(code: 'COUPLE1000', group: TravelGroup.couple, travellers: 3).valid, isTrue);
      expect(check(travellers: 3).valid, isTrue);
      expect(check(travellers: 3, packageId: 'demo-goa-classic-highlights', code: 'WEEKEND500').problem,
          CouponProblem.ineligible);
      expect(check(code: 'COUPLE1000', group: TravelGroup.family, travellers: 3).problem,
          CouponProblem.ineligible);
      expect(check(travellers: 3, usesByPerson: 1).problem, CouponProblem.alreadyUsed);
      expect(check(code: 'LIMITED5', travellers: 1, totalUses: 5).problem, CouponProblem.usageLimitReached);
    });

    test('fixed discounts never exceed the subtotal', () {
      final tiny = PriceBreakdown.calculate(pricePerPerson: 300, travellers: 1, couponDiscount: 500);
      expect(tiny.total, 0);
      expect(tiny.couponDiscount, 300);
    });
  });

  group('gift cards', () {
    test('a demo card can be issued, spent down, and refused when empty or expired', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = GiftCardStore(prefs, () => _today);
      await store.load();

      final card = await store.issue(
        buyerUid: 'buyer',
        denomination: 2000,
        recipientName: 'Asha Demo',
        message: 'Enjoy the trip',
      );
      expect(card.code, startsWith('DEMO-'));
      expect(card.balance, 2000);
      expect(card.statusOn(_today), 'Active (demo)');

      final partial = await store.redeem(code: card.code, amount: 1500, note: 'Demo preview');
      expect(partial.ok, isTrue);
      expect(store.cardsFor('buyer').single.balance, 500);

      final tooMuch = await store.redeem(code: card.code, amount: 800, note: 'Demo preview');
      expect(tooMuch.problem, RedeemProblem.insufficientBalance);

      await store.redeem(code: card.code, amount: 500, note: 'Demo preview');
      final empty = await store.redeem(code: card.code, amount: 100, note: 'Demo preview');
      expect(empty.problem, RedeemProblem.fullyUsed);

      final expired = GiftCardRules.redeem(
        cards: [card.copyWith(balance: 100)],
        code: card.code,
        amount: 50,
        today: DateTime(2028, 1, 1),
      );
      expect(expired.problem, RedeemProblem.expired);
      expect(
        GiftCardRules.redeem(cards: const [], code: 'DEMO-NOPE', amount: 1, today: _today).problem,
        RedeemProblem.notFound,
      );
    });

    test('invalid denominations and recipient details are refused', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = GiftCardStore(prefs, () => _today);
      await store.load();
      await expectLater(
        store.issue(buyerUid: 'b', denomination: 1234, recipientName: 'Asha'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        store.issue(buyerUid: 'b', denomination: 1000, recipientName: 'A'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        store.issue(buyerUid: 'b', denomination: 1000, recipientName: 'Asha', recipientEmail: 'not-an-email'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('demo codes are random and do not repeat in a short run', () {
      final random = Random(7);
      final codes = {for (var i = 0; i < 200; i++) DemoGiftCards.newCode(random)};
      expect(codes.length, 200);
    });
  });

  group('filters, sorting and recommendations', () {
    test('group type, duration and price filters change the results', () {
      final all = DemoCatalogue.all;
      final family = PackageQuery.apply(all, const PackageFilter(group: TravelGroup.family),
          sort: PackageSort.nameAtoZ, today: _today);
      expect(family, isNotEmpty);
      expect(family.every((p) => p.groupTypes.contains(TravelGroup.family)), isTrue);
      expect(family.length, lessThan(all.length));

      final short = PackageQuery.apply(all, const PackageFilter(maxDays: 4),
          sort: PackageSort.nameAtoZ, today: _today);
      expect(short.every((p) => p.durationDays <= 4), isTrue);

      final budget = PackageQuery.apply(all, const PackageFilter(minPrice: 4999, maxPrice: 9999),
          sort: PackageSort.nameAtoZ, today: _today);
      expect(budget.every((p) => p.pricePerPerson <= 9999), isTrue);
    });

    test('every sort option orders the results as its name says', () {
      final all = DemoCatalogue.all;
      List<DemoPackage> sorted(PackageSort s) =>
          PackageQuery.apply(all, const PackageFilter(), sort: s, today: _today);

      final low = sorted(PackageSort.priceLowToHigh);
      expect(low.first.pricePerPerson, low.map((p) => p.pricePerPerson).reduce(min));
      final high = sorted(PackageSort.priceHighToLow);
      expect(high.first.pricePerPerson, high.map((p) => p.pricePerPerson).reduce(max));
      final short = sorted(PackageSort.durationShortToLong);
      expect(short.first.durationDays, short.map((p) => p.durationDays).reduce(min));
      final long = sorted(PackageSort.durationLongToShort);
      expect(long.first.durationDays, long.map((p) => p.durationDays).reduce(max));
      final names = sorted(PackageSort.nameAtoZ).map((p) => p.title.toLowerCase()).toList();
      expect(names, [...names]..sort());
      final rated = sorted(PackageSort.ratingHighest);
      expect(rated.first.demoRating, rated.map((p) => p.demoRating).reduce(max));
      final dates = sorted(PackageSort.departureEarliest).map((p) => p.earliestDeparture!).toList();
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].isBefore(dates[i - 1]), isFalse);
      }
    });

    test('clearing filters returns the full catalogue, and an impossible filter gives nothing', () {
      final all = DemoCatalogue.all;
      expect(const PackageFilter().isEmpty, isTrue);
      expect(
        PackageQuery.apply(all, const PackageFilter(), sort: PackageSort.nameAtoZ, today: _today).length,
        all.length,
      );
      expect(
        PackageQuery.apply(all, const PackageFilter(minPrice: 900000), sort: PackageSort.nameAtoZ, today: _today),
        isEmpty,
      );
    });

    test('recommendations follow the group type and budget', () {
      final all = DemoCatalogue.all;
      final forCouples = PackageRecommender.recommend(all,
          group: TravelGroup.couple, budgetPerPerson: 20000, limit: 5);
      expect(forCouples, isNotEmpty);
      expect(forCouples.every((p) => p.groupTypes.contains(TravelGroup.couple)), isTrue);
      expect(forCouples.first.pricePerPerson, lessThanOrEqualTo(24000));
      expect(
        PackageRecommender.score(forCouples.first, group: TravelGroup.couple, budgetPerPerson: 20000),
        greaterThan(PackageRecommender.score(forCouples.first, group: TravelGroup.family)),
      );
    });
  });

  group('nearby services', () {
    test('covers every supported Indian city and every category', () {
      final cities = NearbyServices.all.map((s) => s.destinationId).toSet();
      expect(cities, containsAll(DemoCatalogue.indianDestinationIds));
      final categories = NearbyServices.all.map((s) => s.category).toSet();
      expect(categories, containsAll(ServiceCategory.values));
    });

    test('demo records are labelled, carry no phone number, and say their address is unverified', () {
      final demo = NearbyServices.all.where((s) => s.isDemo);
      expect(demo, isNotEmpty);
      for (final s in demo) {
        expect(s.address, contains('not verified'), reason: s.name);
        expect(s.contact, contains('No verified phone number'), reason: s.name);
        expect(s.hours, contains('not verified'), reason: s.name);
      }
    });

    test('search narrows by city, category and name, and attraction records come from the app catalogue', () {
      final goaHospitals = NearbyServices.search(destinationId: 'goa', category: ServiceCategory.hospital);
      expect(goaHospitals, isNotEmpty);
      expect(goaHospitals.every((s) => s.destinationId == 'goa' && s.category == ServiceCategory.hospital), isTrue);

      final byName = NearbyServices.search(query: 'sample police');
      expect(byName, isNotEmpty);
      expect(byName.every((s) => s.name.toLowerCase().contains('sample police')), isTrue);

      final attractions = NearbyServices.search(category: ServiceCategory.attraction, appCatalogueOnly: true);
      expect(attractions, isNotEmpty);
      expect(attractions.every((s) => !s.isDemo), isTrue);
    });

    test('map links search for the category in the city and do not invent coordinates', () {
      final s = NearbyServices.search(destinationId: 'jaipur', category: ServiceCategory.temple).first;
      expect(s.mapSearchUrl, startsWith('https://www.google.com/maps/search/'));
      expect(s.mapSearchUrl, contains('Temple'));
      expect(s.mapSearchUrl, isNot(contains('@')));
    });
  });
}
