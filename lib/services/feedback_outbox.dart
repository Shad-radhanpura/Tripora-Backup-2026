import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A report that is saved on this device because it has not reached the
/// Tripora team yet.
class FeedbackDraft {
  final String id;
  final String userId;
  final String category;
  final String priority;
  final String subject;
  final String message;
  final DateTime savedAt;

  const FeedbackDraft({
    required this.id,
    required this.userId,
    required this.category,
    required this.priority,
    required this.subject,
    required this.message,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'category': category,
    'priority': priority,
    'subject': subject,
    'message': message,
    'savedAt': savedAt.toIso8601String(),
  };

  factory FeedbackDraft.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String) throw FormatException('Missing $key');
      return value;
    }

    return FeedbackDraft(
      id: text('id'),
      userId: text('userId'),
      category: text('category'),
      priority: text('priority'),
      subject: text('subject'),
      message: text('message'),
      savedAt: DateTime.parse(text('savedAt')),
    );
  }
}

/// Reports waiting on this device. The app shows them as "Saved on this
/// device, not sent yet" until the cloud write succeeds.
class FeedbackOutbox extends ChangeNotifier {
  FeedbackOutbox([this._prefs]);

  static final FeedbackOutbox instance = FeedbackOutbox();

  static const String storageKey = 'feedback.outbox.v1';

  SharedPreferences? _prefs;
  List<FeedbackDraft> _items = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<FeedbackDraft> forUser(String uid) {
    final mine = _items.where((d) => d.userId == uid).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return List.unmodifiable(mine);
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _items = _decode(_prefs!.getString(storageKey));
    } catch (_) {
      // Unreadable storage: show nothing rather than guess.
      _items = [];
    }
    _loaded = true;
    notifyListeners();
  }

  /// Saves [draft] on this device. Throws [StateError] if the device refuses,
  /// so the caller can tell the user the report was not saved anywhere.
  Future<void> add(FeedbackDraft draft) async {
    final next = [..._items, draft];
    await _write(next);
  }

  Future<void> remove(String id) async {
    final next = [
      for (final draft in _items)
        if (draft.id != id) draft,
    ];
    await _write(next);
  }

  Future<void> _write(List<FeedbackDraft> next) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final encoded = jsonEncode([for (final d in next) d.toJson()]);
    final ok = await prefs.setString(storageKey, encoded);
    if (!ok) {
      throw StateError('This device could not save the report.');
    }
    _items = next;
    notifyListeners();
  }

  List<FeedbackDraft> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw);
    if (list is! List) return [];
    final result = <FeedbackDraft>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        result.add(FeedbackDraft.fromJson(entry));
      } on FormatException {
        // Skip a damaged entry; keep the rest.
      }
    }
    return result;
  }
}
