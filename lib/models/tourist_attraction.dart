/// A tourist attraction shown in Destination Explorer.
///
/// Attractions are app content (a curated list bundled with the app), not
/// user data, so they live in code. Every photo is a Wikimedia Commons file
/// that was checked to load and to show the named place; its licence and
/// author are kept in [imageCredit].
class TouristAttraction {
  final String name;
  final String location;
  final String description;

  /// Verified photo URL, or null when no verified photo exists yet. A null
  /// URL shows an attractive placeholder instead of an unrelated picture.
  final String? imageUrl;
  final String imageCredit;

  const TouristAttraction({
    required this.name,
    required this.location,
    required this.description,
    required this.imageCredit,
    this.imageUrl,
  });
}
