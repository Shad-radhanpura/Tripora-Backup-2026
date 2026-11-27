import 'package:flutter/material.dart';

import '../models/saved_trip.dart' show formatDate;
import '../services/app_firebase.dart';
import '../services/budget_store.dart';
import '../services/trip_budget_planner.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Trip Budget Planner: enter the trip, see an itemised estimate that updates as
/// you type, compare the three tiers, and log what you actually spend.
class TripBudgetPlannerPage extends StatefulWidget {
  const TripBudgetPlannerPage({super.key});

  @override
  State<TripBudgetPlannerPage> createState() => _TripBudgetPlannerPageState();
}

class _TripBudgetPlannerPageState extends State<TripBudgetPlannerPage> {
  final _store = BudgetStore.instance;
  final _outbound = TextEditingController(text: '0');
  final _returnFare = TextEditingController(text: '0');
  final _entry = TextEditingController(text: '0');
  final _shopping = TextEditingController(text: '0');
  final _insurance = TextEditingController(text: '0');
  final _misc = TextEditingController(text: '0');
  final _prepaid = TextEditingController(text: '0');

  DateTime? _start;
  DateTime? _end;
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;
  BudgetTier _tier = BudgetTier.moderate;
  TravelMode _mode = TravelMode.train;
  bool _loadedSaved = false;
  String? _savedNotice;

