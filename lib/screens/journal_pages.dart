import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/saved_trip.dart' show formatDate;
import '../services/app_firebase.dart';
import '../services/journal_store.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'journal_editor_page.dart';

/// Whether the entry's journey touches [day]. A single-date entry counts only
/// on that date; a journey with an end date counts on every day in between.
bool journalCoversDay(JournalEntry entry, DateTime day) {
  final start = entry.tripDate;
  if (start == null) return false;
  final end = entry.endDate ?? start;
  final d = DateTime(day.year, day.month, day.day);
  return !d.isBefore(start) && !d.isAfter(end);
}

/// The list of the signed-in person's journal entries, with search and a date
/// range filter.
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _store = JournalStore.instance;
  final _search = TextEditingController();
  String _query = '';
  DateTime? _from;
  DateTime? _to;

  String get _uid => AppFirebase.auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(JournalEntry e) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final haystack = [
        e.title, e.place, e.city, e.state, e.description, e.notes, e.companions,
      ].join(' ').toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    final date = e.calendarDate;
    if (_from != null || _to != null) {
      if (date == null) return false;
      if (_from != null && date.isBefore(_from!)) return false;
      if (_to != null && date.isAfter(_to!)) return false;
    }
    return true;
  }

  Future<void> _pick({required bool from}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: from ? 'Trips from' : 'Trips until',
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) _from = picked;
      }
    });
  }

  void _openNew() => SafeNav.push(context, const JournalEditorPage());

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('My travel journal'),
        actions: [
          IconButton(
            key: const Key('journal-calendar'),
            tooltip: 'Travel calendar',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => SafeNav.push(context, const JournalCalendarPage()),
          ),
        ],
      ),
      floatingActionButton: _uid.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('journal-new'),
              onPressed: _openNew,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('New entry'),
            ),
      body: _uid.isEmpty
          ? const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to keep a journal',
              message: 'Journal entries are private and linked to your account.',
            )
          : ListenableBuilder(
              listenable: _store,
              builder: (context, _) {
                if (!_store.isLoaded) {
                  return const LoadingState(message: 'Loading your journal…');
                }
                if (_store.readFailed) {
                  return const EmptyState(
                    icon: Icons.lock_clock_outlined,
                    title: 'Saved entries could not be read',
                    message: 'New changes are blocked so saved entries are not '
                        'overwritten. Restart the app to try again.',
                  );
                }
                final all = _store.forUser(_uid);
                final visible = all.where(_matches).toList();
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                      children: [
                        TextField(
                          key: const Key('journal-search'),
                          controller: _search,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Search title, place, notes…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () => setState(() {
                                      _search.clear();
                                      _query = '';
                                    }),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ActionChip(
                              key: const Key('journal-filter-from'),
                              avatar: const Icon(Icons.event_rounded, size: 18),
                              label: Text(_from == null ? 'From date' : 'From ${formatDate(_from)}'),
                              onPressed: () => _pick(from: true),
                            ),
                            ActionChip(
                              key: const Key('journal-filter-to'),
                              avatar: const Icon(Icons.event_rounded, size: 18),
                              label: Text(_to == null ? 'To date' : 'To ${formatDate(_to)}'),
                              onPressed: () => _pick(from: false),
                            ),
                            if (_from != null || _to != null || _query.isNotEmpty)
                              TextButton(
                                key: const Key('journal-clear-filters'),
                                onPressed: () => setState(() {
                                  _from = null;
                                  _to = null;
                                  _search.clear();
                                  _query = '';
                                }),
                                child: const Text('Clear filters'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (all.isEmpty)
                          EmptyState(
                            icon: Icons.menu_book_rounded,
                            title: 'Your journal is empty',
                            message: 'Write about a journey: where you went, what stood out, '
                                'and what it cost. Entries stay private to you.',
                            actionLabel: 'Write your first entry',
                            onAction: _openNew,
                          )
                        else if (visible.isEmpty)
                          const EmptyState(
                            icon: Icons.filter_alt_off_rounded,
                            title: 'No entries match',
                            message: 'Try a different search or date range.',
                          )
                        else
                          for (final entry in visible) ...[
                            _JournalCard(entry: entry),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;

  const _JournalCard({required this.entry});

  String get _when {
    final start = entry.tripDate;
    if (start == null) return 'No trip date set';
    if (entry.endDate == null || entry.endDate == start) return formatDate(start);
    return '${formatDate(start)} – ${formatDate(entry.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final where = [entry.place, entry.city, entry.state].where((s) => s.isNotEmpty).join(', ');
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('journal-card-${entry.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => SafeNav.push(context, JournalDetailPage(entryId: entry.id)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: TextStyle(color: palette.text, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(where, style: TextStyle(color: palette.muted, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: palette.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_when, style: TextStyle(color: palette.text, fontSize: 12.5)),
                  ),
                ],
              ),
              if (entry.expenses.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Expenses noted: ₹${entry.expenseTotal}',
                  style: TextStyle(color: palette.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reading layout for one entry, with edit and delete for its owner.
class JournalDetailPage extends StatelessWidget {
  final String entryId;

  const JournalDetailPage({super.key, required this.entryId});

  Future<void> _delete(BuildContext context, JournalEntry entry) async {
    final uid = AppFirebase.auth.currentUser?.uid ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this journal entry?'),
        content: const Text('It will be removed from this device. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const Key('journal-delete-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await JournalStore.instance.delete(uid: uid, id: entry.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      showAppMessage(context, 'Journal entry deleted.');
    } catch (e) {
      if (context.mounted) showAppMessage(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: JournalStore.instance,
      builder: (context, _) {
        final entry = JournalStore.instance.byId(entryId);
        final uid = AppFirebase.auth.currentUser?.uid ?? '';
        if (entry == null || !entry.isOwnedBy(uid)) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Entry not found',
              message: 'This journal entry is not on this device for your account.',
            ),
          );
        }
        final start = entry.tripDate;
        final dates = start == null
            ? 'No trip date set'
            : (entry.endDate == null || entry.endDate == start)
                ? formatDate(start)
                : '${formatDate(start)} – ${formatDate(entry.endDate)}';
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: const Text('Journal entry'),
            actions: [
              IconButton(
                key: const Key('journal-edit'),
                tooltip: 'Edit entry',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => SafeNav.push(context, JournalEditorPage(existing: entry)),
              ),
              IconButton(
                key: const Key('journal-delete'),
                tooltip: 'Delete entry',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _delete(context, entry),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(color: palette.text, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [entry.place, entry.city, entry.state].where((s) => s.isNotEmpty).join(' · '),
                    style: TextStyle(color: palette.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(dates, style: TextStyle(color: palette.blue, fontWeight: FontWeight.w700)),
                  if (entry.companions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('With: ${entry.companions}', style: TextStyle(color: palette.muted, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  if (entry.description.isNotEmpty) _Block('The journey', entry.description),
                  if (entry.highlights.isNotEmpty) _Block('Highlights', entry.highlights.map((h) => '• $h').join('\n')),
                  if (entry.placesVisited.isNotEmpty) _Block('Places visited', entry.placesVisited.map((p) => '• $p').join('\n')),
                  if (entry.notes.isNotEmpty) _Block('Personal notes', entry.notes),
                  if (entry.expenses.isNotEmpty)
                    _Block(
                      'Expenses noted',
                      [
                        for (final e in entry.expenses) '${e.label}: ₹${e.amount}',
                        'Total: ₹${entry.expenseTotal}',
                      ].join('\n'),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'Created ${formatDate(entry.createdAt)} · Last updated ${formatDate(entry.updatedAt)}',
                    style: TextStyle(color: palette.muted, fontSize: 12),
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

class _Block extends StatelessWidget {
  final String title;
  final String body;

  const _Block(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: palette.navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: palette.text, height: 1.5)),
        ],
      ),
    );
  }
}

/// Month view of journal entries. Selecting a day lists the entries that cover
/// it. Entries without a trip date are listed separately.
class JournalCalendarPage extends StatefulWidget {
  const JournalCalendarPage({super.key});

  @override
  State<JournalCalendarPage> createState() => _JournalCalendarPageState();
}

class _JournalCalendarPageState extends State<JournalCalendarPage> {
  final _store = JournalStore.instance;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  String get _uid => AppFirebase.auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  void _shift(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months);
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Travel calendar')),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (_uid.isEmpty) {
            return const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to see your calendar',
              message: 'Your journal dates are linked to your account.',
            );
          }
          if (!_store.isLoaded) {
            return const LoadingState(message: 'Loading your calendar…');
          }
          final entries = _store.forUser(_uid);
          final undated = entries.where((e) => e.tripDate == null).toList();
          final selected = _selected;
          final onDay = selected == null
              ? const <JournalEntry>[]
              : entries.where((e) => journalCoversDay(e, selected)).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('calendar-prev'),
                        tooltip: 'Previous month',
                        onPressed: () => _shift(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          '${_monthNames[_month.month - 1]} ${_month.year}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.text, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton(
                        key: const Key('calendar-next'),
                        tooltip: 'Next month',
                        onPressed: () => _shift(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  _MonthGrid(
                    month: _month,
                    selected: selected,
                    entries: entries,
                    onSelect: (day) => setState(() => _selected = day),
                  ),
                  const SizedBox(height: 16),
                  if (selected == null)
                    Text(
                      entries.isEmpty
                          ? 'Journal entries with a trip date appear on the calendar.'
                          : 'Select a day to see its journal entries.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.muted),
                    )
                  else ...[
                    Text(
                      formatDate(selected),
                      style: TextStyle(color: palette.text, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    if (onDay.isEmpty)
                      Text('No journal entries on this day.', style: TextStyle(color: palette.muted))
                    else
                      for (final e in onDay) ...[
                        _JournalCard(entry: e),
                        const SizedBox(height: 10),
                      ],
                  ],
                  if (undated.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Entries without a trip date (${undated.length})',
                      style: TextStyle(color: palette.text, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    for (final e in undated) ...[
                      _JournalCard(entry: e),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final List<JournalEntry> entries;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.entries,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Weeks start on Monday, so the first column is Monday.
    final leading = first.weekday - 1;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();

    final cells = <Widget>[
      for (final d in weekdays)
        Center(
          child: Text(d, style: TextStyle(color: palette.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _dayCell(context, DateTime(month.year, month.month, day), today),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  Widget _dayCell(BuildContext context, DateTime day, DateTime today) {
    final palette = context.palette;
    final count = entries.where((e) => journalCoversDay(e, day)).length;
    final isSelected = selected != null &&
        selected!.year == day.year &&
        selected!.month == day.month &&
        selected!.day == day.day;
    final isToday = today.year == day.year && today.month == day.month && today.day == day.day;
    return InkWell(
      key: Key('calendar-day-${day.day}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSelect(day),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? palette.blue
              : count > 0
                  ? palette.surfaceTint
                  : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? palette.coral : palette.border,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : palette.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            if (count > 0)
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : palette.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
