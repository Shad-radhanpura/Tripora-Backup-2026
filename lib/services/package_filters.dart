import '../data/demo_catalogue.dart';

/// Ways to order the catalogue. Ratings are demo ratings.
enum PackageSort {
  priceLowToHigh('Price: low to high'),
  priceHighToLow('Price: high to low'),
  durationShortToLong('Duration: shortest first'),
  durationLongToShort('Duration: longest first'),
  nameAtoZ('Name: A to Z'),
  departureEarliest('Departure: earliest first'),
  ratingHighest('Demo rating: highest first');

  final String label;
  const PackageSort(this.label);
}

/// The filters the catalogue screen can set. Null or empty means "any".
class PackageFilter {
  final TravelGroup? group;
  final String? destinationId;
  final String? state;
  final int? minPrice;
  final int? maxPrice;
  final int? minDays;
  final int? maxDays;
  final String? category;
  final DateTime? departureFrom;
  final DateTime? departureTo;
  final bool availableOnly;
  final double? minRating;
  final String query;

  const PackageFilter({
    this.group,
    this.destinationId,
    this.state,
    this.minPrice,
    this.maxPrice,
    this.minDays,
    this.maxDays,
    this.category,
    this.departureFrom,
    this.departureTo,
    this.availableOnly = false,
    this.minRating,
    this.query = '',
  });

  /// True when no filter is set. Used for the "Clear filters" state.
  bool get isEmpty =>
      group == null &&
      destinationId == null &&
      state == null &&
      minPrice == null &&
      maxPrice == null &&
      minDays == null &&
      maxDays == null &&
      category == null &&
      departureFrom == null &&
      departureTo == null &&
      !availableOnly &&
      minRating == null &&
      query.trim().isEmpty;

  /// Clears the filters but keeps the group the traveller chose.
  PackageFilter clearedKeepingGroup() => PackageFilter(group: group);

  PackageFilter copyWith({
    TravelGroup? group,
    bool clearGroup = false,
    String? destinationId,
    bool clearDestination = false,
    String? state,
    bool clearState = false,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    int? minDays,
    int? maxDays,
    bool clearDays = false,
    String? category,
    bool clearCategory = false,
    DateTime? departureFrom,
    DateTime? departureTo,
    bool clearDates = false,
    bool? availableOnly,
    double? minRating,
    bool clearRating = false,
    String? query,
  }) {
    return PackageFilter(
      group: clearGroup ? null : (group ?? this.group),
      destinationId: clearDestination ? null : (destinationId ?? this.destinationId),
      state: clearState ? null : (state ?? this.state),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      minDays: clearDays ? null : (minDays ?? this.minDays),
      maxDays: clearDays ? null : (maxDays ?? this.maxDays),
      category: clearCategory ? null : (category ?? this.category),
      departureFrom: clearDates ? null : (departureFrom ?? this.departureFrom),
      departureTo: clearDates ? null : (departureTo ?? this.departureTo),
      availableOnly: availableOnly ?? this.availableOnly,
      minRating: clearRating ? null : (minRating ?? this.minRating),
      query: query ?? this.query,
    );
  }
}

/// Applies filters and sorting to the demo catalogue. Pure logic, so it is
/// easy to test and runs the same way everywhere.
class PackageQuery {
  PackageQuery._();

