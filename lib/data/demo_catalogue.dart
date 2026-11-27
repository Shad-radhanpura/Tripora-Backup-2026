import '../models/destination.dart';
import '../models/tour_package.dart';
import 'attractions.dart';
import 'destinations.dart';

/// Who a trip suits. Used to recommend packages and to filter the catalogue.
enum TravelGroup {
  family('Family', 'Child-friendly sightseeing, wildlife and easy days.'),
  friends('Friends', 'Adventure, trekking, beaches and group activities.'),
  corporate('Office / corporate', 'Team-friendly resorts, group tours and easy logistics.'),
  couple('Couple', 'Scenic places, quiet stays and romantic experiences.');

  final String label;
  final String description;
  const TravelGroup(this.label, this.description);
}

/// A dated departure with demo inventory. Seats are illustrative only.
class DemoDeparture {
  final DateTime date;
  final int seatsTotal;
  final int seatsBooked;

  const DemoDeparture({required this.date, required this.seatsTotal, required this.seatsBooked});

  int get seatsLeft => (seatsTotal - seatsBooked).clamp(0, seatsTotal);
  bool get soldOut => seatsLeft == 0;
}

/// A demo tour package. Every field is illustrative and not a live offer.
class DemoPackage {
  final String id;
  final String title;
  final String destinationId;
  final String city;
  final String state;
  final int durationDays;
  final int pricePerPerson;
  final String category;
  final Set<TravelGroup> groupTypes;
  final List<String> tags;
  final String hotel;
  final String transport;
  final String season;
  final List<PackageDay> itinerary;
  final List<String> inclusions;
  final List<String> exclusions;
  final String cancellationPolicy;
  final List<DemoDeparture> departures;
  final double demoRating;
  final int demoReviews;
  final String imageUrl;
  final String imageCredit;

  const DemoPackage({
    required this.id,
    required this.title,
    required this.destinationId,
    required this.city,
    required this.state,
    required this.durationDays,
    required this.pricePerPerson,
    required this.category,
    required this.groupTypes,
    required this.tags,
    required this.hotel,
    required this.transport,
    required this.season,
    required this.itinerary,
    required this.inclusions,
    required this.exclusions,
    required this.cancellationPolicy,
    required this.departures,
    required this.demoRating,
    required this.demoReviews,
    required this.imageUrl,
    required this.imageCredit,
  });

  int get nights => durationDays - 1;
  String get durationLabel => '$durationDays days / $nights nights';
  String get pricingBasis => 'Per person on twin sharing. Flights and personal costs are extra.';
  bool get hasSeats => departures.any((d) => !d.soldOut);
  DateTime? get earliestDeparture =>
      departures.isEmpty ? null : departures.map((d) => d.date).reduce((a, b) => a.isBefore(b) ? a : b);

  /// Whether any departure is still bookable on or after [today].
  bool isBookableFrom(DateTime today) =>
      departures.any((d) => !d.soldOut && !_dayOnly(d.date).isBefore(_dayOnly(today)));

  static DateTime _dayOnly(DateTime v) => DateTime(v.year, v.month, v.day);
}

/// Price points the catalogue uses. The first and last are the agreed limits:
/// ₹4,999 to ₹1,49,000 per person.
const List<int> demoPriceLadder = [
  4999, 9999, 14999, 19999, 24999, 29999, 34999, 39999, 44999, 49999,
  54999, 59999, 64999, 69999, 74999, 79999, 84999, 89999, 94999, 99999,
  109999, 119999, 129999, 139999, 149000,
];

/// The first departure date allowed. Nothing earlier than this is generated.
final DateTime demoFirstDeparture = DateTime(2026, 10, 31);

class DemoCatalogue {
  DemoCatalogue._();

  static const String notice =
      'Tripora demo catalogue. Prices, seats, ratings, itineraries and terms are '
      'illustrative and are not live offers. No booking is made from this screen.';

  static List<DemoPackage>? _cache;

  /// Every demo package, built once and kept in memory.
  static List<DemoPackage> get all => _cache ??= _build();

  static DemoPackage? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const List<String> indianDestinationIds = [
    'manali', 'goa', 'jaipur', 'alappuzha', 'ladakh', 'rishikesh', 'udaipur',
    'varanasi', 'andaman', 'agra', 'darjeeling', 'ahmedabad', 'mumbai', 'delhi',
    'kolkata', 'hyderabad', 'bengaluru', 'chennai', 'kochi', 'madurai',
    'pune', 'shimla', 'amritsar', 'jodhpur', 'jaisalmer', 'mysuru', 'ooty',
    'shillong', 'gangtok', 'puducherry',
  ];

