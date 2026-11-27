import 'attractions.dart';
import 'demo_catalogue.dart';
import 'destinations.dart';

/// The kinds of place a traveller may want to find in a city.
enum ServiceCategory {
  hospital('Hospitals and clinics', 'Hospital'),
  police('Police stations', 'Police station'),
  mall('Shopping malls', 'Shopping mall'),
  market('Local markets', 'Local market'),
  cinema('Theatres and cinemas', 'Theatre or cinema'),
  temple('Temples', 'Temple'),
  mosque('Mosques', 'Mosque'),
  church('Churches', 'Church'),
  gurudwara('Gurudwaras', 'Gurudwara'),
  school('Schools', 'School'),
  university('Universities and colleges', 'University or college'),
  museum('Museums', 'Museum'),
  zoo('Zoos', 'Zoo'),
  amusement('Amusement parks', 'Amusement park'),
  gameZone('Game zones and arcades', 'Game zone'),
  attraction('Tourist attractions', 'Tourist attraction'),
  pharmacy('Pharmacies', 'Pharmacy'),
  atm('ATMs', 'ATM'),
  transport('Transport hubs', 'Transport hub');

  final String label;
  final String singular;
  const ServiceCategory(this.label, this.singular);
}

/// Where a record came from. Only [appCatalogue] names are real places taken
/// from the app's own catalogue. Everything else is a labelled demo record.
enum ServiceSource { appCatalogue, demo }

class NearbyService {
  final String id;
  final String name;
  final ServiceCategory category;
  final String destinationId;
  final String city;
  final String state;
  final ServiceSource source;

  const NearbyService({
    required this.id,
    required this.name,
    required this.category,
    required this.destinationId,
    required this.city,
    required this.state,
    required this.source,
  });

  bool get isDemo => source == ServiceSource.demo;

  /// Demo records have no verified address, hours or phone number.
  String get address => isDemo
      ? 'Sample locality $ordinal, $city, $state (illustrative address, not verified)'
      : '$city, $state (general area; full address not recorded in the app)';

  String get hours => isDemo
      ? 'Hours not verified. Check the official listing before you go.'
      : 'Opening hours not recorded in the app. Check before you go.';

  String get contact => 'No verified phone number recorded. Use the official website or the map search.';

  /// A search link on Google Maps. It searches for the category in the city,
  /// so it points at real places rather than at invented coordinates.
  String get mapSearchUrl {
    final query = Uri.encodeQueryComponent('${category.singular} in $city, $state');
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  /// Position in the demo list, used to make the sample address unique.
  int get ordinal => int.tryParse(id.split('-').last) ?? 1;
}

class NearbyServices {
  NearbyServices._();

  static const String notice =
      'Demo services. Names, addresses, hours and contacts are illustrative and '
      'are not verified. Records marked "App catalogue" come from Tripora\'s own '
      'attraction list. For emergencies, use the Emergency help page.';

  static List<NearbyService>? _cache;

  /// Every record, built once. Covers the supported Indian cities.
  static List<NearbyService> get all => _cache ??= _build();

  static List<String> get cityIds => DemoCatalogue.indianDestinationIds;

  static List<NearbyService> _build() {
    final out = <NearbyService>[];
    var n = 0;
    for (final destId in DemoCatalogue.indianDestinationIds) {
      final dest = DestinationCatalog.byId(destId);
      if (dest == null) continue;
      for (final category in ServiceCategory.values) {
        if (category == ServiceCategory.attraction) {
          for (final a in AttractionCatalog.forDestination(destId)) {
            n++;
            out.add(NearbyService(
              id: 'svc-$destId-$n',
              name: a.name,
              category: category,
              destinationId: destId,
              city: dest.name,
              state: dest.region,
              source: ServiceSource.appCatalogue,
            ));
          }
          continue;
        }
        for (var k = 1; k <= 2; k++) {
          n++;
          out.add(NearbyService(
            id: 'svc-$destId-$n',
            name: 'Sample ${category.singular.toLowerCase()} $k, ${dest.name}',
            category: category,
            destinationId: destId,
            city: dest.name,
            state: dest.region,
            source: ServiceSource.demo,
          ));
        }
      }
    }
    return out;
  }

  /// Filters and sorts the records. Empty filters mean "any".
  static List<NearbyService> search({
    String? destinationId,
    ServiceCategory? category,
    String query = '',
    bool appCatalogueOnly = false,
    bool byCategory = false,
  }) {
    final q = query.trim().toLowerCase();
    final result = all.where((s) {
      if (destinationId != null && s.destinationId != destinationId) return false;
      if (category != null && s.category != category) return false;
      if (appCatalogueOnly && s.source != ServiceSource.appCatalogue) return false;
      if (q.isNotEmpty) {
        final text = '${s.name} ${s.category.label} ${s.city} ${s.state}'.toLowerCase();
        if (!text.contains(q)) return false;
      }
      return true;
    }).toList();
    result.sort((a, b) {
      if (byCategory) {
        final c = a.category.index.compareTo(b.category.index);
        if (c != 0) return c;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }
}
