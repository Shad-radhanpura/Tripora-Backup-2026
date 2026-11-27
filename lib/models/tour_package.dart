/// One stop (or group of days) in a tour package's day-by-day plan.
class PackageDay {
  /// Label shown to the user, e.g. "Day 1" or "Days 2–4".
  final String days;
  final String title;
  final String details;

  const PackageDay(this.days, this.title, this.details);

  Map<String, dynamic> toMap() =>
      {'days': days, 'title': title, 'details': details};

  factory PackageDay.fromMap(Map<String, dynamic> data) => PackageDay(
        data['days']?.toString() ?? '',
        data['title']?.toString() ?? '',
        data['details']?.toString() ?? '',
      );
}

/// A ready-made tour package (10, 15, 20 or 30 days).
///
/// The built-in catalogue lives in `lib/data/tour_packages.dart`. Admins can
/// add new packages, or override / hide a built-in one, through the
/// `packages` Firestore collection (document ID = package ID).
class TourPackage {
  final String id;
  final String title;
  final int durationDays;
  final List<String> cities;
  final String region;
  final String category;
  final int pricePerPerson;
  final String hotelClass;
  final List<String> facilities;
  final List<String> highlights;
  final List<PackageDay> itinerary;
  final String description;
  final String imageUrl;
  final bool active;

  /// True for catalogue packages bundled with the app.
  final bool builtIn;

  const TourPackage({
    required this.id,
    required this.title,
    required this.durationDays,
    required this.cities,
    required this.region,
    required this.category,
    required this.pricePerPerson,
    required this.hotelClass,
    required this.facilities,
    required this.highlights,
    required this.itinerary,
    required this.description,
    required this.imageUrl,
    this.active = true,
    this.builtIn = false,
  });

  int get nights => durationDays > 0 ? durationDays - 1 : 0;

  String get durationLabel => '$durationDays days / $nights nights';

  String get route => cities.join(' • ');

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [title, region, category, description, ...cities, ...highlights]
        .any((value) => value.toLowerCase().contains(q));
  }

  TourPackage copyWith({bool? active, bool? builtIn}) => TourPackage(
        id: id,
        title: title,
        durationDays: durationDays,
        cities: cities,
        region: region,
        category: category,
        pricePerPerson: pricePerPerson,
        hotelClass: hotelClass,
        facilities: facilities,
        highlights: highlights,
        itinerary: itinerary,
        description: description,
        imageUrl: imageUrl,
        active: active ?? this.active,
        builtIn: builtIn ?? this.builtIn,
      );

  /// Fields stored in `packages/{id}`. Exactly these keys are allowed by the
  /// security rules.
  Map<String, dynamic> toMap() => {
        'title': title,
        'durationDays': durationDays,
        'cities': cities,
        'region': region,
        'category': category,
        'pricePerPerson': pricePerPerson,
        'hotelClass': hotelClass,
        'facilities': facilities,
        'highlights': highlights,
        'itinerary': itinerary.map((day) => day.toMap()).toList(),
        'description': description,
        'imageUrl': imageUrl,
        'active': active,
      };

  factory TourPackage.fromMap(
    String id,
    Map<String, dynamic> data, {
    bool builtIn = false,
  }) {
    List<String> strings(Object? value) => value is List
        ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const [];

    int number(Object? value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    final rawDays = data['itinerary'];

    return TourPackage(
      id: id,
      title: data['title']?.toString() ?? 'Untitled package',
      durationDays: number(data['durationDays']),
      cities: strings(data['cities']),
      region: data['region']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Mixed',
      pricePerPerson: number(data['pricePerPerson']),
      hotelClass: data['hotelClass']?.toString() ?? '3-star',
      facilities: strings(data['facilities']),
      highlights: strings(data['highlights']),
      itinerary: rawDays is List
          ? rawDays
              .whereType<Map>()
              .map((m) => PackageDay.fromMap(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      active: data['active'] != false,
      builtIn: builtIn,
    );
  }
}

/// Formats a rupee amount with Indian digit grouping, e.g. ₹1,25,000.
String formatInr(num amount) {
  final digits = amount.round().abs().toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${amount < 0 ? '-' : ''}₹$grouped';
}