  String get _uid => AppFirebase.auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (!mounted) return;
      final saved = _store.planFor(_uid);
      if (saved != null) _applySaved(saved);
    });
    _start = DateTime.now().add(const Duration(days: 30));
    _end = _start!.add(const Duration(days: 3));
  }

  @override
  void dispose() {
    for (final c in [_outbound, _returnFare, _entry, _shopping, _insurance, _misc, _prepaid]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applySaved(PlanInputs p) {
    setState(() {
      _loadedSaved = true;
      _start = p.startDate;
      _end = p.endDate;
      _adults = p.adults;
      _children = p.children;
      _rooms = p.rooms;
      _tier = p.tier;
      _mode = p.mode;
      _outbound.text = '${p.outboundFarePerPerson}';
      _returnFare.text = '${p.returnFarePerPerson}';
      _entry.text = '${p.entryTicketsPerTraveller}';
      _shopping.text = '${p.shoppingPerAdult}';
      _insurance.text = '${p.insurancePerTraveller}';
      _misc.text = '${p.miscellaneousTotal}';
      _prepaid.text = '${p.prepaidTotal}';
    });
  }

  int? _money(TextEditingController c) => int.tryParse(c.text.trim());

  /// The inputs as entered, or the first problem found with them.
  ({PlanInputs? inputs, String? problem}) _current() {
    final money = <String, int?>{
      'Outbound fare': _money(_outbound),
      'Return fare': _money(_returnFare),
      'Entry tickets': _money(_entry),
      'Shopping': _money(_shopping),
      'Insurance': _money(_insurance),
      'Group costs': _money(_misc),
      'Already paid': _money(_prepaid),
    };
    for (final entry in money.entries) {
      if (entry.value == null) return (inputs: null, problem: '${entry.key}: enter a whole number.');
    }
    final problem = PlanInputs.validate(
      start: _start,
      end: _end,
      adults: _adults,
      children: _children,
      rooms: _rooms,
      money: {for (final e in money.entries) e.key: e.value!},
    );
    if (problem != null) return (inputs: null, problem: problem);
    return (
      inputs: PlanInputs(
        startDate: _start!,
        endDate: _end!,
        adults: _adults,
        children: _children,
        rooms: _rooms,
        tier: _tier,
        mode: _mode,
        outboundFarePerPerson: money['Outbound fare']!,
        returnFarePerPerson: money['Return fare']!,
        entryTicketsPerTraveller: money['Entry tickets']!,
        shoppingPerAdult: money['Shopping']!,
        insurancePerTraveller: money['Insurance']!,
        miscellaneousTotal: money['Group costs']!,
        prepaidTotal: money['Already paid']!,
      ),
      problem: null,
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = (start ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
      helpText: start ? 'Trip starts' : 'Trip ends',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _savePlan() async {
    final result = _current();
    if (result.inputs == null) {
      showAppMessage(context, result.problem ?? 'Check the highlighted values.', error: true);
      return;
    }
    if (_uid.isEmpty) {
      showAppMessage(context, 'Sign in to save your plan.', error: true);
      return;
    }
    try {
      await _store.savePlan(_uid, result.inputs!);
      if (!mounted) return;
      setState(() => _savedNotice = 'Plan saved on this device.');
      showAppMessage(context, 'Plan saved on this device.');
    } catch (e) {
      if (mounted) showAppMessage(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final result = _current();
    final inputs = result.inputs;
    final estimate = inputs == null ? null : BudgetPlanResult.calculate(inputs);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Trip budget planner')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              if (_loadedSaved)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Your saved plan is loaded. Change anything to recalculate.',
                    style: TextStyle(color: palette.muted, fontSize: 12.5),
                  ),
                ),
              _section('Your trip', [
                Row(
                  children: [
                    Expanded(child: _dateButton('Start', _start, () => _pickDate(start: true), 'budget-start')),
                    const SizedBox(width: 10),
                    Expanded(child: _dateButton('End', _end, () => _pickDate(start: false), 'budget-end')),
                  ],
                ),
                const SizedBox(height: 10),
                _stepper('Adults', _adults, 1, 9, 'budget-adults', (v) => setState(() => _adults = v)),
                _stepper('Children (under 12)', _children, 0, 9, 'budget-children', (v) => setState(() => _children = v)),
                _stepper('Rooms', _rooms, 1, 12, 'budget-rooms', (v) => setState(() => _rooms = v)),
                const SizedBox(height: 8),
                SegmentedButton<BudgetTier>(
                  key: const Key('budget-tier'),
                  segments: [
                    for (final t in BudgetTier.values)
                      ButtonSegment(value: t, label: Text(t.label)),
                  ],
                  selected: {_tier},
                  onSelectionChanged: (s) => setState(() => _tier = s.first),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TravelMode>(
                  key: const Key('budget-mode'),
                  initialValue: _mode,
                  decoration: const InputDecoration(labelText: 'How you travel'),
                  items: [
                    for (final m in TravelMode.values)
                      DropdownMenuItem(value: m, child: Text(m.label)),
                  ],
                  onChanged: (v) => setState(() => _mode = v ?? _mode),
                ),
              ]),
              _section('Costs you know or have chosen (₹)', [
                _moneyField('Outbound fare, per person', _outbound, 'budget-outbound'),
                _moneyField('Return fare, per person', _returnFare, 'budget-return'),
                _moneyField('Entry tickets, per traveller (whole trip)', _entry, 'budget-entry'),
                _moneyField('Shopping and personal, per adult (whole trip)', _shopping, 'budget-shopping'),
                _moneyField('Travel insurance, per traveller', _insurance, 'budget-insurance'),
                _moneyField('Other group costs (whole trip)', _misc, 'budget-misc'),
                _moneyField('Already paid or booked before the trip', _prepaid, 'budget-prepaid'),
              ]),
              if (result.problem != null)
                Container(
                  key: const Key('budget-problem'),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(result.problem!, style: TextStyle(color: palette.danger)),
                ),
              if (estimate != null && inputs != null) ...[
                _EstimateCard(estimate: estimate, inputs: inputs),
                const SizedBox(height: 16),
                _ComparisonCard(inputs: inputs),
                const SizedBox(height: 16),
                _ChartCard(estimate: estimate),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('budget-save-plan'),
                  onPressed: _savePlan,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save this plan on this device'),
                ),
                if (_savedNotice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_savedNotice!, style: TextStyle(color: palette.muted, fontSize: 12)),
                  ),
                const SizedBox(height: 22),
                _ExpenseSection(estimate: estimate),
              ],
              const SizedBox(height: 16),
              Text(
                BudgetPlanResult.notice,
                style: TextStyle(color: palette.muted, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(color: palette.navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap, String key) {
    return OutlinedButton.icon(
      key: Key(key),
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_rounded, size: 18),
      label: Text(value == null ? '$label date' : '$label: ${formatDate(value)}', overflow: TextOverflow.ellipsis),
    );
  }

  Widget _stepper(String label, int value, int min, int max, String key, ValueChanged<int> onChanged) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: palette.text))),
          IconButton(
            tooltip: 'Less',
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 28,
            child: Text('$value', key: Key(key), textAlign: TextAlign.center,
                style: TextStyle(color: palette.text, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _moneyField(String label, TextEditingController controller, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        key: Key(key),
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label, prefixText: '₹ ', errorText: _money(controller) == null ? 'Whole number only' : null),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final BudgetPlanResult estimate;
  final PlanInputs inputs;

  const _EstimateCard({required this.estimate, required this.inputs});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('budget-estimate'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${estimate.tier.label} estimate · ${inputs.days} days, ${inputs.nights} nights',
                  style: TextStyle(color: palette.text, fontWeight: FontWeight.w900),
                ),
              ),
              TagChip(label: 'ESTIMATE', color: palette.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _big(context, 'Total', '₹${_fmt(estimate.total)}')),
              Expanded(child: _big(context, 'Per person', '₹${_fmt(estimate.perPerson)}')),
              Expanded(child: _big(context, 'Still to pay', '₹${_fmt(estimate.stillToPay)}')),
            ],
          ),
          const Divider(height: 26),
          for (final line in estimate.lines)
            if (line.amount > 0 || line.category == 'stay')
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(budgetCategoryLabels[line.category] ?? line.category,
                              style: TextStyle(color: palette.text, fontWeight: FontWeight.w700)),
                          Text(line.basis, style: TextStyle(color: palette.muted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Text('₹${_fmt(line.amount)}', style: TextStyle(color: palette.text, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          _row(context, 'Contingency (10%)', '₹${_fmt(estimate.contingency)}'),
          if (estimate.prepaid > 0) _row(context, 'Already paid', '− ₹${_fmt(estimate.prepaid)}'),
          const SizedBox(height: 6),
          Text(
            'Taxes, booking fees and any fare or price not entered above are not included.',
            style: TextStyle(color: palette.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _big(BuildContext context, String label, String value) {
    final palette = context.palette;
    return Column(
      children: [
        Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: palette.blue, fontWeight: FontWeight.w900, fontSize: 17)),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: palette.text))),
          Text(value, style: TextStyle(color: palette.text, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final PlanInputs inputs;

  const _ComparisonCard({required this.inputs});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compare the three levels', style: TextStyle(color: palette.text, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final tier in BudgetTier.values) ...[
                Expanded(
                  child: _TierTile(
                    key: Key('compare-${tier.name}'),
                    estimate: BudgetPlanResult.calculate(inputs, tier: tier),
                    selected: tier == inputs.tier,
                  ),
                ),
                if (tier != BudgetTier.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final BudgetPlanResult estimate;
  final bool selected;

  const _TierTile({super.key, required this.estimate, required this.selected});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? palette.surfaceTint : palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? palette.blue : palette.border, width: selected ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Text(estimate.tier.label, style: TextStyle(color: palette.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('₹${_fmt(estimate.total)}', style: TextStyle(color: palette.blue, fontWeight: FontWeight.w900)),
          Text('₹${_fmt(estimate.perPerson)} each', style: TextStyle(color: palette.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final BudgetPlanResult estimate;

  const _ChartCard({required this.estimate});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shown = estimate.lines.where((l) => l.amount > 0).toList();
    final largest = shown.fold(0, (m, l) => l.amount > m ? l.amount : m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where the money goes', style: TextStyle(color: palette.text, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            Text('Nothing to chart yet.', style: TextStyle(color: palette.muted))
          else
            for (final line in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(budgetCategoryLabels[line.category] ?? line.category,
                          style: TextStyle(color: palette.text, fontSize: 12)),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => Stack(
                          children: [
                            Container(height: 12, decoration: BoxDecoration(color: palette.surfaceTint, borderRadius: BorderRadius.circular(6))),
                            Container(
                              height: 12,
                              width: largest == 0 ? 0 : box.maxWidth * line.amount / largest,
                              decoration: BoxDecoration(color: palette.blue, borderRadius: BorderRadius.circular(6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('₹${_fmt(line.amount)}', style: TextStyle(color: palette.muted, fontSize: 11.5)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Planned versus actual spending for each category, and the expense log.
class _ExpenseSection extends StatefulWidget {
  final BudgetPlanResult estimate;

  const _ExpenseSection({required this.estimate});

  @override
  State<_ExpenseSection> createState() => _ExpenseSectionState();
}

class _ExpenseSectionState extends State<_ExpenseSection> {
  final _store = BudgetStore.instance;

  String get _uid => AppFirebase.auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _openForm({BudgetExpense? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExpenseForm(existing: existing),
    );
  }

  Future<void> _delete(BudgetExpense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: Text('₹${e.amount} · ${budgetCategoryLabels[e.category] ?? e.category}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep it')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _store.deleteExpense(uid: _uid, id: e.id);
    } catch (err) {
      if (mounted) showAppMessage(context, '$err', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        if (_uid.isEmpty) {
          return const EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to log expenses',
            message: 'Expense records are linked to your account.',
          );
        }
        if (!_store.isLoaded) return const LoadingState(message: 'Loading expenses…');
        if (_store.readFailed) {
          return const EmptyState(
            icon: Icons.lock_clock_outlined,
            title: 'Saved expenses could not be read',
            message: 'New expenses are blocked so saved records are not overwritten.',
          );
        }
        final expenses = _store.expensesFor(_uid);
        final actualByCategory = <String, int>{};
        for (final e in expenses) {
          actualByCategory[e.category] = (actualByCategory[e.category] ?? 0) + e.amount;
        }
        final spent = actualByCategory.values.fold(0, (s, v) => s + v);
        final remaining = widget.estimate.total - spent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Planned versus actual', style: TextStyle(color: palette.text, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Estimate: ₹${_fmt(widget.estimate.total)}', style: TextStyle(color: palette.text))),
                      Expanded(child: Text('Spent: ₹${_fmt(spent)}', style: TextStyle(color: palette.text))),
                      Expanded(
                        child: Text(
                          remaining >= 0 ? 'Left: ₹${_fmt(remaining)}' : 'Over by ₹${_fmt(-remaining)}',
                          key: const Key('budget-remaining'),
                          style: TextStyle(
                            color: remaining >= 0 ? palette.green : palette.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  for (final line in widget.estimate.lines.where((l) => l.amount > 0 || (actualByCategory[l.category] ?? 0) > 0))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(budgetCategoryLabels[line.category] ?? line.category,
                                style: TextStyle(color: palette.text, fontSize: 12.5)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Plan ₹${_fmt(line.amount)}', style: TextStyle(color: palette.muted, fontSize: 12)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Actual ₹${_fmt(actualByCategory[line.category] ?? 0)}',
                                style: TextStyle(color: palette.text, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Expenses (${expenses.length})',
                      style: TextStyle(color: palette.text, fontWeight: FontWeight.w900)),
                ),
                FilledButton.icon(
                  key: const Key('budget-add-expense'),
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add expense'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (expenses.isEmpty)
              Text('No expenses logged yet. Add one as you spend.', style: TextStyle(color: palette.muted))
            else
              for (final e in expenses)
                Container(
                  key: Key('expense-${e.id}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${_fmt(e.amount)} · ${budgetCategoryLabels[e.category] ?? e.category}',
                                style: TextStyle(color: palette.text, fontWeight: FontWeight.w800)),
                            Text(
                              '${formatDate(e.date)} · ${paymentMethodLabels[e.paymentMethod] ?? 'Other'}'
                              '${e.note.isEmpty ? '' : ' · ${e.note}'}',
                              style: TextStyle(color: palette.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit expense',
                        onPressed: () => _openForm(existing: e),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: 'Delete expense',
                        onPressed: () => _delete(e),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final BudgetExpense? existing;

  const _ExpenseForm({this.existing});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: widget.existing == null ? '' : '${widget.existing!.amount}');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late String _category = widget.existing?.category ?? 'food';
  late String _payment = widget.existing?.paymentMethod ?? 'upi';
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final uid = AppFirebase.auth.currentUser?.uid ?? '';
    final amount = int.parse(_amount.text.trim());
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await BudgetStore.instance.addExpense(
          uid: uid,
          amount: amount,
          category: _category,
          date: _date,
          note: _note.text,
          paymentMethod: _payment,
        );
      } else {
        await BudgetStore.instance.updateExpense(
          uid: uid,
          id: widget.existing!.id,
          amount: amount,
          category: _category,
          date: _date,
          note: _note.text,
          paymentMethod: _payment,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      showAppMessage(context, widget.existing == null ? 'Expense saved on this device.' : 'Expense updated.');
    } on ArgumentError catch (e) {
      if (mounted) showAppMessage(context, '${e.message}', error: true);
    } catch (e) {
      if (mounted) showAppMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.existing == null ? 'Add expense' : 'Edit expense',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('expense-amount'),
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null) return 'Enter a whole number.';
                    if (n <= 0) return 'Enter an amount above zero.';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('expense-category'),
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final e in budgetCategoryLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('expense-payment'),
                  initialValue: _payment,
                  decoration: const InputDecoration(labelText: 'Payment method'),
                  items: [
                    for (final e in paymentMethodLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _payment = v ?? _payment),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(DateTime.now().year - 2),
                      lastDate: DateTime(DateTime.now().year + 3),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(formatDate(_date)),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('expense-note'),
                  controller: _note,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('expense-save'),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _fmt(int amount) => _indian(amount);

/// Indian digit grouping, for example 1,49,999.
String _indian(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  if (digits.length <= 3) return '${negative ? '-' : ''}$digits';
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${negative ? '-' : ''}${groups.join(',')},$last3';
}