  static List<DemoPackage> apply(
    List<DemoPackage> packages,
    PackageFilter filter, {
    required PackageSort sort,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final q = filter.query.trim().toLowerCase();
    final result = packages.where((p) {
      if (filter.group != null && !p.groupTypes.contains(filter.group)) return false;
      if (filter.destinationId != null && p.destinationId != filter.destinationId) return false;
      if (filter.state != null && p.state != filter.state) return false;
      if (filter.minPrice != null && p.pricePerPerson < filter.minPrice!) return false;
      if (filter.maxPrice != null && p.pricePerPerson > filter.maxPrice!) return false;
      if (filter.minDays != null && p.durationDays < filter.minDays!) return false;
      if (filter.maxDays != null && p.durationDays > filter.maxDays!) return false;
      if (filter.category != null && p.category != filter.category) return false;
      if (filter.minRating != null && p.demoRating < filter.minRating!) return false;
      if (filter.availableOnly && !p.isBookableFrom(day)) return false;
      if (filter.departureFrom != null || filter.departureTo != null) {
        final inRange = p.departures.any((d) {
          final date = DateTime(d.date.year, d.date.month, d.date.day);
          if (filter.departureFrom != null && date.isBefore(_dayOnly(filter.departureFrom!))) return false;
          if (filter.departureTo != null && date.isAfter(_dayOnly(filter.departureTo!))) return false;
          return !d.soldOut;
        });
        if (!inRange) return false;
      }
      if (q.isNotEmpty) {
        final haystack = [p.title, p.city, p.state, p.category, ...p.tags].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    result.sort(_comparator(sort));
    return result;
  }

  static DateTime _dayOnly(DateTime v) => DateTime(v.year, v.month, v.day);

  static int Function(DemoPackage, DemoPackage) _comparator(PackageSort sort) => switch (sort) {
        PackageSort.priceLowToHigh => (a, b) => _then(a.pricePerPerson.compareTo(b.pricePerPerson), a, b),
        PackageSort.priceHighToLow => (a, b) => _then(b.pricePerPerson.compareTo(a.pricePerPerson), a, b),
        PackageSort.durationShortToLong => (a, b) => _then(a.durationDays.compareTo(b.durationDays), a, b),
        PackageSort.durationLongToShort => (a, b) => _then(b.durationDays.compareTo(a.durationDays), a, b),
        PackageSort.nameAtoZ => (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        PackageSort.departureEarliest => (a, b) {
            final left = a.earliestDeparture;
            final right = b.earliestDeparture;
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;
            return left.compareTo(right);
          },
        PackageSort.ratingHighest => (a, b) => _then(b.demoRating.compareTo(a.demoRating), a, b),
      };

  /// Keeps the comparison stable: ties fall back to name, so the order never
  /// changes between rebuilds.
  static int _then(int primary, DemoPackage a, DemoPackage b) =>
      primary != 0 ? primary : a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

/// Scores how well a package suits a traveller. Used to order "Recommended"
/// results and to explain why a package was suggested.
class PackageRecommender {
  PackageRecommender._();

  /// Categories each group type tends to enjoy. A starting point, not a rule:
  /// any package can still be chosen and filtered.
  static const Map<TravelGroup, Set<String>> preferredCategories = {
    TravelGroup.family: {'Family', 'Heritage', 'Nature', 'Wildlife', 'Sightseeing'},
    TravelGroup.friends: {'Adventure', 'Weekend', 'Food', 'Group', 'Beach'},
    TravelGroup.corporate: {'Group', 'Luxury', 'Heritage', 'Sightseeing'},
    TravelGroup.couple: {'Honeymoon', 'Weekend', 'Beach', 'Luxury', 'Nature'},
  };

  /// A score from 0 upward. Higher is a better fit.
  static int score(
    DemoPackage p, {
    TravelGroup? group,
    Set<String> interests = const {},
    int? budgetPerPerson,
    int? preferredDays,
    String? preferredDestinationId,
  }) {
    var s = 0;
    final reasons = <String>[];
    if (group != null) {
      if (p.groupTypes.contains(group)) {
        s += 40;
        reasons.add('suits ${group.label.toLowerCase()} travellers');
      }
      if (preferredCategories[group]?.contains(p.category) ?? false) {
        s += 15;
      }
    }
    final wanted = interests.map((i) => i.toLowerCase()).toSet();
    if (wanted.isNotEmpty) {
      final matches = [p.category, ...p.tags].where((t) => wanted.contains(t.toLowerCase())).length;
      s += (matches * 12).clamp(0, 36);
      if (matches > 0) reasons.add('matches your interests');
    }
    if (budgetPerPerson != null) {
      if (p.pricePerPerson <= budgetPerPerson) {
        s += 20;
        reasons.add('within your budget');
      } else if (p.pricePerPerson <= budgetPerPerson * 1.2) {
        s += 5;
      }
    }
    if (preferredDays != null) {
      final diff = (p.durationDays - preferredDays).abs();
      if (diff == 0) {
        s += 15;
      } else if (diff <= 2) {
        s += 7;
      }
    }
    if (preferredDestinationId != null && p.destinationId == preferredDestinationId) {
      s += 10;
    }
    return s;
  }

  /// The top [limit] packages for the traveller, best first.
  static List<DemoPackage> recommend(
    List<DemoPackage> packages, {
    TravelGroup? group,
    Set<String> interests = const {},
    int? budgetPerPerson,
    int? preferredDays,
    String? preferredDestinationId,
    int limit = 6,
  }) {
    final scored = [
      for (final p in packages)
        (p, score(p,
            group: group,
            interests: interests,
            budgetPerPerson: budgetPerPerson,
            preferredDays: preferredDays,
            preferredDestinationId: preferredDestinationId)),
    ]..sort((a, b) {
        final byScore = b.$2.compareTo(a.$2);
        return byScore != 0 ? byScore : a.$1.title.compareTo(b.$1.title);
      });
    return [for (final entry in scored.take(limit)) if (entry.$2 > 0) entry.$1];
  }
}
