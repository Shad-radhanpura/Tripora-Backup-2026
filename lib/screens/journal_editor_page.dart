import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/saved_trip.dart' show formatDate;
import '../services/app_firebase.dart';
import '../services/journal_store.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Structured editor for a journal entry. Returns the saved entry to the
/// previous screen, or nothing when cancelled.
class JournalEditorPage extends StatefulWidget {
  final JournalEntry? existing;

  const JournalEditorPage({super.key, this.existing});

  @override
  State<JournalEditorPage> createState() => _JournalEditorPageState();
}

class _ExpenseRow {
  final TextEditingController label;
  final TextEditingController amount;

  _ExpenseRow(String labelText, String amountText)
    : label = TextEditingController(text: labelText),
      amount = TextEditingController(text: amountText);

  void dispose() {
    label.dispose();
    amount.dispose();
  }
}

class _JournalEditorPageState extends State<JournalEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _store = JournalStore.instance;

  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _place = TextEditingController(text: widget.existing?.place ?? '');
  late final _city = TextEditingController(text: widget.existing?.city ?? '');
  late final _state = TextEditingController(text: widget.existing?.state ?? '');
  late final _companions = TextEditingController(text: widget.existing?.companions ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late final _highlights = TextEditingController(
    text: widget.existing?.highlights.join('\n') ?? '',
  );
  late final _visited = TextEditingController(
    text: widget.existing?.placesVisited.join('\n') ?? '',
  );
  late final List<_ExpenseRow> _expenses = [
    for (final e in widget.existing?.expenses ?? const <JournalExpense>[])
      _ExpenseRow(e.label, '${e.amount}'),
  ];

  late DateTime? _start = widget.existing?.tripDate;
  late DateTime? _end = widget.existing?.endDate;
  bool _saving = false;
  String? _dateError;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final c in [
      _title, _place, _city, _state, _companions, _description, _notes, _highlights, _visited,
    ]) {
      c.dispose();
    }
    for (final row in _expenses) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final today = DateTime.now();
    final initial = (start ? _start : _end) ?? _start ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 5),
      helpText: start ? 'Start date' : 'End date',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _dateError = JournalRules.validateDates(start: _start, end: _end);
    });
  }

  String? _amountProblem(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter an amount.';
    final number = int.tryParse(text);
    if (number == null || number < 0) return 'Use a whole number, zero or more.';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    final dateProblem = JournalRules.validateDates(start: _start, end: _end);
    setState(() => _dateError = dateProblem);
    if (!formValid || dateProblem != null) return;

    final uid = AppFirebase.auth.currentUser?.uid ?? '';
    final expenses = [
      for (final row in _expenses)
        if (row.label.text.trim().isNotEmpty || row.amount.text.trim().isNotEmpty)
          JournalExpense(label: row.label.text.trim(), amount: int.parse(row.amount.text.trim())),
    ];

    setState(() => _saving = true);
    try {
      final JournalEntry saved;
      if (_editing) {
        saved = await _store.update(
          uid: uid,
          id: widget.existing!.id,
          title: _title.text,
          place: _place.text,
          city: _city.text,
          state: _state.text,
          tripDate: _start,
          endDate: _end,
          companions: _companions.text,
          description: _description.text,
          notes: _notes.text,
          highlights: JournalRules.cleanList(_highlights.text),
          placesVisited: JournalRules.cleanList(_visited.text),
          expenses: expenses,
        );
      } else {
        saved = await _store.create(
          uid: uid,
          title: _title.text,
          place: _place.text,
          city: _city.text,
          state: _state.text,
          tripDate: _start,
          endDate: _end,
          companions: _companions.text,
          description: _description.text,
          notes: _notes.text,
          highlights: JournalRules.cleanList(_highlights.text),
          placesVisited: JournalRules.cleanList(_visited.text),
          expenses: expenses,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
      showAppMessage(
        context,
        _editing ? 'Journal entry updated on this device.' : 'Journal entry saved on this device.',
      );
    } on ArgumentError catch (e) {
      if (mounted) showAppMessage(context, '${e.message}', error: true);
    } catch (e) {
      if (mounted) showAppMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dateField({required String label, required DateTime? value, required bool start}) {
    final palette = context.palette;
    return Expanded(
      child: OutlinedButton.icon(
        key: Key(start ? 'journal-start' : 'journal-end'),
        onPressed: () => _pickDate(start: start),
        icon: const Icon(Icons.calendar_today_rounded, size: 18),
        label: Text(
          value == null ? label : formatDate(value),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: palette.text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(_editing ? 'Edit journal entry' : 'New journal entry')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                const _Heading('About this journey'),
                TextFormField(
                  key: const Key('journal-title'),
                  controller: _title,
                  maxLength: JournalRules.titleMax,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'For example: Monsoon week in Kerala',
                  ),
                  validator: JournalRules.validateTitle,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('journal-place'),
                  controller: _place,
                  decoration: const InputDecoration(labelText: 'Place visited'),
                  validator: JournalRules.validatePlace,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(labelText: 'City (optional)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _state,
                        decoration: const InputDecoration(labelText: 'State (optional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _Heading('Dates'),
                Row(
                  children: [
                    _dateField(label: 'Start date', value: _start, start: true),
                    const SizedBox(width: 10),
                    _dateField(label: 'End date', value: _end, start: false),
                  ],
                ),
                if (_start != null || _end != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('journal-clear-dates'),
                      onPressed: () => setState(() {
                        _start = null;
                        _end = null;
                        _dateError = null;
                      }),
                      child: const Text('Clear dates'),
                    ),
                  ),
                if (_dateError != null)
                  Text(_dateError!, style: TextStyle(color: palette.danger, fontSize: 12.5)),
                const SizedBox(height: 16),
                const _Heading('Your journey'),
                TextFormField(
                  controller: _companions,
                  decoration: const InputDecoration(
                    labelText: 'Travel companions (optional)',
                    helperText: 'Only you can see this entry.',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('journal-description'),
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: JournalRules.textMax,
                  decoration: const InputDecoration(
                    labelText: 'Journey description',
                    alignLabelWithHint: true,
                  ),
                  validator: JournalRules.validateText,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: JournalRules.textMax,
                  decoration: const InputDecoration(
                    labelText: 'Personal notes',
                    alignLabelWithHint: true,
                  ),
                  validator: JournalRules.validateText,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _highlights,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Highlights and memorable experiences',
                    helperText: 'One per line, up to ${JournalRules.listMax}.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => JournalRules.validateList(
                    JournalRules.cleanList(v ?? ''),
                    'highlights',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _visited,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Places visited',
                    helperText: 'One per line, up to ${JournalRules.listMax}.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => JournalRules.validateList(
                    JournalRules.cleanList(v ?? ''),
                    'places visited',
                  ),
                ),
                const SizedBox(height: 16),
                const _Heading('Expenses (optional)'),
                for (var i = 0; i < _expenses.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            key: Key('expense-label-$i'),
                            controller: _expenses[i].label,
                            decoration: const InputDecoration(labelText: 'Item'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: Key('expense-amount-$i'),
                            controller: _expenses[i].amount,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Amount (₹)'),
                            validator: (v) => (_expenses[i].label.text.trim().isEmpty && (v ?? '').trim().isEmpty)
                                ? null
                                : _amountProblem(v),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove expense',
                          onPressed: () => setState(() {
                            _expenses.removeAt(i).dispose();
                          }),
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                if (_expenses.length < JournalRules.expenseMax)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('journal-add-expense'),
                      onPressed: () => setState(() => _expenses.add(_ExpenseRow('', ''))),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add an expense'),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('journal-save'),
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving…' : 'Save entry'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Journal entries are saved on this device only. They are not synced to the cloud.',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.navy,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
