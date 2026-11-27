/// A travel destination shown in Destination Discovery.
///
/// Destinations are app content (a curated catalogue bundled with the app),
/// not user data, so they live in code rather than in Firestore.
class Destination {
  final String id;
  final String name;
  final String region;
  final String country;
  final String tagline;
  final String description;
  final List<String> categories;
  final List<String> highlights;
  final String bestTime;
  final String imageUrl;
  final String imageCredit;
  final bool featured;

  /// Extra words a user might type for this place (e.g. "Leh" for Ladakh).
  final List<String> aliases;

  const Destination({
    required this.id,
    required this.name,
    required this.region,
    required this.country,
    required this.tagline,
    required this.description,
    required this.categories,
    required this.highlights,
    required this.bestTime,
    required this.imageUrl,
    required this.imageCredit,
    this.featured = false,
    this.aliases = const [],
  });

  String get location =>
      region.isEmpty || region == country ? country : '$region, $country';

  /// True when [query] matches the name, location, categories, aliases or
  /// highlights. An empty query matches everything.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final haystack = [
      name,
      region,
      country,
      tagline,
      ...categories,
      ...aliases,
      ...highlights,
    ].join(' ').toLowerCase();

    return q
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .every(haystack.contains);
  }

  bool hasCategory(String? category) {
    if (category == null || category.isEmpty) return true;
    return categories.any((c) => c.toLowerCase() == category.toLowerCase());
  }

  /// True when free text typed by a user (e.g. a saved trip's destination)
  /// refers to this destination.
  bool isNamedBy(String text) {
    final value = text.trim().toLowerCase();
    if (value.isEmpty) return false;
    final names = [name, ...aliases].map((n) => n.toLowerCase());
    return names.any((n) => value == n || value.contains(n));
  }
}
