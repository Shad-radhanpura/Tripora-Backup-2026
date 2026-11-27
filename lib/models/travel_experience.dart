/// Limits for a travel experience. The editor and the local store both use
/// these, so the same rules apply everywhere.
class ExperienceRules {
  ExperienceRules._();

  static const int titleMin = 4;
  static const int titleMax = 80;
  static const int storyMin = 40;
  static const int storyMax = 2000;
  static const int tipsMax = 600;
  static const int highlightsMax = 5;
  static const int highlightMax = 80;
  static const int ratingMin = 1;
  static const int ratingMax = 5;

  static String? validateTitle(String? value) {
    final text = (value ?? '').trim();
    if (text.length < titleMin) {
      return 'Add a title (at least $titleMin characters).';
    }
    if (text.length > titleMax) {
      return 'Keep the title under $titleMax characters.';
    }
    return null;
  }

  static String? validateStory(String? value) {
    final text = (value ?? '').trim();
    if (text.length < storyMin) {
      return 'Describe your trip in at least $storyMin characters.';
    }
    if (text.length > storyMax) {
      return 'Keep the description under $storyMax characters.';
    }
    return null;
  }

  static String? validateTips(String? value) {
    if ((value ?? '').trim().length > tipsMax) {
      return 'Keep the tips under $tipsMax characters.';
    }
    return null;
  }

  /// One highlight per line. Blank lines are dropped.
  static List<String> parseHighlights(String raw) => raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  static String? validateHighlights(List<String> items) {
    if (items.length > highlightsMax) {
      return 'Add up to $highlightsMax highlights.';
    }
    if (items.any((item) => item.length > highlightMax)) {
      return 'Keep each highlight under $highlightMax characters.';
    }
    return null;
  }

  static String? validateRating(int? value) {
    if (value == null || value < ratingMin || value > ratingMax) {
      return 'Choose a rating from 1 to 5 stars.';
    }
    return null;
  }

  /// Throws [ArgumentError] with the first problem found, so the caller can
  /// show it. Returns normally when everything is valid.
  static void check({
    required String title,
    required String story,
    required String tips,
    required List<String> highlights,
    required int? rating,
    required String destinationId,
  }) {
    if (destinationId.trim().isEmpty) {
      throw ArgumentError('Choose the destination you visited.');
    }
    final problems = [
      validateTitle(title),
      validateStory(story),
      validateTips(tips),
      validateHighlights(highlights),
      validateRating(rating),
    ];
    for (final problem in problems) {
      if (problem != null) throw ArgumentError(problem);
    }
  }
}

/// A traveller's written account of a trip. Every experience belongs to the
/// person who wrote it ([authorId]).
class TravelExperience {
  final String id;
  final String authorId;
  final String authorName;
  final String destinationId;
  final String destinationName;
  final String? tripId;
  final String title;
  final String story;
  final String tips;
  final List<String> highlights;
  final int rating;
  final DateTime publishedAt;
  final DateTime updatedAt;

  const TravelExperience({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.destinationId,
    required this.destinationName,
    this.tripId,
    required this.title,
    required this.story,
    required this.tips,
    required this.highlights,
    required this.rating,
    required this.publishedAt,
    required this.updatedAt,
  });

  bool isOwnedBy(String uid) => uid.isNotEmpty && authorId == uid;

  TravelExperience copyWith({
    String? destinationId,
    String? destinationName,
    String? tripId,
    bool clearTrip = false,
    String? title,
    String? story,
    String? tips,
    List<String>? highlights,
    int? rating,
    DateTime? updatedAt,
  }) {
    return TravelExperience(
      id: id,
      authorId: authorId,
      authorName: authorName,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      tripId: clearTrip ? null : (tripId ?? this.tripId),
      title: title ?? this.title,
      story: story ?? this.story,
      tips: tips ?? this.tips,
      highlights: highlights ?? this.highlights,
      rating: rating ?? this.rating,
      publishedAt: publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'destinationId': destinationId,
    'destinationName': destinationName,
    'tripId': tripId,
    'title': title,
    'story': story,
    'tips': tips,
    'highlights': highlights,
    'rating': rating,
    'publishedAt': publishedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Throws [FormatException] when a required field is missing, so the store
  /// can skip a damaged record instead of failing completely.
  factory TravelExperience.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String) throw FormatException('Missing $key');
      return value;
    }

    final rating = json['rating'];
    if (rating is! int) throw const FormatException('Missing rating');
    final rawHighlights = json['highlights'];
    return TravelExperience(
      id: text('id'),
      authorId: text('authorId'),
      authorName: json['authorName'] is String ? json['authorName'] as String : 'Traveller',
      destinationId: text('destinationId'),
      destinationName: text('destinationName'),
      tripId: json['tripId'] is String ? json['tripId'] as String : null,
      title: text('title'),
      story: text('story'),
      tips: json['tips'] is String ? json['tips'] as String : '',
      highlights: rawHighlights is List
          ? rawHighlights.whereType<String>().toList()
          : const [],
      rating: rating,
      publishedAt: DateTime.parse(text('publishedAt')),
      updatedAt: DateTime.parse(text('updatedAt')),
    );
  }
}
