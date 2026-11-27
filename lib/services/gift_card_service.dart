import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo gift cards. No payment is taken, no real money is issued, and a card
/// can only be spent inside Tripora's demo booking preview. Real issuance needs
/// a payment provider and server-side verification, which are not configured.
class DemoGiftCards {
  DemoGiftCards._();

  static const List<int> denominations = [1000, 2000, 5000, 10000];
  static const int validityDays = 365;
  static const String issuanceNotice =
      'Demo gift card. No payment has been taken and no real value has been issued. '
      'It can only be used in the demo booking preview.';

  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// A demo card number. It is not a real card number and has no value outside
  /// this app.
  static String newCode(Random random) {
    String part() => List.generate(4, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
    return 'DEMO-${part()}-${part()}';
  }

  static String? validateRecipient({required String name, required String email, required String message}) {
    if (name.trim().length < 2) return 'Enter the recipient\'s name.';
    if (name.trim().length > 60) return 'Keep the recipient\'s name under 60 characters.';
    final mail = email.trim();
    if (mail.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      return 'Enter a valid email address, or leave it blank.';
    }
    if (message.trim().length > 200) return 'Keep the message under 200 characters.';
    return null;
  }
}

class GiftTransaction {
  final DateTime date;

  /// Negative for a redemption.
  final int amount;
  final String note;

  const GiftTransaction({required this.date, required this.amount, required this.note});

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'amount': amount, 'note': note};

  factory GiftTransaction.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    if (amount is! int || json['date'] is! String) throw const FormatException('Bad transaction');
    return GiftTransaction(
      date: DateTime.parse(json['date'] as String),
      amount: amount,
      note: json['note'] is String ? json['note'] as String : '',
    );
  }
}

class DemoGiftCard {
  final String code;
  final int denomination;
  final int balance;
  final String recipientName;
  final String recipientEmail;
  final String message;
  final String buyerUid;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final List<GiftTransaction> transactions;

  const DemoGiftCard({
    required this.code,
    required this.denomination,
    required this.balance,
    required this.recipientName,
    required this.recipientEmail,
    required this.message,
    required this.buyerUid,
    required this.issuedAt,
    required this.expiresAt,
    this.transactions = const [],
  });

  /// active, redeemed (no balance left), or expired, as of [today].
  String statusOn(DateTime today) {
    if (_day(today).isAfter(_day(expiresAt))) return 'Expired';
    if (balance <= 0) return 'Fully used';
    return 'Active (demo)';
  }

  DemoGiftCard copyWith({int? balance, List<GiftTransaction>? transactions}) => DemoGiftCard(
        code: code,
        denomination: denomination,
        balance: balance ?? this.balance,
        recipientName: recipientName,
        recipientEmail: recipientEmail,
        message: message,
        buyerUid: buyerUid,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        transactions: transactions ?? this.transactions,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'denomination': denomination,
        'balance': balance,
        'recipientName': recipientName,
        'recipientEmail': recipientEmail,
        'message': message,
        'buyerUid': buyerUid,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'transactions': [for (final t in transactions) t.toJson()],
      };

  factory DemoGiftCard.fromJson(Map<String, dynamic> json) {
    int whole(String key) {
      final v = json[key];
      if (v is! int || v < 0) throw FormatException('Bad $key');
      return v;
    }

    String text(String key) {
      final v = json[key];
      if (v is! String) throw FormatException('Missing $key');
      return v;
    }

    final txs = <GiftTransaction>[];
    if (json['transactions'] is List) {
      for (final item in json['transactions'] as List) {
        if (item is Map<String, dynamic>) {
          try {
            txs.add(GiftTransaction.fromJson(item));
          } on FormatException {
            // Skip a damaged transaction.
          }
        }
      }
    }
    return DemoGiftCard(
      code: text('code'),
      denomination: whole('denomination'),
      balance: whole('balance'),
      recipientName: text('recipientName'),
      recipientEmail: json['recipientEmail'] is String ? json['recipientEmail'] as String : '',
      message: json['message'] is String ? json['message'] as String : '',
      buyerUid: text('buyerUid'),
      issuedAt: DateTime.parse(text('issuedAt')),
      expiresAt: DateTime.parse(text('expiresAt')),
      transactions: txs,
    );
  }

  static DateTime _day(DateTime v) => DateTime(v.year, v.month, v.day);
}

enum RedeemProblem { invalidAmount, notFound, expired, fullyUsed, insufficientBalance }

class RedeemResult {
  final int applied;
  final RedeemProblem? problem;
  final DemoGiftCard? card;

  const RedeemResult._(this.applied, this.problem, this.card);

  bool get ok => problem == null;

  factory RedeemResult.ok(DemoGiftCard card, int applied) => RedeemResult._(applied, null, card);
  factory RedeemResult.fail(RedeemProblem problem, [DemoGiftCard? card]) => RedeemResult._(0, problem, card);