  static const List<_Template> _templates = [
    _Template('Weekend Escape', 3, 'Weekend', 1.0, {TravelGroup.friends, TravelGroup.couple}, ['Weekend', 'Short trip']),
    _Template('Classic Highlights', 5, 'Heritage', 1.1, {TravelGroup.family, TravelGroup.corporate}, ['Sightseeing', 'Heritage']),
    _Template('Family Holiday', 6, 'Family', 1.2, {TravelGroup.family}, ['Family', 'Child-friendly']),
    _Template('Adventure Trail', 7, 'Adventure', 1.25, {TravelGroup.friends}, ['Adventure', 'Trekking']),
    _Template('Romantic Retreat', 4, 'Honeymoon', 1.3, {TravelGroup.couple}, ['Couple', 'Scenic']),
    _Template('Group Getaway', 5, 'Group', 1.15, {TravelGroup.corporate, TravelGroup.friends}, ['Group', 'Team trip']),
    _Template('Food and Culture Trail', 4, 'Food', 1.05, {TravelGroup.friends, TravelGroup.couple}, ['Food', 'Local experiences']),
    _Template('Grand Tour', 12, 'Luxury', 1.5, {TravelGroup.family, TravelGroup.couple, TravelGroup.corporate}, ['Luxury', 'Long trip']),
  ];

  static List<DemoPackage> _build() {
    final out = <DemoPackage>[];
    var index = 0;
    for (final destId in indianDestinationIds) {
      final dest = DestinationCatalog.byId(destId);
      if (dest == null) continue;
      final attractions = AttractionCatalog.forDestination(destId).map((a) => a.name).toList();
      final places = attractions.isNotEmpty ? attractions : dest.highlights;
      for (var t = 0; t < _templates.length; t++) {
        final template = _templates[t];
        index++;
        out.add(_make(index, dest, template, places, t));
      }
    }
    return _withExplicitPricePoints(out);
  }

  static DemoPackage _make(int index, Destination dest, _Template tmpl, List<String> places, int t) {
    final days = tmpl.days;
    // Cost per person per day for this template, scaled by how expensive the
    // destination is, then snapped to the nearest price point.
    // A deterministic spread of about ±10% so that packages do not all land on
    // the same price point.
    final spread = 1 + (((index * 37) % 11) - 5) / 50.0;
    final raw = days * _perDay(tmpl) * _costFactor(dest.id) * tmpl.costMultiplier * spread;
    final price = _snap(raw.round());

    final departures = _departures(index);
    final cityName = dest.name;
    final title = '$cityName ${tmpl.name}';
    return DemoPackage(
      id: 'demo-${dest.id}-${tmpl.slug}',
      title: title,
      destinationId: dest.id,
      city: cityName,
      state: dest.region,
      durationDays: days,
      pricePerPerson: price,
      category: tmpl.category,
      groupTypes: tmpl.groups,
      tags: [...tmpl.tags, cityName],
      hotel: _hotelFor(price),
      transport: _transportFor(price),
      season: dest.bestTime,
      itinerary: _itinerary(days, cityName, places, dest.highlights),
      inclusions: const [
        'Accommodation for the nights listed (demo)',
        'Daily breakfast',
        'Sightseeing transport as per itinerary (demo)',
        'Services of a local guide on sightseeing days',
      ],
      exclusions: const [
        'Flights and train fares unless stated',
        'Lunch and dinner unless stated',
        'Entry fees unless stated',
        'Personal expenses, tips and porterage',
      ],
      cancellationPolicy: 'Demo policy: free cancellation up to 15 days before departure; '
          '50% refund from 15 to 7 days; no refund within 7 days. Not a provider contract.',
      departures: departures,
      demoRating: 3.8 + ((index * 7) % 12) / 10,
      demoReviews: 12 + (index * 13) % 180,
      imageUrl: dest.imageUrl,
      imageCredit: dest.imageCredit,
    );
  }

  static int _perDay(_Template tmpl) => switch (tmpl.category) {
    'Luxury' => 6500,
    'Honeymoon' => 5200,
    'Adventure' => 3600,
    'Family' => 4300,
    'Heritage' => 3900,
    'Group' => 3500,
    'Food' => 3300,
    _ => 2600,
  };

