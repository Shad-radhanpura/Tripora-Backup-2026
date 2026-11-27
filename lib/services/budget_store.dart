import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trip_budget_planner.dart';

/// One money spent during a trip, logged by its owner.
class BudgetExpense {
  final String id;
  final String userId;
  final int amount;
  final String category;
  final DateTime date;
  final String note;
  final String paymentMethod;
  final DateTime createdAt;

  const BudgetExpense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.paymentMethod = 'other',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'amount': amount,
    'category': category,
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'note': note,
    'paymentMethod': paymentMethod,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BudgetExpense.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String) throw FormatException('Missing $key');
      return value;
    }

    final amount = json['amount'];
    if (amount is! int || amount < 0) throw const FormatException('Bad amount');
    return BudgetExpense(
      id: text('id'),
      userId: text('userId'),
      amount: amount,
      category: text('category'),
      date: DateTime.parse(text('date')),
      note: json['note'] is String ? json['note'] as String : '',
      paymentMethod: json['paymentMethod'] is String ? json['paymentMethod'] as String : 'other',
      createdAt: DateTime.parse(text('createdAt')),
    );
  }
}

/// The planner's saved inputs and expense log, kept on this device.
///
/// Device-only storage: nothing is sent to the cloud. Each write is saved before
/// the screen is updated, and writes are refused if the saved data cannot be
/// read, so existing records are never overwritten.
class BudgetStore extends ChangeNotifier {
  BudgetStore([this._prefs, DateTime Function()? clock])
    : _clock = clock ?? DateTime.now;

  static final BudgetStore instance = BudgetStore();

  static const String storageKey = 'budget.local.v1';

  SharedPreferences? _prefs;
  final DateTime Function() _clock;
  final Random _random = Random();
  Map<String, PlanInputs> _plans = {};
  List<BudgetExpense> _expenses = [];
  bool _loaded = false;
  bool _readFailed = false;

  bool get isLoaded => _loaded;
  bool get readFailed => _readFailed;

  PlanInputs? planFor(String uid) => _plans[uid];

  /// The signed-in person's expenses, newest first.
  List<BudgetExpense> expensesFor(String uid) {
    final mine = _expenses.where((e) => e.userId == uid).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(mine);
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is! Map<String, dynamic>) throw const FormatException('Not a map');
        _plans = _decodePlans(data['plans']);
        _expenses = _decodeExpenses(data['expenses']);
      }
      _readFailed = false;
    } catch (_) {
      _readFailed = true;
      _plans = {};
      _expenses = [];
    }
    _loaded = true;
    notifyListeners();
  }

  /// Saves the planner inputs for [uid], replacing any earlier plan.
  Future<void> savePlan(String uid, PlanInputs inputs) async {
    _requireUser(uid);
    final next = Map<String, PlanInputs>.from(_plans)..[uid] = inputs;
    await _write(plans: next, expenses: _expenses);
  }

  Future<BudgetExpense> addExpense({
    required String uid,
    required int amount,
    required String category,
    required DateTime date,
    String note = '',
    String paymentMethod = 'other',
  }) async {
    _requireUser(uid);
    _checkExpense(amount: amount, category: category, note: note, paymentMethod: paymentMethod);
    final now = _clock();
    final expense = BudgetExpense(
      id: _newId(now),
      userId: uid,
      amount: amount,
      category: category,
      date: DateTime(date.year, date.month, date.day),
      note: note.trim(),
      paymentMethod: paymentMethod,
      createdAt: now,
    );
    await _write(plans: _plans, expenses: [..._expenses, expense]);
    return expense;
  }

  Future<void> updateExpense({
    required String uid,
    required String id,
    required int amount,
    required String category,
    required DateTime date,
    String note = '',
    String paymentMethod = 'other',
  }) async {
    final current = _findOwned(uid, id);
    _checkExpense(amount: amount, category: category, note: note, paymentMethod: paymentMethod);
    final updated = BudgetExpense(
      id: current.id,
      userId: current.userId,
      amount: amount,
      category: category,
      date: DateTime(date.year, date.month, date.day),
      note: note.trim(),
      paymentMethod: paymentMethod,
      createdAt: current.createdAt,
    );
    await _write(
      plans: _plans,
      expenses: [for (final e in _expenses) e.id == id ? updated : e],
    );
  }

  Future<void> deleteExpense({required String uid, required String id}) async {
    _findOwned(uid, id);
    await _write(plans: _plans, expenses: [for (final e in _expenses) if (e.id != id) e]);
  }

  void _requireUser(String uid) {
    if (uid.trim().isEmpty) throw ArgumentError('Sign in to use the budget planner.');
  }

  void _checkExpense({
    required int amount,
    required String category,
    required String note,
    required String paymentMethod,
  }) {
    if (amount <= 0) throw ArgumentError('Enter an amount above zero.');
    if (amount > PlanInputs.maxMoney) throw ArgumentError('That amount is too large to be correct.');
    if (!budgetCategoryLabels.containsKey(category)) throw ArgumentError('Choose a category.');
    if (!paymentMethodLabels.containsKey(paymentMethod)) throw ArgumentError('Choose a payment method.');
    if (note.trim().length > 200) throw ArgumentError('Keep the note under 200 characters.');
  }

  BudgetExpense _findOwned(String uid, String id) {
    for (final e in _expenses) {
      if (e.id == id) {
        if (e.userId != uid) throw StateError('This expense belongs to another account.');
        return e;
      }
    }
    throw StateError('This expense is no longer on this device.');
  }

  Future<void> _write({
    required Map<String, PlanInputs> plans,
    required List<BudgetExpense> expenses,
  }) async {
    if (_readFailed) {
      throw StateError(
        'Saved budget data on this device could not be read, so new changes are '
        'blocked to protect it. Restart the app and try again.',
      );
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final encoded = jsonEncode({
      'plans': {for (final e in plans.entries) e.key: e.value.toJson()},
      'expenses': [for (final e in expenses) e.toJson()],
    });
    final ok = await prefs.setString(storageKey, encoded);
    if (!ok) throw StateError('Could not save on this device. Please try again.');
    _plans = plans;
    _expenses = expenses;
    notifyListeners();
  }

  Map<String, PlanInputs> _decodePlans(Object? raw) {
    final result = <String, PlanInputs>{};
    if (raw is! Map) return result;
    for (final entry in raw.entries) {
      final value = entry.value;
      if (entry.key is String && value is Map<String, dynamic>) {
        try {
          result[entry.key as String] = PlanInputs.fromJson(value);
        } on FormatException {
          // Skip a damaged plan.
        }
      }
    }
    return result;
  }

  List<BudgetExpense> _decodeExpenses(Object? raw) {
    final result = <BudgetExpense>[];
    if (raw is! List) return result;
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(BudgetExpense.fromJson(item));
        } on FormatException {
          // Skip a damaged expense.
        }
      }
    }
    return result;
  }

  String _newId(DateTime now) =>
      'exp_${now.microsecondsSinceEpoch.toRadixString(36)}_'
      '${_random.nextInt(1 << 24).toRadixString(36)}';
}
