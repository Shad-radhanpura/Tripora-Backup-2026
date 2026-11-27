import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry.dart';

/// Thrown when someone tries to open, change or delete a journal entry that
/// belongs to another person.
class NotOwnerError extends StateError {
  NotOwnerError() : super('This journal entry belongs to another account.');
}

/// Private travel journal entries saved on this device.
///
/// This is device-only storage. Entries are not synchronised to the cloud, so
/// they are not visible on other devices and are not backed up. Each write is
/// saved before the screen is updated, and a failed save never shows as saved.
class JournalStore extends ChangeNotifier {
  JournalStore([this._prefs, DateTime Function()? clock])
    : _clock = clock ?? DateTime.now;

  static final JournalStore instance = JournalStore();

  static const String storageKey = 'journal.local.v1';

  SharedPreferences? _prefs;
  final DateTime Function() _clock;
  final Random _random = Random();
  List<JournalEntry> _items = [];
  bool _loaded = false;
  bool _readFailed = false;

  bool get isLoaded => _loaded;

  /// True when the saved data could not be read. Writes are refused then, so
  /// the unreadable data is never overwritten.
  bool get readFailed => _readFailed;

  /// The entries belonging to [uid], newest trip date first.
  List<JournalEntry> forUser(String uid) {
    final mine = _items.where((e) => e.isOwnedBy(uid)).toList()
      ..sort((a, b) {
        final left = a.calendarDate ?? a.createdAt;
        final right = b.calendarDate ?? b.createdAt;
        return right.compareTo(left);
      });
    return List.unmodifiable(mine);
  }

  JournalEntry? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _items = _decode(_prefs!.getString(storageKey));
      _readFailed = false;
    } catch (_) {
      _readFailed = true;
      _items = [];
    }
    _loaded = true;
    notifyListeners();
  }

  /// Creates an entry for [uid]. Throws [ArgumentError] for invalid input and
  /// [StateError] when the entry cannot be saved.
  Future<JournalEntry> create({
    required String uid,
    required String title,
    required String place,
    String city = '',
    String state = '',
    DateTime? tripDate,
    DateTime? endDate,
    String companions = '',
    String description = '',
    String notes = '',
    List<String> highlights = const [],
    List<String> placesVisited = const [],
    List<JournalExpense> expenses = const [],
  }) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError('Sign in to keep a journal.');
    }
    _checkInput(
      title: title,
      place: place,
      description: description,
      notes: notes,
      start: tripDate,
      end: endDate,
      highlights: highlights,
      placesVisited: placesVisited,
      expenses: expenses,
    );
    final now = _clock();
    final entry = JournalEntry(
      id: _newId(now),
      userId: uid,
      title: title.trim(),
      place: place.trim(),
      city: city.trim(),
      state: state.trim(),
      tripDate: _dayOnly(tripDate),
      endDate: _dayOnly(endDate),
      companions: companions.trim(),
      description: description.trim(),
      notes: notes.trim(),
      highlights: highlights,
      placesVisited: placesVisited,
      expenses: expenses,
      createdAt: now,
      updatedAt: now,
    );
    await _write([..._items, entry]);
    return entry;
  }

  /// Changes an entry. Only its owner may do this.
  Future<JournalEntry> update({
    required String uid,
    required String id,
    required String title,
    required String place,
    String city = '',
    String state = '',
    DateTime? tripDate,
    DateTime? endDate,
    String companions = '',
    String description = '',
    String notes = '',
    List<String> highlights = const [],
    List<String> placesVisited = const [],
    List<JournalExpense> expenses = const [],
  }) async {
    final current = _findOwned(uid, id);
    _checkInput(
      title: title,
      place: place,
      description: description,
      notes: notes,
      start: tripDate,
      end: endDate,
      highlights: highlights,
      placesVisited: placesVisited,
      expenses: expenses,
    );
    // Built directly so that each date is set exactly as the user entered it,
    // including clearing one of them.
    final updated = JournalEntry(
      id: current.id,
      userId: current.userId,
      title: title.trim(),
      place: place.trim(),
      city: city.trim(),
      state: state.trim(),
      tripDate: _dayOnly(tripDate),
      endDate: _dayOnly(endDate),
      companions: companions.trim(),
      description: description.trim(),
      notes: notes.trim(),
      highlights: highlights,
      placesVisited: placesVisited,
      expenses: expenses,
      createdAt: current.createdAt,
      updatedAt: _clock(),
    );
    await _write([for (final e in _items) e.id == id ? updated : e]);
    return updated;
  }

  /// Deletes an entry. Only its owner may do this.
  Future<void> delete({required String uid, required String id}) async {
    _findOwned(uid, id);
    await _write([
      for (final e in _items)
        if (e.id != id) e,
    ]);
  }

  void _checkInput({
    required String title,
    required String place,
    required String description,
    required String notes,
    required DateTime? start,
    required DateTime? end,
    required List<String> highlights,
    required List<String> placesVisited,
    required List<JournalExpense> expenses,
  }) {
    final problem = JournalRules.firstProblem(
      title: title,
      place: place,
      description: description,
      notes: notes,
      start: start,
      end: end,
      highlights: highlights,
      placesVisited: placesVisited,
    );
    if (problem != null) throw ArgumentError(problem);
    if (expenses.length > JournalRules.expenseMax) {
      throw ArgumentError('Add up to ${JournalRules.expenseMax} expenses.');
    }
    for (final expense in expenses) {
      if (expense.label.trim().isEmpty) {
        throw ArgumentError('Each expense needs a label.');
      }
      if (expense.amount < 0) {
        throw ArgumentError('Expense amounts cannot be negative.');
      }
    }
  }

  JournalEntry _findOwned(String uid, String id) {
    final entry = byId(id);
    if (entry == null) {
      throw StateError('This journal entry is no longer on this device.');
    }
    if (!entry.isOwnedBy(uid)) throw NotOwnerError();
    return entry;
  }

  /// Saves [next] first, then replaces the in-memory list.
  Future<void> _write(List<JournalEntry> next) async {
    if (_readFailed) {
      throw StateError(
        'Saved journal entries on this device could not be read, so new changes '
        'are blocked to protect them. Restart the app and try again.',
      );
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final encoded = jsonEncode([for (final e in next) e.toJson()]);
    final ok = await prefs.setString(storageKey, encoded);
    if (!ok) {
      throw StateError('Could not save on this device. Please try again.');
    }
    _items = next;
    notifyListeners();
  }

  List<JournalEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw);
    if (list is! List) throw const FormatException('Not a list');
    final result = <JournalEntry>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        result.add(JournalEntry.fromJson(entry));
      } on FormatException {
        // Skip a damaged entry; the rest stay usable.
      }
    }
    return result;
  }

  static DateTime? _dayOnly(DateTime? value) =>
      value == null ? null : DateTime(value.year, value.month, value.day);

  String _newId(DateTime now) =>
      'jrn_${now.microsecondsSinceEpoch.toRadixString(36)}_'
      '${_random.nextInt(1 << 24).toRadixString(36)}';
}
