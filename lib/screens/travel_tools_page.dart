import 'dart:math';

import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/destination.dart';
import '../services/travel_tools.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'destination_details_screen.dart';
import 'demo_catalogue_pages.dart';
import 'emergency_help_page.dart';
import 'nearby_services_page.dart';
import 'offers_gift_pages.dart';
import 'trip_budget_planner_page.dart';

/// Formats an amount in Indian rupees with comma grouping, e.g. ₹7,590.
String formatRupees(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final left = digits.length - i;
    buffer.write(digits[i]);
    if (left > 1 && left % 3 == 1) buffer.write(',');
  }
  return '${value < 0 ? '-' : ''}₹$buffer';
}

/// Formats an amount held in paise (1/100 rupee), keeping the paise so split
/// balances never look rounded. Whole rupees show no decimals.
String formatMoneyCents(int cents) {
  final paise = cents.abs() % 100;
  final rupees = formatRupees(cents.abs() ~/ 100);
  final sign = cents < 0 ? '-' : '';
  final decimals = paise == 0 ? '' : '.${paise.toString().padLeft(2, '0')}';
  return '$sign$rupees$decimals';
}

/// Hub for the planning tools. Each tool is a separate screen so that the
/// main Explore tab stays short.
class TravelToolsPage extends StatelessWidget {
  const TravelToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <_ToolEntry>[
      _ToolEntry(
        key: 'tool-compare',
        icon: Icons.compare_arrows_rounded,
        title: 'Compare destinations',
        subtitle: 'Put two places side by side: best time, interests, highlights.',
        color: context.palette.blue,
        page: const CompareDestinationsPage(),
      ),
      _ToolEntry(
        key: 'tool-surprise',
        icon: Icons.casino_rounded,
        title: 'Surprise me',
        subtitle: 'Let Tripora pick a destination from the catalogue.',
        color: context.palette.purple,
        page: const SurprisePage(),
      ),
      _ToolEntry(
        key: 'tool-demo-packages',
        icon: Icons.luggage_rounded,
        title: 'Tour packages (demo)',
        subtitle: 'Browse 100+ demo packages by group, price, duration and date.',
        color: context.palette.blue,
        page: const DemoCataloguePage(),
      ),
      _ToolEntry(
        key: 'tool-nearby',
        icon: Icons.place_rounded,
        title: 'Nearby city services',
        subtitle: 'Hospitals, police, markets, temples and more in supported cities (demo).',
        color: context.palette.teal,
        page: const NearbyServicesPage(),
      ),
      _ToolEntry(
        key: 'tool-offers',
        icon: Icons.local_offer_rounded,
        title: 'Offers and coupons',
        subtitle: 'Demo offers, coupon rules and how discounts are worked out.',
        color: context.palette.orange,
        page: const OffersPage(),
      ),
      _ToolEntry(
        key: 'tool-gift-cards',
        icon: Icons.card_giftcard_rounded,
        title: 'Gift cards (demo)',
        subtitle: 'Demo gift cards with a preview. No payment is taken.',
        color: context.palette.pink,
        page: const GiftCardsPage(),
      ),
      _ToolEntry(
        key: 'tool-budget',
        icon: Icons.account_balance_wallet_rounded,
        title: 'Trip budget planner',
        subtitle: 'Itemised estimate, three levels, and your expense log.',
        color: context.palette.teal,
        page: const TripBudgetPlannerPage(),
      ),
      _ToolEntry(
        key: 'tool-split',
        icon: Icons.call_split_rounded,
        title: 'Split expenses',
        subtitle: 'Track shared costs and see who pays whom.',
        color: context.palette.pink,
        page: const ExpenseSplitPage(),
      ),
      _ToolEntry(
        key: 'tool-luggage',
        icon: Icons.luggage_rounded,
        title: 'Luggage planner',
        subtitle: 'Add up bag weights before you reach the check-in desk.',
        color: context.palette.orange,
        page: const LuggageToolPage(),
      ),
      _ToolEntry(
        key: 'tool-currency',
        icon: Icons.currency_exchange_rounded,
        title: 'Currency converter',
        subtitle: 'Sample rates for planning. Not live rates.',
        color: context.palette.green,
        page: const CurrencyToolPage(),
      ),
      _ToolEntry(
        key: 'tool-readiness',
        icon: Icons.fact_check_rounded,
        title: 'Trip readiness',
        subtitle: 'See what is still missing before you leave.',
        color: context.palette.navy,
        page: const ReadinessToolPage(),
      ),
      _ToolEntry(
        key: 'tool-emergency',
        icon: Icons.health_and_safety_rounded,
        title: 'Emergency help',
        subtitle: 'What to do if something goes wrong while travelling.',
        color: context.palette.danger,
        page: const EmergencyHelpPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Travel tools')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          const SectionHeader(
            title: 'Plan smarter',
            subtitle: 'Free planning helpers. Estimates are labelled as such.',
          ),
          const SizedBox(height: 14),
          for (final tool in tools) ...[
            _ToolCard(entry: tool),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ToolEntry {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;

  const _ToolEntry({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });
}

class _ToolCard extends StatelessWidget {
  final _ToolEntry entry;

  const _ToolCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key(entry.key),
        borderRadius: BorderRadius.circular(18),
        onTap: () => SafeNav.push(context, entry.page),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entry.icon, color: entry.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared scaffold for every tool screen: a title, a body and an optional
/// notice at the top.
class _ToolScaffold extends StatelessWidget {
  final String title;
  final String? notice;
  final List<Widget> children;

  const _ToolScaffold({
    required this.title,
    required this.children,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              if (notice != null) ...[
                DemoNotice(message: notice!),
                const SizedBox(height: 16),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    // Material (not a coloured Container) so list tiles and switches inside
    // the panel can draw their ink splashes.
    return Material(
      color: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _ResultRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      fontSize: strong ? 16 : 14,
      color: context.palette.text,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ============================================================
// CURRENCY
// ============================================================

class CurrencyToolPage extends StatefulWidget {
  const CurrencyToolPage({super.key});

  @override
  State<CurrencyToolPage> createState() => _CurrencyToolPageState();
}

class _CurrencyToolPageState extends State<CurrencyToolPage> {
  final _amount = TextEditingController(text: '100');
  String _from = 'USD';
  String _to = 'INR';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_amount.text.trim());
    final result = value == null
        ? null
        : CurrencyConverter.convert(amount: value, from: _from, to: _to);

    return _ToolScaffold(
      title: 'Currency converter',
      notice: CurrencyConverter.notice,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('currency-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CurrencyPicker(
                      label: 'From',
                      value: _from,
                      onChanged: (v) => setState(() => _from = v),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Swap currencies',
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: () => setState(() {
                      final t = _from;
                      _from = _to;
                      _to = t;
                    }),
                  ),
                  Expanded(
                    child: _CurrencyPicker(
                      label: 'To',
                      value: _to,
                      onChanged: (v) => setState(() => _to = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (result == null)
                Text(
                  'Enter an amount to convert.',
                  style: TextStyle(color: context.palette.muted),
                )
              else
                Text(
                  key: const Key('currency-result'),
                  '${value!.toStringAsFixed(2)} $_from ≈ '
                  '${result.toStringAsFixed(2)} $_to',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencyPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: [
            for (final code in CurrencyConverter.currencies)
              DropdownMenuItem(value: code, child: Text(code)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ============================================================
// LUGGAGE
// ============================================================

class LuggageToolPage extends StatefulWidget {
  const LuggageToolPage({super.key});

  @override
  State<LuggageToolPage> createState() => _LuggageToolPageState();
}

class _LuggageToolPageState extends State<LuggageToolPage> {
  final Map<String, int> _quantities = {};
  double _allowance = 15;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final item in LuggagePlan.suggestedItems)
        if ((_quantities[item.name] ?? 0) > 0)
          LuggageItem(
            name: item.name,
            kg: item.kg,
            quantity: _quantities[item.name]!,
          ),
    ];
    final plan = LuggagePlan(items: items, allowanceKg: _allowance);
    final progress = (plan.totalKg / _allowance).clamp(0.0, 1.0);

    return _ToolScaffold(
      title: 'Luggage planner',
      notice:
          'Weights are typical estimates. Check your airline or train operator '
          'for the exact allowance on your ticket.',
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check-in allowance',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kg in LuggagePlan.typicalAllowancesKg)
                    ChoiceChip(
                      label: Text('${kg.toStringAsFixed(0)} kg'),
                      selected: _allowance == kg,
                      onSelected: (_) => setState(() => _allowance = kg),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key: const Key('luggage-total'),
                '${plan.totalKg.toStringAsFixed(1)} kg of '
                '${_allowance.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: plan.isOverAllowance
                      ? context.palette.danger
                      : context.palette.green,
                  backgroundColor: context.palette.border,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.isOverAllowance
                    ? 'Over by ${(-plan.remainingKg).toStringAsFixed(1)} kg. '
                        'Remove something or pay for extra weight.'
                    : '${plan.remainingKg.toStringAsFixed(1)} kg left.',
                style: TextStyle(
                  color: plan.isOverAllowance
                      ? context.palette.danger
                      : context.palette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            children: [
              for (final item in LuggagePlan.suggestedItems)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.name}  (~${item.kg} kg)',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove ${item.name}',
                      onPressed: (_quantities[item.name] ?? 0) > 0
                          ? () => setState(
                                () => _quantities[item.name] =
                                    _quantities[item.name]! - 1,
                              )
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${_quantities[item.name] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Add ${item.name}',
                      onPressed: () => setState(
                        () => _quantities[item.name] =
                            (_quantities[item.name] ?? 0) + 1,
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BUDGET
// ============================================================

class BudgetToolPage extends StatefulWidget {
  const BudgetToolPage({super.key});

  @override
  State<BudgetToolPage> createState() => _BudgetToolPageState();
}

class _BudgetToolPageState extends State<BudgetToolPage> {
  final _days = TextEditingController(text: '4');
  final _travellers = TextEditingController(text: '1');
  String _tier = 'Moderate';

  @override
  void dispose() {
    _days.dispose();
    _travellers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = int.tryParse(_days.text.trim());
    final travellers = int.tryParse(_travellers.text.trim());
    final valid = days != null &&
        days >= 1 &&
        days <= 60 &&
        travellers != null &&
        travellers >= 1 &&
        travellers <= 20;
    final budget = valid
        ? BudgetEstimate.tiers[_tier]!.breakdown(
            days: days,
            travellers: travellers,
          )
        : null;

    return _ToolScaffold(
      title: 'Budget estimate',
      notice: BudgetEstimate.notice,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: [
                  for (final tier in BudgetEstimate.tiers.keys)
                    ButtonSegment(value: tier, label: Text(tier)),
                ],
                selected: {_tier},
                onSelectionChanged: (s) => setState(() => _tier = s.first),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('budget-days'),
                      controller: _days,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Days (1–60)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('budget-travellers'),
                      controller: _travellers,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Travellers (1–20)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!valid)
          _Panel(
            child: Text(
              'Enter between 1 and 60 days, and between 1 and 20 travellers.',
              style: TextStyle(color: context.palette.danger),
            ),
          )
        else
          _Panel(
            child: Column(
              children: [
                _ResultRow(
                  label: 'Stay (${max(days - 1, 0)} nights)',
                  value: formatRupees(budget!.stay),
                ),
                _ResultRow(label: 'Food', value: formatRupees(budget.food)),
                _ResultRow(
                  label: 'Local transport',
                  value: formatRupees(budget.transport),
                ),
                _ResultRow(
                  label: 'Activities',
                  value: formatRupees(budget.activities),
                ),
                _ResultRow(
                  label: 'Buffer (10%)',
                  value: formatRupees(budget.buffer),
                ),
                const Divider(height: 22),
                _ResultRow(
                  label: 'Estimated total',
                  value: formatRupees(budget.total),
                  strong: true,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// EXPENSE SPLITTER
// ============================================================

class _ExpenseEntry {
  final String description;
  final SharedExpense expense;

  const _ExpenseEntry({required this.description, required this.expense});
}

class ExpenseSplitPage extends StatefulWidget {
  const ExpenseSplitPage({super.key});

  @override
  State<ExpenseSplitPage> createState() => _ExpenseSplitPageState();
}

class _ExpenseSplitPageState extends State<ExpenseSplitPage> {
  final List<String> _people = ['You', 'Friend'];
  final List<_ExpenseEntry> _entries = [];
  final _newPerson = TextEditingController();

  @override
  void dispose() {
    _newPerson.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _newPerson.text.trim();
    if (name.isEmpty || _people.contains(name)) return;
    setState(() {
      _people.add(name);
      _newPerson.clear();
    });
  }

  Future<void> _addExpense() async {
    if (_people.length < 2) {
      showAppMessage(context, 'Add at least two people first.', error: true);
      return;
    }
    final entry = await showDialog<_ExpenseEntry>(
      context: context,
      builder: (_) => _ExpenseDialog(people: List.of(_people)),
    );
    if (entry != null) setState(() => _entries.add(entry));
  }

  @override
  Widget build(BuildContext context) {
    final expenses = [for (final e in _entries) e.expense];
    final balance = ExpenseSplitter.balances(expenses);
    final settlements = ExpenseSplitter.settlements(expenses);
    final total = expenses.fold<int>(0, (sum, e) => sum + e.amountCents);

    return _ToolScaffold(
      title: 'Split expenses',
      notice:
          'Expenses are kept on this screen only and are cleared when you leave. '
          'Tripora does not move money between people.',
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'People',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _people)
                    Chip(
                      label: Text(p),
                      onDeleted: _people.length > 2 &&
                              !_entries.any(
                                (e) =>
                                    e.expense.payer == p ||
                                    e.expense.participants.contains(p),
                              )
                          ? () => setState(() => _people.remove(p))
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newPerson,
                      decoration: const InputDecoration(labelText: 'Add a person'),
                      onSubmitted: (_) => _addPerson(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add person',
                    onPressed: _addPerson,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Expenses (${_entries.length}) · ${formatMoneyCents(total)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('split-add-expense'),
                    onPressed: _addExpense,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (_entries.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'No expenses yet.',
                    style: TextStyle(color: context.palette.muted),
                  ),
                )
              else
                for (var i = 0; i < _entries.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_entries[i].description),
                    subtitle: Text(
                      'Paid by ${_entries[i].expense.payer} · split between '
                      '${_entries[i].expense.participants.length}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMoneyCents(_entries[i].expense.amountCents),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          tooltip: 'Remove expense',
                          onPressed: () => setState(() => _entries.removeAt(i)),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Who pays whom',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (settlements.isEmpty)
                Text(
                  'Everyone is settled up.',
                  style: TextStyle(color: context.palette.muted),
                )
              else
                for (final s in settlements)
                  _ResultRow(
                    label: '${s.from} pays ${s.to}',
                    value: formatMoneyCents(s.amountCents),
                  ),
              const Divider(height: 22),
              for (final person in _people)
                _ResultRow(
                  label: person,
                  value: balance.containsKey(person)
                      ? (balance[person]! >= 0
                          ? 'is owed ${formatMoneyCents(balance[person]!)}'
                          : 'owes ${formatMoneyCents(-balance[person]!)}')
                      : 'settled',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseDialog extends StatefulWidget {
  final List<String> people;

  const _ExpenseDialog({required this.people});

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  late String _payer = widget.people.first;
  late final Set<String> _included = {...widget.people};
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final text = _description.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    if (text.isEmpty) {
      setState(() => _error = 'Describe the expense.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (_included.isEmpty) {
      setState(() => _error = 'Choose who shares this expense.');
      return;
    }
    Navigator.pop(
      context,
      _ExpenseEntry(
        description: text,
        expense: SharedExpense(
          payer: _payer,
          amountCents: (amount * 100).round(),
          participants: [
            for (final p in widget.people)
              if (_included.contains(p)) p,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'What was it for?'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Paid by'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _payer,
                  isExpanded: true,
                  items: [
                    for (final p in widget.people)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _payer = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            for (final p in widget.people)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Shared by $p'),
                value: _included.contains(p),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _included.add(p);
                  } else {
                    _included.remove(p);
                  }
                }),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _error!,
                  style: TextStyle(color: context.palette.danger),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

// ============================================================
// READINESS
// ============================================================

class ReadinessToolPage extends StatefulWidget {
  const ReadinessToolPage({super.key});

  @override
  State<ReadinessToolPage> createState() => _ReadinessToolPageState();
}

class _ReadinessToolPageState extends State<ReadinessToolPage> {
  final _done = TextEditingController(text: '0');
  final _total = TextEditingController(text: '7');
  bool _itinerary = false;
  bool _booking = false;

  @override
  void dispose() {
    _done.dispose();
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = int.tryParse(_total.text.trim()) ?? 0;
    final done = int.tryParse(_done.text.trim()) ?? 0;
    final safeTotal = min(max(total, 0), 500);
    final safeDone = min(max(done, 0), safeTotal);
    final readiness = TripReadiness.calculate(
      checklistDone: safeDone,
      checklistTotal: safeTotal,
      hasItinerary: _itinerary,
      hasBooking: _booking,
    );

    return _ToolScaffold(
      title: 'Trip readiness',
      notice:
          'Enter what you have done for your trip. Tripora does not read these '
          'answers from your saved trips yet.',
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score: ${readiness.score} / 100',
                key: const Key('readiness-score'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: readiness.score / 100,
                  minHeight: 10,
                  color: context.palette.green,
                  backgroundColor: context.palette.border,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _done,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Checklist items done',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _total,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Checklist items total',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I have saved a day-wise itinerary'),
                value: _itinerary,
                onChanged: (v) => setState(() => _itinerary = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I have requested a stay or travel service'),
                value: _booking,
                onChanged: (v) => setState(() => _booking = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Still to do',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (readiness.missing.isEmpty)
                Text(
                  'Nothing left. Have a great trip!',
                  style: TextStyle(color: context.palette.green),
                )
              else
                for (final item in readiness.missing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $item'),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COMPARE DESTINATIONS
// ============================================================

class CompareDestinationsPage extends StatefulWidget {
  const CompareDestinationsPage({super.key});

  @override
  State<CompareDestinationsPage> createState() =>
      _CompareDestinationsPageState();
}

class _CompareDestinationsPageState extends State<CompareDestinationsPage> {
  late String _leftId = DestinationCatalog.all.first.id;
  late String _rightId = DestinationCatalog.all.length > 1
      ? DestinationCatalog.all[1].id
      : DestinationCatalog.all.first.id;

  Destination _find(String id) =>
      DestinationCatalog.byId(id) ?? DestinationCatalog.all.first;

  @override
  Widget build(BuildContext context) {
    final left = _find(_leftId);
    final right = _find(_rightId);

    return _ToolScaffold(
      title: 'Compare destinations',
      notice:
          'Compares the details recorded in the Tripora catalogue. It does not '
          'include live prices, weather or availability.',
      children: [
        Row(
          children: [
            Expanded(child: _DestinationPicker(
              value: _leftId,
              onChanged: (v) => setState(() => _leftId = v),
            )),
            const SizedBox(width: 12),
            Expanded(child: _DestinationPicker(
              value: _rightId,
              onChanged: (v) => setState(() => _rightId = v),
            )),
          ],
        ),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            children: [
              _CompareRow(
                label: 'Location',
                left: left.location,
                right: right.location,
              ),
              _CompareRow(
                label: 'Best time',
                left: left.bestTime,
                right: right.bestTime,
              ),
              _CompareRow(
                label: 'Interests',
                left: left.categories.join(', '),
                right: right.categories.join(', '),
              ),
              _CompareRow(
                label: 'Highlights',
                left: left.highlights.take(3).join(', '),
                right: right.highlights.take(3).join(', '),
              ),
              _CompareRow(
                label: 'About',
                left: left.tagline,
                right: right.tagline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => SafeNav.push(
                  context,
                  DestinationDetailsScreen(destination: left),
                ),
                child: Text(left.name, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => SafeNav.push(
                  context,
                  DestinationDetailsScreen(destination: right),
                ),
                child: Text(right.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DestinationPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DestinationPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Destination'),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: [
            for (final d in DestinationCatalog.all)
              DropdownMenuItem(value: d.id, child: Text(d.name)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String left;
  final String right;

  const _CompareRow({
    required this.label,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                color: context.palette.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(child: Text(left, style: const TextStyle(height: 1.35))),
          const SizedBox(width: 12),
          Expanded(child: Text(right, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

// ============================================================
// SURPRISE ME
// ============================================================

class SurprisePage extends StatefulWidget {
  const SurprisePage({super.key});

  @override
  State<SurprisePage> createState() => _SurprisePageState();
}

class _SurprisePageState extends State<SurprisePage> {
  final _random = Random();
  String? _category;
  late Destination _pick = SurprisePicker.pick(random: _random);

  void _again() {
    setState(() {
      _pick = SurprisePicker.pick(
        random: _random,
        category: _category,
        avoid: _pick,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: 'Surprise me',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in [null, ...DestinationCatalog.categories])
              ChoiceChip(
                label: Text(c ?? 'Any'),
                selected: _category == c,
                onSelected: (_) {
                  setState(() => _category = c);
                  _again();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _pick.name,
                key: const Key('surprise-name'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _pick.location,
                style: TextStyle(color: context.palette.muted),
              ),
              const SizedBox(height: 10),
              Text(_pick.tagline, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _again,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Another'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => SafeNav.push(
                        context,
                        DestinationDetailsScreen(destination: _pick),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Open'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
