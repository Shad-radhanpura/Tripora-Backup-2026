import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/saved_trip.dart' show formatDate;
import '../models/tour_package.dart' show formatInr;
import '../services/app_firebase.dart';
import '../services/gift_card_service.dart';
import '../services/offers_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

String _offerStatus(DemoOffer o, DateTime today) {
  if (!o.active) return 'Disabled';
  final day = DateTime(today.year, today.month, today.day);
  if (day.isBefore(DateTime(o.validFrom.year, o.validFrom.month, o.validFrom.day))) return 'Scheduled';
  if (day.isAfter(DateTime(o.validTo.year, o.validTo.month, o.validTo.day))) return 'Expired';
  return 'Active (demo)';
}

/// Demo offers and coupons. Demo offers are examples and cannot be redeemed
/// through a payment provider.
class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  bool _activeOnly = true;
  bool _biggestFirst = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final today = DateTime.now();
    var offers = [...DemoOffers.all];
    if (_activeOnly) {
      offers = offers.where((o) => _offerStatus(o, today) == 'Active (demo)').toList();
    }
    offers.sort((a, b) => _biggestFirst
        ? b.value.compareTo(a.value)
        : a.validTo.compareTo(b.validTo));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Offers and coupons')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.warningSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.warningBorder),
                ),
                child: Text(
                  'Demo offers. They are examples only, are not authorised promotions, and '
                  'cannot be redeemed through a payment provider.',
                  style: TextStyle(color: palette.warningText, fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    key: const Key('offers-active-only'),
                    label: const Text('Active only'),
                    selected: _activeOnly,
                    onSelected: (v) => setState(() => _activeOnly = v),
                  ),
                  ChoiceChip(
                    key: const Key('offers-sort-ending'),
                    label: const Text('Ending soonest'),
                    selected: !_biggestFirst,
                    onSelected: (_) => setState(() => _biggestFirst = false),
                  ),
                  ChoiceChip(
                    key: const Key('offers-sort-value'),
                    label: const Text('Biggest saving'),
                    selected: _biggestFirst,
                    onSelected: (_) => setState(() => _biggestFirst = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (offers.isEmpty)
                const EmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'No active offers right now',
                  message: 'Turn off "Active only" to see scheduled and expired demo offers.',
                )
              else
                for (final o in offers) ...[
                  _OfferCard(offer: o, status: _offerStatus(o, today)),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 4),
              Text('Demo records. Dates and amounts are examples, not live promotions.',
                  style: TextStyle(color: palette.muted, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final DemoOffer offer;
  final String status;

  const _OfferCard({required this.offer, required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = status == 'Active (demo)';
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('offer-${offer.code}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => SafeNav.push(context, OfferDetailPage(offer: offer)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: active ? AppColors.actionGradient : null,
            color: active ? null : palette.surfaceTint,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.valueLabel,
                      style: TextStyle(
                        color: active ? Colors.white : palette.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TagChip(
                    label: status,
                    color: active ? Colors.white : palette.muted,
                    onDark: active,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(offer.title,
                  style: TextStyle(color: active ? Colors.white : palette.text, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Code ${offer.code} · valid ${formatDate(offer.validFrom)} to ${formatDate(offer.validTo)}',
                style: TextStyle(color: active ? Colors.white70 : palette.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfferDetailPage extends StatelessWidget {
  final DemoOffer offer;

  const OfferDetailPage({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final status = _offerStatus(offer, DateTime.now());
    final groups = offer.eligibleGroups.isEmpty
        ? 'Any travel group'
        : offer.eligibleGroups.map((g) => g.label).join(', ');
    final categories = offer.eligibleCategories.isEmpty
        ? 'Any package category'
        : offer.eligibleCategories.join(', ');
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(offer.code)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              Text(offer.title,
                  style: TextStyle(color: palette.text, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TagChip(label: status, color: palette.blue),
              const SizedBox(height: 12),
              _Detail('Discount', offer.valueLabel),
              _Detail('Minimum booking', offer.minimumAmount == 0 ? 'None' : formatInr(offer.minimumAmount)),
              _Detail(
                'Maximum discount',
                offer.maximumDiscount == null ? 'No cap' : formatInr(offer.maximumDiscount!),
              ),
              _Detail('Valid', '${formatDate(offer.validFrom)} to ${formatDate(offer.validTo)}'),
              _Detail('Eligible travellers', groups),
              _Detail('Eligible packages', categories),
              _Detail(
                'Usage',
                '${offer.perPersonLimit} per person'
                    '${offer.totalUsageLimit == null ? '' : ', ${offer.totalUsageLimit} in total'}',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Text(offer.description, style: TextStyle(color: palette.text, height: 1.45)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('offer-copy-code'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: offer.code));
                  if (context.mounted) showAppMessage(context, 'Copied ${offer.code}. Paste it in the package preview.');
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy code'),
              ),
              const SizedBox(height: 12),
              Text(
                'Terms: a demo offer for illustration. Usage is checked on this device only. '
                'Real offers would be set by Tripora or the operator and checked on the server.',
                style: TextStyle(color: palette.muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: palette.muted, fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: palette.text, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

/// Demo gift cards: buy (with a preview and confirmation), list, and redeem in
/// the demo preview. No payment is taken and no real value is issued.
class GiftCardsPage extends StatefulWidget {
  const GiftCardsPage({super.key});

  @override
  State<GiftCardsPage> createState() => _GiftCardsPageState();
}

class _GiftCardsPageState extends State<GiftCardsPage> {
  final _store = GiftCardStore.instance;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  int _amount = DemoGiftCards.denominations[1];
  bool _issuing = false;

  String get _uid => AppFirebase.auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final problem = DemoGiftCards.validateRecipient(
      name: _name.text,
      email: _email.text,
      message: _message.text,
    );
    if (problem != null) {
      showAppMessage(context, problem, error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('gift-preview'),
        title: const Text('Review demo gift card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${formatInr(_amount)}'),
            Text('To: ${_name.text.trim()}'),
            if (_email.text.trim().isNotEmpty) Text('Email: ${_email.text.trim()}'),
            if (_message.text.trim().isNotEmpty) Text('Message: ${_message.text.trim()}'),
            const SizedBox(height: 10),
            Text(DemoGiftCards.issuanceNotice,
                style: TextStyle(color: dialogContext.palette.warningText, fontSize: 12.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Back')),
          FilledButton(
            key: const Key('gift-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create demo card'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _issuing = true);
    try {
      final card = await _store.issue(
        buyerUid: _uid,
        denomination: _amount,
        recipientName: _name.text,
        recipientEmail: _email.text,
        message: _message.text,
      );
      if (!mounted) return;
      _name.clear();
      _email.clear();
      _message.clear();
      showAppMessage(context, 'Demo card ${card.code} created. No payment was taken.');
    } on ArgumentError catch (e) {
      if (mounted) showAppMessage(context, '${e.message}', error: true);
    } catch (e) {
      if (mounted) showAppMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Gift cards (demo)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.warningSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.warningBorder),
                ),
                child: Text(DemoGiftCards.issuanceNotice,
                    style: TextStyle(color: palette.warningText, fontSize: 12, height: 1.4)),
              ),
              const SizedBox(height: 14),
              const _GiftPreviewCard(),
              const SizedBox(height: 14),
              Text('Choose an amount', style: TextStyle(color: palette.text, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in DemoGiftCards.denominations)
                    ChoiceChip(
                      key: Key('gift-amount-$d'),
                      label: Text(formatInr(d)),
                      selected: _amount == d,
                      onSelected: (_) => setState(() => _amount = d),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('gift-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Recipient name'),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('gift-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Recipient email (optional)'),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('gift-message'),
                controller: _message,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Personal message (optional)'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('gift-review'),
                onPressed: _issuing || _uid.isEmpty ? null : _preview,
                icon: const Icon(Icons.card_giftcard_rounded),
                label: Text(_uid.isEmpty ? 'Sign in to create a demo card' : 'Review demo card'),
              ),
              const SizedBox(height: 22),
              Text('Your demo cards', style: TextStyle(color: palette.text, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _store,
                builder: (context, _) {
                  if (_uid.isEmpty) return const SizedBox.shrink();
                  if (!_store.isLoaded) return const LoadingState(message: 'Loading your demo cards…');
                  if (_store.readFailed) {
                    return const EmptyState(
                      icon: Icons.lock_clock_outlined,
                      title: 'Saved demo cards could not be read',
                      message: 'New cards are blocked so the saved ones are not overwritten.',
                    );
                  }
                  final cards = _store.cardsFor(_uid);
                  if (cards.isEmpty) {
                    return const EmptyState(
                      icon: Icons.card_giftcard_outlined,
                      title: 'No demo cards yet',
                      message: 'Create one above. It is for demonstration and cannot be spent outside the app.',
                    );
                  }
                  return Column(
                    children: [
                      for (final c in cards) ...[
                        _CardTile(card: c),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiftPreviewCard extends StatelessWidget {
  const _GiftPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('gift-visual'),
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tripora demo gift card',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          Text('Not a real card. No value is issued.', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final DemoGiftCard card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final status = card.statusOn(DateTime.now());
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('gift-card-${card.code}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => SafeNav.push(context, GiftCardDetailPage(code: card.code)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.code, style: TextStyle(color: palette.text, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('Balance ${formatInr(card.balance)} of ${formatInr(card.denomination)} · for ${card.recipientName}',
                        style: TextStyle(color: palette.muted, fontSize: 12)),
                  ],
                ),
              ),
              TagChip(label: status, color: status.startsWith('Active') ? palette.green : palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class GiftCardDetailPage extends StatefulWidget {
  final String code;

  const GiftCardDetailPage({super.key, required this.code});

  @override
  State<GiftCardDetailPage> createState() => _GiftCardDetailPageState();
}

class _GiftCardDetailPageState extends State<GiftCardDetailPage> {
  final _amount = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final value = int.tryParse(_amount.text.trim()) ?? 0;
    final result = await GiftCardStore.instance.redeem(
      code: widget.code,
      amount: value,
      note: 'Demo redemption in the preview',
    );
    if (!mounted) return;
    setState(() => _message = result.message);
    if (result.ok) _amount.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: GiftCardStore.instance,
      builder: (context, _) {
        DemoGiftCard? card;
        for (final c in GiftCardStore.instance.allCards) {
          if (c.code == widget.code) card = c;
        }
        if (card == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.card_giftcard_outlined,
              title: 'Card not found',
              message: 'This demo card is not on this device.',
            ),
          );
        }
        final c = card;
        final status = c.statusOn(DateTime.now());
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(title: const Text('Demo gift card')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  Text(c.code, style: TextStyle(color: palette.text, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  TagChip(label: status, color: status.startsWith('Active') ? palette.green : palette.muted),
                  const SizedBox(height: 12),
                  Text('Balance: ${formatInr(c.balance)} of ${formatInr(c.denomination)} (demo)',
                      key: const Key('gift-balance'),
                      style: TextStyle(color: palette.text, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Valid until ${formatDate(c.expiresAt)}. No payment was taken.',
                      style: TextStyle(color: palette.muted)),
                  if (c.message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('"${c.message}"', style: TextStyle(color: palette.text, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 16),
                  Text('Transactions (demo)', style: TextStyle(color: palette.text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  if (c.transactions.isEmpty)
                    Text('No spending yet.', style: TextStyle(color: palette.muted))
                  else
                    for (final t in c.transactions)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${t.amount < 0 ? '−' : '+'} ${formatInr(t.amount.abs())}'),
                        subtitle: Text('${formatDate(t.date)} · ${t.note}'),
                      ),
                  const SizedBox(height: 16),
                  Text('Use in the demo preview', style: TextStyle(color: palette.text, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('This spends demo balance only. It does not charge any real payment method.',
                      style: TextStyle(color: palette.muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('gift-redeem-amount'),
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Amount (₹)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('gift-redeem'),
                        onPressed: status == 'Active (demo)' ? _redeem : null,
                        child: const Text('Redeem demo'),
                      ),
                    ],
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_message!, key: const Key('gift-redeem-message'),
                          style: TextStyle(color: palette.text)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
