import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/saved_trip.dart' show formatDate;
import '../models/support_ticket.dart';
import '../services/app_firebase.dart';
import '../services/support_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Admin: Feedback & issues. Filter by category, priority and status, open a
/// report, see who sent it, change its status and reply. Every change is
/// recorded in the audit log.
class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> {
  final _stream = SupportService.allTickets();
  String? _status;
  String? _category;
  String? _priority;

  bool _matches(SupportTicket t) =>
      (_status == null || t.status == _status) &&
      (_category == null || t.category == _category) &&
      (_priority == null || t.priority == _priority);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Feedback & issues')),
      body: StreamBuilder<List<SupportTicket>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              error: snapshot.error,
              title: 'Could not load support tickets',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingState(message: 'Loading feedback…');
          }
          final all = snapshot.data!;
          final visible = all.where(_matches).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in [null, ...SupportStatus.all])
                        ChoiceChip(
                          key: Key('support-filter-${f ?? 'all'}'),
                          label: Text(
                            f == null
                                ? 'All (${all.length})'
                                : '${SupportStatus.label(f)} '
                                    '(${all.where((t) => t.status == f).length})',
                          ),
                          selected: _status == f,
                          onSelected: (_) => setState(() => _status = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _FilterDropdown(
                        key: const Key('support-filter-category'),
                        label: 'Category',
                        value: _category,
                        options: {
                          for (final c in [...SupportCategory.all, ...SupportCategory.legacy])
                            c: SupportCategory.label(c),
                        },
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      _FilterDropdown(
                        key: const Key('support-filter-priority'),
                        label: 'Priority',
                        value: _priority,
                        options: {
                          for (final p in SupportPriority.all) p: SupportPriority.label(p),
                        },
                        onChanged: (v) => setState(() => _priority = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (all.isEmpty)
                    const EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No support requests',
                      message: 'Feedback and requests from travellers appear here.',
                    )
                  else if (visible.isEmpty)
                    const EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Nothing in this filter',
                      message: 'Choose another status, category or priority.',
                    )
                  else
                    for (final ticket in visible) ...[
                      _AdminTicketTile(ticket: ticket),
                      const SizedBox(height: 10),
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

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: value,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
              for (final entry in options.entries)
                DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

Color _priorityColor(BuildContext context, String priority) {
  final palette = context.palette;
  return switch (priority) {
    SupportPriority.urgent => palette.danger,
    SupportPriority.high => palette.orange,
    SupportPriority.low => palette.muted,
    _ => palette.blue,
  };
}

Color _statusColor(BuildContext context, String status) {
  final palette = context.palette;
  return switch (status) {
    SupportStatus.resolved => palette.green,
    SupportStatus.closed => palette.muted,
    SupportStatus.inProgress => palette.orange,
    SupportStatus.inReview => palette.purple,
    _ => palette.blue,
  };
}

class _AdminTicketTile extends StatelessWidget {
  final SupportTicket ticket;

  const _AdminTicketTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shortUser = ticket.userId.length > 6
        ? ticket.userId.substring(ticket.userId.length - 6)
        : ticket.userId;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('support-ticket-${ticket.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _TicketSheet(ticket: ticket),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                      ticket.subject,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TagChip(
                    label: SupportPriority.label(ticket.priority),
                    color: _priorityColor(context, ticket.priority),
                  ),
                  const SizedBox(width: 6),
                  TagChip(
                    label: SupportStatus.label(ticket.status),
                    color: _statusColor(context, ticket.status),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${SupportCategory.label(ticket.category)} · user …$shortUser · '
                '${formatDate(ticket.createdAt)}',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                ticket.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.text, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketSheet extends StatefulWidget {
  final SupportTicket ticket;

  const _TicketSheet({required this.ticket});

  @override
  State<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends State<_TicketSheet> {
  late String _status = widget.ticket.status;
  late final _reply = TextEditingController(text: widget.ticket.adminReply);
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _account = AppFirebase
      .db
      .collection('users')
      .doc(widget.ticket.userId)
      .get();
  bool _saving = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final adminUid = AppFirebase.auth.currentUser?.uid;
    if (adminUid == null) {
      showAppMessage(context, 'Sign in again to save changes.', error: true);
      return;
    }
    final text = _reply.text.trim();
    final replyChanged = text.isNotEmpty && text != widget.ticket.adminReply;
    final statusChanged = _status != widget.ticket.status;
    if (!replyChanged && !statusChanged) {
      showAppMessage(context, 'Nothing to save.');
      return;
    }

    setState(() => _saving = true);
    try {
      await SupportService.adminUpdate(
        adminUid: adminUid,
        ticket: widget.ticket,
        status: _status,
        reply: replyChanged ? text : null,
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      Navigator.pop(context);
      showAppMessage(context, 'Ticket updated and recorded in the audit log.');
    } on ArgumentError catch (e) {
      if (mounted) showAppMessage(context, '${e.message}', error: true);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, describeFirestoreError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final t = widget.ticket;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.subject,
              style: TextStyle(
                color: palette.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${SupportCategory.label(t.category)} · Priority: '
              '${SupportPriority.label(t.priority)} · Submitted '
              '${formatDate(t.createdAt, withTime: true)}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _account,
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = (data?['name'] as String?)?.trim() ?? '';
                final email = (data?['email'] as String?)?.trim() ?? '';
                final text = snapshot.hasError
                    ? 'Account details could not be loaded.'
                    : snapshot.connectionState != ConnectionState.done
                        ? 'Loading account details…'
                        : data == null
                            ? 'No account record found for this user.'
                            : 'Name: ${name.isEmpty ? 'not given' : name}\n'
                                'Email: ${email.isEmpty ? 'not given' : email}';
                return Text(
                  text,
                  style: TextStyle(color: palette.text, fontSize: 13, height: 1.4),
                );
              },
            ),
            const SizedBox(height: 4),
            SelectableText(
              'User ID: ${t.userId}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              t.message,
              style: TextStyle(color: palette.text, height: 1.45),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Status'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('support-status'),
                  value: _status,
                  isExpanded: true,
                  items: [
                    for (final s in SupportStatus.all)
                      DropdownMenuItem(
                        value: s,
                        child: Text(SupportStatus.label(s)),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('support-reply'),
              controller: _reply,
              minLines: 3,
              maxLines: 8,
              maxLength: SupportRules.messageMax,
              decoration: const InputDecoration(
                labelText: 'Reply to the traveller',
                helperText:
                    'Shown to the user in their request list. Do not share passwords or payment details.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('support-save'),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
