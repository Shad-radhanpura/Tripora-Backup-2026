import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/travel_experience.dart';

/// Thrown when someone tries to edit or delete an experience they did not
/// write.
class NotAuthorError extends StateError {
  NotAuthorError() : super('Only the person who wrote this can change it.');
}

/// Travel experiences saved on this device.
///
/// This is a local fallback. Records live only in this browser or phone:
/// other travellers, the admin and other devices cannot see them, and they
/// are not backed up. Each write is saved before the screen is updated, so a
/// failed save never shows as saved.
class ExperienceStore extends ChangeNotifier {
  /// [_prefs] is optional; tests pass an in-memory store, and the app leaves it
  /// empty so the device storage is opened on first use.
  ExperienceStore([this._prefs, DateTime Function()? clock])
    : _clock = clock ?? DateTime.now;

  static final ExperienceStore instance = ExperienceStore();

  static const String storageKey = 'experiences.local.v1';

  SharedPreferences? _prefs;
  final DateTime Function() _clock;
  final Random _random = Random();
  List<TravelExperience> _items = [];
  bool _loaded = false;

  /// True when the saved data could not be read. Writes are refused then, so
  /// the unreadable data is never overwritten.
  bool _readFailed = false;

  bool get isLoaded => _loaded;
  bool get readFailed => _readFailed;

  /// Every experience on this device, newest first.
  List<TravelExperience> get all {
    final sorted = [..._items]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return List.unmodifiable(sorted);
  }

  List<TravelExperience> byAuthor(String uid) =>
      all.where((e) => e.authorId == uid).toList();

  TravelExperience? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(storageKey);
      _items = _decode(raw);
      _readFailed = false;
    } catch (_) {
      _readFailed = true;
      _items = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<TravelExperience> create({
    required String authorId,
    required String authorName,
    required String destinationId,
    required String destinationName,
    String? tripId,
    required String title,
    required String story,
    required String tips,
    required List<String> highlights,
    required int rating,
  }) async {
    if (authorId.trim().isEmpty) {
      throw ArgumentError('Sign in to write an experience.');
    }
    ExperienceRules.check(
      title: title,
      story: story,
      tips: tips,
      highlights: highlights,
      rating: rating,
      destinationId: destinationId,
    );
    final now = _clock();
    final item = TravelExperience(
      id: _newId(now),
      authorId: authorId,
      authorName: authorName.trim().isEmpty ? 'Traveller' : authorName.trim(),
      destinationId: destinationId,
      destinationName: destinationName,
      tripId: tripId,
      title: title.trim(),
      story: story.trim(),
      tips: tips.trim(),
      highlights: highlights,
      rating: rating,
      publishedAt: now,
      updatedAt: now,
    );
    await _write([..._items, item]);
    return item;
  }

  /// Changes an experience. Only its author may do this.
  Future<TravelExperience> update({
    required String uid,
    required String id,
    required String destinationId,
    required String destinationName,
    String? tripId,
    required String title,
    required String story,
    required String tips,
    required List<String> highlights,
    required int rating,
  }) async {
    final current = _findOwned(uid, id);
    ExperienceRules.check(
      title: title,
      story: story,
      tips: tips,
      highlights: highlights,
      rating: rating,
      destinationId: destinationId,
    );
    final updated = current.copyWith(
      destinationId: destinationId,
      destinationName: destinationName,
      tripId: tripId,
      clearTrip: tripId == null,
      title: title.trim(),
      story: story.trim(),
      tips: tips.trim(),
      highlights: highlights,
      rating: rating,
      updatedAt: _clock(),
    );
    await _write([
      for (final item in _items) item.id == id ? updated : item,
    ]);
    return updated;
  }

  /// Deletes an experience. Only its author may do this.
  Future<void> delete({required String uid, required String id}) async {
    _findOwned(uid, id);
    await _write([
      for (final item in _items)
        if (item.id != id) item,
    ]);
  }

  TravelExperience _findOwned(String uid, String id) {
    final item = byId(id);
    if (item == null) {
      throw StateError('This experience is no longer on this device.');
    }
    if (!item.isOwnedBy(uid)) throw NotAuthorError();
    return item;
  }

  /// Saves [next] first; only then replaces the in-memory list. If saving
  /// fails, the screen still shows the previous state.
  Future<void> _write(List<TravelExperience> next) async {
    if (_readFailed) {
      throw StateError(
        'Saved experiences on this device could not be read, so new changes '
        'are blocked to protect them. Restart the app and try again.',
      );
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final encoded = jsonEncode([for (final item in next) item.toJson()]);
    final ok = await prefs.setString(storageKey, encoded);
    if (!ok) {
      throw StateError('Could not save on this device. Please try again.');
    }
    _items = next;
    notifyListeners();
  }

  List<TravelExperience> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw);
    if (list is! List) throw const FormatException('Not a list');
    final result = <TravelExperience>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        result.add(TravelExperience.fromJson(entry));
      } on FormatException {
        // Skip a damaged record; the rest stay usable.
      }
    }
    return result;
  }

  String _newId(DateTime now) =>
      'exp_${now.microsecondsSinceEpoch.toRadixString(36)}_'
      '${_random.nextInt(1 << 24).toRadixString(36)}';
}
