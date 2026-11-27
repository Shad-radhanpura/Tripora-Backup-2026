/// Limits and checks for a journal entry. The editor and the store both use
/// these, so the same rules apply everywhere.
class JournalRules {
  JournalRules._();

  static const int titleMin = 3;
  static const int titleMax = 90;
  static const int textMax = 3000;
  static const int listItemMax = 120;
  static const int listMax = 20;
  static const int expenseMax = 50;

  static String? validateTitle(String? value) {
    final text = (value ?? '').trim();
    if (text.length < titleMin) return 'Add a title (at least $titleMin characters).';
    if (text.length > titleMax) return 'Keep the title under $titleMax characters.';
    return null;
  }

  static String? validatePlace(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter the place you visited.';
    return null;
  }

  static String? validateText(String? value) {
    if ((value ?? '').length > textMax) return 'Keep this under $textMax characters.';
    return null;
  }

  /// Start and end dates: both optional, but the end cannot be before the start.
  static String? validateDates({DateTime? start, DateTime? end}) {
    if (start != null && end != null && end.isBefore(start)) {
      return 'The end date cannot be before the start date.';
    }
    return null;
  }

  static List<String> cleanList(String raw) => raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  static String? validateList(List<String> items, String what) {
    if (items.length > listMax) return 'Add up to $listMax $what.';
    if (items.any((item) => item.length > listItemMax)) {
      return 'Keep each $what item under $listItemMax characters.';
    }
    return null;
  }

  /// Returns the first problem found, or null when the entry is valid.
  static String? firstProblem({
    required String title,
    required String place,
    required String description,
    required String notes,
    DateTime? start,
    DateTime? end,
    required List<String> highlights,
    required List<String> placesVisited,
  }) {
    return validateTitle(title) ??
        validatePlace(place) ??
        validateDates(start: start, end: end) ??
        validateText(description) ??
        validateText(notes) ??
        validateList(highlights, 'highlights') ??
        validateList(placesVisited, 'places visited');
  }
}

/// One expense noted in a journal entry (for example a hotel or a ticket).
class JournalExpense {
  final String label;
  final int amount;

  const JournalExpense({required this.label, required this.amount});

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount};

  factory JournalExpense.fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final amount = json['amount'];
    if (label is! String || amount is! int) {
      throw const FormatException('Bad expense');
    }
    return JournalExpense(label: label, amount: amount);
  }
}

/// A private travel journal entry. Only its owner ([userId]) can see it.
class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String place;
  final String city;
  final String state;

  /// Single date for a day trip, or the start of a longer journey.
  final DateTime? tripDate;
  final DateTime? endDate;
  final String companions;
  final String description;
  final String notes;
  final List<String> highlights;
  final List<String> placesVisited;
  final List<JournalExpense> expenses;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.place,
    this.city = '',
    this.state = '',
    this.tripDate,
    this.endDate,
    this.companions = '',
    this.description = '',
    this.notes = '',
    this.highlights = const [],
    this.placesVisited = const [],
    this.expenses = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// The day the entry is filed under in the calendar.
  DateTime? get calendarDate => tripDate;

  bool isOwnedBy(String uid) => uid.isNotEmpty && userId == uid;

  int get expenseTotal => expenses.fold(0, (sum, e) => sum + e.amount);

  JournalEntry copyWith({
    String? title,
    String? place,
    String? city,
    String? state,
    DateTime? tripDate,
    DateTime? endDate,
    bool clearDates = false,
    String? companions,
    String? description,
    String? notes,
    List<String>? highlights,
    List<String>? placesVisited,
    List<JournalExpense>? expenses,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id,
      userId: userId,
      title: title ?? this.title,
      place: place ?? this.place,
      city: city ?? this.city,
      state: state ?? this.state,
      tripDate: clearDates ? null : (tripDate ?? this.tripDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      companions: companions ?? this.companions,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      highlights: highlights ?? this.highlights,
      placesVisited: placesVisited ?? this.placesVisited,
      expenses: expenses ?? this.expenses,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'place': place,
    'city': city,
    'state': state,
    'tripDate': tripDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'companions': companions,
    'description': description,
    'notes': notes,
    'highlights': highlights,
    'placesVisited': placesVisited,
    'expenses': [for (final e in expenses) e.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Throws [FormatException] when a required field is missing, so the store
  /// skips that one damaged entry and keeps the rest.
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String) throw FormatException('Missing $key');
      return value;
    }

    String optional(String key) => json[key] is String ? json[key] as String : '';
    DateTime? optionalDate(String key) =>
        json[key] is String ? DateTime.tryParse(json[key] as String) : null;
    List<String> strings(String key) => json[key] is List
        ? (json[key] as List).whereType<String>().toList()
        : const [];

    final expenses = <JournalExpense>[];
    if (json['expenses'] is List) {
      for (final item in json['expenses'] as List) {
        if (item is Map<String, dynamic>) {
          try {
            expenses.add(JournalExpense.fromJson(item));
          } on FormatException {
            // Skip a damaged expense row.
          }
        }
      }
    }

    return JournalEntry(
      id: text('id'),
      userId: text('userId'),
      title: text('title'),
      place: text('place'),
      city: optional('city'),
      state: optional('state'),
      tripDate: optionalDate('tripDate'),
      endDate: optionalDate('endDate'),
      companions: optional('companions'),
      description: optional('description'),
      notes: optional('notes'),
      highlights: strings('highlights'),
      placesVisited: strings('placesVisited'),
      expenses: expenses,
      createdAt: DateTime.parse(text('createdAt')),
      updatedAt: DateTime.parse(text('updatedAt')),
    );
  }
}