  static double _costFactor(String destId) => switch (destId) {
    'ladakh' || 'andaman' => 1.35,
    'mumbai' || 'delhi' => 1.15,
    'manali' || 'darjeeling' || 'rishikesh' => 1.05,
    _ => 1.0,
  };

  static int _snap(int value) {
    var best = demoPriceLadder.first;
    for (final point in demoPriceLadder) {
      if ((point - value).abs() < (best - value).abs()) best = point;
    }
    return best;
  }

  static String _hotelFor(int price) {
    if (price >= 79999) return '5-star hotel (demo)';
    if (price >= 34999) return '4-star hotel (demo)';
    return '3-star hotel (demo)';
  }

  static String _transportFor(int price) {
    if (price >= 79999) return 'Private cab for all transfers and sightseeing (demo)';
    if (price >= 34999) return 'Private cab on sightseeing days, shared transfers (demo)';
    return 'Shared AC coach for sightseeing; transfers as per itinerary (demo)';
  }

  static List<DemoDeparture> _departures(int index) {
    // Four dates a month or so apart, all on or after 31 October 2026.
    final offsets = [0, 9, 24, 41];
    return [
      for (var i = 0; i < offsets.length; i++)
        DemoDeparture(
          date: demoFirstDeparture.add(Duration(days: offsets[i] + (index % 6))),
          seatsTotal: 14 + (index + i) % 11,
          // One departure in every nine packages is shown as sold out.
          seatsBooked: (index + i) % 9 == 0 && i == 0
              ? 14 + (index + i) % 11
              : (index * 3 + i * 5) % (14 + (index + i) % 11),
        ),
    ];
  }

  static List<PackageDay> _itinerary(int days, String city, List<String> places, List<String> highlights) {
    String place(int i) => places.isEmpty ? city : places[i % places.length];
    final list = <PackageDay>[];
    for (var d = 1; d <= days; d++) {
      if (d == 1) {
        list.add(PackageDay('Day 1', 'Arrival in $city', 'Check in, rest, and an evening walk around ${place(0)}.'));
      } else if (d == days) {
        list.add(PackageDay('Day $d', 'Departure', 'Breakfast, check out, and transfer as per your booking.'));
      } else {
        final highlight = highlights.isEmpty ? city : highlights[(d - 2) % highlights.length];
        list.add(PackageDay('Day $d', 'Explore ${place(d - 1)}',
            'Visit ${place(d - 1)} and enjoy $highlight at your own pace.'));
      }
    }
    return list;
  }

  /// Makes sure the agreed limits are present: a ₹4,999 package and a
  /// ₹1,49,000 package. Their names are fixed so they are easy to find.
  static List<DemoPackage> _withExplicitPricePoints(List<DemoPackage> packages) {
    final list = [...packages];
    final cheapest = list.indexWhere((p) => p.id == 'demo-jaipur-weekend-escape');
    if (cheapest >= 0) {
      list[cheapest] = _repriced(list[cheapest], 4999);
    }
    final dearest = list.indexWhere((p) => p.id == 'demo-ladakh-grand-tour');
    if (dearest >= 0) {
      list[dearest] = _repriced(list[dearest], 149000);
    }
    return list;
  }

  static DemoPackage _repriced(DemoPackage p, int price) => DemoPackage(
        id: p.id,
        title: p.title,
        destinationId: p.destinationId,
        city: p.city,
        state: p.state,
        durationDays: p.durationDays,
        pricePerPerson: price,
        category: p.category,
        groupTypes: p.groupTypes,
        tags: p.tags,
        hotel: p.hotel,
        transport: p.transport,
        season: p.season,
        itinerary: p.itinerary,
        inclusions: p.inclusions,
        exclusions: p.exclusions,
        cancellationPolicy: p.cancellationPolicy,
        departures: p.departures,
        demoRating: p.demoRating,
        demoReviews: p.demoReviews,
        imageUrl: p.imageUrl,
        imageCredit: p.imageCredit,
      );
}

class _Template {
  final String name;
  final int days;
  final String category;
  final double costMultiplier;
  final Set<TravelGroup> groups;
  final List<String> tags;

  const _Template(this.name, this.days, this.category, this.costMultiplier, this.groups, this.tags);

  String get slug => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
}