  String get message => switch (problem) {
        null => 'Applied ₹$applied from the demo gift card.',
        RedeemProblem.invalidAmount => 'Enter an amount above zero.',
        RedeemProblem.notFound => 'No demo gift card has that number.',
        RedeemProblem.expired => 'This demo gift card has expired.',
        RedeemProblem.fullyUsed => 'This demo gift card has no balance left.',
        RedeemProblem.insufficientBalance =>
          'This card has ₹${card?.balance ?? 0} left, which is less than ₹$applied.',
      };
}

/// Pure rules for issuing and redeeming demo cards. [cards] is the full list,
/// so the same rules run in tests and in the store.
class GiftCardRules {
  GiftCardRules._();

  static RedeemResult redeem({
    required List<DemoGiftCard> cards,
    required String code,
    required int amount,
    required DateTime today,
  }) {
    if (amount <= 0) return RedeemResult.fail(RedeemProblem.invalidAmount);
    final wanted = code.trim().toUpperCase();
    DemoGiftCard? card;
    for (final c in cards) {
      if (c.code == wanted) card = c;
    }
    if (card == null) return RedeemResult.fail(RedeemProblem.notFound);
    if (card.statusOn(today) == 'Expired') return RedeemResult.fail(RedeemProblem.expired, card);
    if (card.balance <= 0) return RedeemResult.fail(RedeemProblem.fullyUsed, card);
    if (amount > card.balance) return RedeemResult.fail(RedeemProblem.insufficientBalance, card);
    return RedeemResult.ok(card, amount);
  }
}

/// Demo gift cards stored on this device for one account.
class GiftCardStore extends ChangeNotifier {
  GiftCardStore([this._prefs, DateTime Function()? clock]) : _clock = clock ?? DateTime.now;

  static final GiftCardStore instance = GiftCardStore();
  static const String storageKey = 'giftcards.demo.v1';

  SharedPreferences? _prefs;
  final DateTime Function() _clock;
  final Random _random = Random();
  List<DemoGiftCard> _cards = [];
  bool _loaded = false;
  bool _readFailed = false;

  bool get isLoaded => _loaded;
  bool get readFailed => _readFailed;

  List<DemoGiftCard> cardsFor(String uid) => List.unmodifiable(
        _cards.where((c) => c.buyerUid == uid).toList()..sort((a, b) => b.issuedAt.compareTo(a.issuedAt)),
      );

  List<DemoGiftCard> get allCards => List.unmodifiable(_cards);

  Future<void> load() async {
    if (_loaded) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(storageKey);
      _cards = _decode(raw);
      _readFailed = false;
    } catch (_) {
      _readFailed = true;
      _cards = [];
    }
    _loaded = true;
    notifyListeners();
  }

  /// Issues a demo card. No payment is taken. Throws [ArgumentError] for
  /// invalid input and [StateError] when the device cannot save it.
  Future<DemoGiftCard> issue({
    required String buyerUid,
    required int denomination,
    required String recipientName,
    String recipientEmail = '',
    String message = '',
  }) async {
    if (buyerUid.trim().isEmpty) throw ArgumentError('Sign in to buy a demo gift card.');
    if (!DemoGiftCards.denominations.contains(denomination)) {
      throw ArgumentError('Choose one of the listed amounts.');
    }
    final problem = DemoGiftCards.validateRecipient(
      name: recipientName,
      email: recipientEmail,
      message: message,
    );
    if (problem != null) throw ArgumentError(problem);

    final now = _clock();
    String code;
    do {
      code = DemoGiftCards.newCode(_random);
    } while (_cards.any((c) => c.code == code));
    final card = DemoGiftCard(
      code: code,
      denomination: denomination,
      balance: denomination,
      recipientName: recipientName.trim(),
      recipientEmail: recipientEmail.trim(),
      message: message.trim(),
      buyerUid: buyerUid,
      issuedAt: now,
      expiresAt: now.add(const Duration(days: DemoGiftCards.validityDays)),
    );
    await _write([..._cards, card]);
    return card;
  }

  /// Spends [amount] from a card. Records the transaction and saves it.
  Future<RedeemResult> redeem({required String code, required int amount, required String note}) async {
    final result = GiftCardRules.redeem(cards: _cards, code: code, amount: amount, today: _clock());
    if (!result.ok) return result;
    final card = result.card!;
    final updated = card.copyWith(
      balance: card.balance - result.applied,
      transactions: [
        ...card.transactions,
        GiftTransaction(date: _clock(), amount: -result.applied, note: note),
      ],
    );
    await _write([for (final c in _cards) c.code == card.code ? updated : c]);
    return RedeemResult.ok(updated, result.applied);
  }

  Future<void> _write(List<DemoGiftCard> next) async {
    if (_readFailed) {
      throw StateError('Saved demo gift cards could not be read, so changes are blocked to protect them.');
    }
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final ok = await prefs.setString(storageKey, jsonEncode([for (final c in next) c.toJson()]));
    if (!ok) throw StateError('Could not save on this device. Please try again.');
    _cards = next;
    notifyListeners();
  }

  List<DemoGiftCard> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw);
    if (list is! List) throw const FormatException('Not a list');
    final result = <DemoGiftCard>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        try {
          result.add(DemoGiftCard.fromJson(item));
        } on FormatException {
          // Skip a damaged card.
        }
      }
    }
    return result;
  }
}
