import 'package:flutter/material.dart';

import '../models/saved_trip.dart' show formatDate;
import '../models/support_ticket.dart';
import '../services/app_firebase.dart';
import '../services/feedback_outbox.dart';
import '../services/support_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Colour for a workflow status, used on chips everywhere in this feature.
Color _statusColor(BuildContext context, String status) {
  final palette = context.palette;
  return switch (status) {
    SupportStatus.inReview => palette.purple,
    SupportStatus.inProgress => palette.orange,
    SupportStatus.resolved => palette.green,
    SupportStatus.closed => palette.muted,
    _ => palette.blue,
  };
}

/// Help & support: ask for help, report a bug, suggest a feature, and see the
/// status of everything you have sent.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Help & support')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              const _IntroCard(),
              const SizedBox(height: 18),
              const SectionHeader(
                title: 'What is this about?',
                subtitle: 'Pick a topic to start a report.',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in SupportCategory.all)
                    ActionChip(
                      key: Key('support-topic-$category'),
                      avatar: Icon(_topicIcon(category), size: 18, color: palette.blue),
                      label: Text(SupportCategory.label(category)),
                      onPressed: () => SafeNav.push(
                        context,
                        NewSupportRequestPage(initialCategory: category),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const _MyFeedbackList(),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _topicIcon(String category) => switch (category) {
    SupportCategory.bug => Icons.bug_report_rounded,
    SupportCategory.feature => Icons.lightbulb_rounded,
    SupportCategory.improvement => Icons.tune_rounded,
    SupportCategory.ui => Icons.design_services_rounded,
    _ => Icons.help_outline_rounded,
  };
}

/// Your own feedback and issues, on their own page.
class MyFeedbackPage extends StatelessWidget {
  const MyFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('My feedback & issues')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('feedback-new'),
        onPressed: () => SafeNav.push(context, const NewSupportRequestPage()),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('New feedback'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
            children: const [_MyFeedbackList()],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Report a bug, suggest a feature, or ask for help. Please do not '
            'send passwords, card numbers or passport details.',
            style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('support-new'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navy,
            ),
            onPressed: () => SafeNav.push(context, const NewSupportRequestPage()),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('New request'),
          ),
        ],
      ),
    );
  }
}

/// Reports saved on this device (not sent yet), followed by the reports the
/// team has received for this account.
class _MyFeedbackList extends StatefulWidget {
  const _MyFeedbackList();

  @override
  State<_MyFeedbackList> createState() => _MyFeedbackListState();
}

class _MyFeedbackListState extends State<_MyFeedbackList> {
  @override
  void initState() {
    super.initState();
    FeedbackOutbox.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) {
      return const EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to see your feedback',
        message: 'Your reports are linked to your account.',
      );
    }
    return ListenableBuilder(
      listenable: FeedbackOutbox.instance,
      builder: (context, _) {
        final drafts = FeedbackOutbox.instance.forUser(uid);
        return StreamBuilder<List<SupportTicket>>(
          stream: SupportService.myTickets(uid),
          builder: (context, snapshot) {
            final tickets = snapshot.data ?? const <SupportTicket>[];
            final loading = !snapshot.hasData && !snapshot.hasError;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (drafts.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Saved on this device (${drafts.length})',
                    subtitle: 'Not sent to the Tripora team yet.',
                  ),
                  const SizedBox(height: 12),
                  for (final draft in drafts) ...[
                    _DraftCard(draft: draft),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 10),
                ],
                SectionHeader(
                  title: 'My feedback & issues (${tickets.length})',
                  subtitle: 'Track each report. Replies from the team appear here.',
                ),
                const SizedBox(height: 12),
                if (snapshot.hasError)
                  EmptyState(
                    icon: Icons.cloud_off_rounded,
                    color: context.palette.danger,
                    title: 'Could not load your reports',
                    message: describeFirestoreError(snapshot.error),
                  )
                else if (loading)
                  const LoadingState(message: 'Loading your reports…')
                else if (tickets.isEmpty && drafts.isEmpty)
                  const EmptyState(
                    icon: Icons.support_agent_rounded,
                    title: 'No feedback yet',
                    message: 'Report a problem or suggest an improvement, and '
                        'track its status here.',
                  )
                else
                  for (final ticket in tickets) ...[
                    _TicketCard(ticket: ticket),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        );
      },
    );
  }
}

class _DraftCard extends StatefulWidget {
  final FeedbackDraft draft;

  const _DraftCard({required this.draft});

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  bool _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final sent = await SupportService.sendDraft(widget.draft);
    if (!mounted) return;
    setState(() => _sending = false);
    showAppMessage(
      context,
      sent
          ? 'Sent to the Tripora team.'
          : 'Still not sent. It stays saved on this device; try again later.',
      error: !sent,
    );
  }

  Future<void> _delete() async {
    await FeedbackOutbox.instance.remove(widget.draft.id);
    if (mounted) showAppMessage(context, 'Saved report deleted from this device.');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.warningSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.draft.subject,
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${SupportCategory.label(widget.draft.category)} · saved '
            '${formatDate(widget.draft.savedAt, withTime: true)}',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved on this device only. The Tripora team has not received it yet.',
            style: TextStyle(color: palette.warningText, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: Key('draft-delete-${widget.draft.id}'),
                onPressed: _delete,
                child: const Text('Delete'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: Key('draft-send-${widget.draft.id}'),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_sending ? 'Sending…' : 'Send now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('ticket-card-${ticket.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => SafeNav.push(context, SupportTicketDetailPage(ticket: ticket)),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    label: SupportStatus.label(ticket.status),
                    color: _statusColor(context, ticket.status),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${SupportCategory.label(ticket.category)} · '
                '${formatDate(ticket.createdAt)}',
                style: TextStyle(color: palette.muted, fontSize: 12),
              ),
              if (ticket.hasReply) ...[
                const SizedBox(height: 8),
                Text(
                  'The team has replied. Tap to read it.',
                  style: TextStyle(
                    color: palette.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One report: its status, the message sent, and any reply from the team.
class SupportTicketDetailPage extends StatelessWidget {
  final SupportTicket ticket;

  const SupportTicketDetailPage({super.key, required this.ticket});

  Future<void> _withdraw(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw this request?'),
        content: const Text('It will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await SupportService.withdraw(ticket);
      if (!context.mounted) return;
      Navigator.pop(context);
      showAppMessage(context, 'Request withdrawn.');
    } catch (e) {
      if (context.mounted) {
        showAppMessage(context, describeFirestoreError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canWithdraw = ticket.status == SupportStatus.open && !ticket.hasReply;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Report details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              Text(
                ticket.subject,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${SupportCategory.label(ticket.category)} · Priority: '
                '${SupportPriority.label(ticket.priority)} · Submitted '
                '${formatDate(ticket.createdAt, withTime: true)}',
                style: TextStyle(color: palette.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              _StatusSteps(current: ticket.status),
              const SizedBox(height: 16),
              _Panel(
                title: 'Your message',
                child: Text(
                  ticket.message,
                  style: TextStyle(color: palette.text, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                title: 'Reply from the Tripora team',
                tint: true,
                child: Text(
                  ticket.hasReply
                      ? '${ticket.adminReply}\n\n${formatDate(ticket.repliedAt)}'
                      : 'No reply yet. Replies appear here.',
                  style: TextStyle(
                    color: ticket.hasReply ? palette.text : palette.muted,
                    height: 1.45,
                  ),
                ),
              ),
              if (canWithdraw) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('ticket-withdraw'),
                    onPressed: () => _withdraw(context),
                    child: const Text('Withdraw this request'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The five steps a report moves through, with the current one highlighted.
class _StatusSteps extends StatelessWidget {
  final String current;

  const _StatusSteps({required this.current});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final steps = SupportStatus.all;
    final currentIndex = steps.indexOf(current);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < steps.length; i++)
          Chip(
            key: Key('status-step-${steps[i]}'),
            avatar: Icon(
              i <= currentIndex
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: i == currentIndex
                  ? _statusColor(context, steps[i])
                  : palette.muted,
            ),
            label: Text(SupportStatus.label(steps[i])),
            labelStyle: TextStyle(
              fontWeight: i == currentIndex ? FontWeight.w900 : FontWeight.w600,
              color: i == currentIndex ? palette.text : palette.muted,
            ),
            backgroundColor: i == currentIndex ? palette.surfaceTint : palette.surface,
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool tint;

  const _Panel({required this.title, required this.child, this.tint = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint ? palette.surfaceTint : palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.navy,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Form for a new report. Limits match [SupportRules] and the Firestore rules.
class NewSupportRequestPage extends StatefulWidget {
  final String? initialCategory;

  const NewSupportRequestPage({super.key, this.initialCategory});

  @override
  State<NewSupportRequestPage> createState() => _NewSupportRequestPageState();
}

class _NewSupportRequestPageState extends State<NewSupportRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  late String _category = widget.initialCategory ?? SupportCategory.help;
  String _priority = SupportPriority.normal;
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) {
      showAppMessage(context, 'Sign in again to send feedback.', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final outcome = await SupportService.submit(
        userId: uid,
        category: _category,
        priority: _priority,
        subject: _subject.text,
        message: _message.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      if (outcome == SubmitOutcome.sent) {
        showAppMessage(
          context,
          'Sent to the Tripora team. Follow its status in My feedback & issues.',
        );
      } else {
        showAppMessage(
          context,
          'Saved on this device only. It has NOT been sent to the Tripora team '
          'yet. Open My feedback & issues to send it again.',
          error: true,
        );
      }
    } on ArgumentError catch (e) {
      if (mounted) showAppMessage(context, '${e.message}', error: true);
    } catch (e) {
      if (mounted) showAppMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('New support request')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('support-category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'What is this about?'),
                  items: [
                    for (final c in SupportCategory.all)
                      DropdownMenuItem(value: c, child: Text(SupportCategory.label(c))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    SupportCategory.hint(_category),
                    style: TextStyle(color: palette.muted, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: const Key('support-priority'),
                  initialValue: _priority,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'How urgent is it?'),
                  items: [
                    for (final p in SupportPriority.all)
                      DropdownMenuItem(value: p, child: Text(SupportPriority.label(p))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('support-subject'),
                  controller: _subject,
                  maxLength: SupportRules.subjectMax,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: SupportRules.validateSubject,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('support-message'),
                  controller: _message,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: SupportRules.messageMax,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    helperText: 'What did you do, what happened, and what would help? '
                        'Screenshots cannot be attached yet.',
                    alignLabelWithHint: true,
                  ),
                  validator: SupportRules.validateMessage,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.warningSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.warningBorder),
                  ),
                  child: Text(
                    'Please do not include passwords, full card numbers or passport '
                    'details. Reports are read by the Tripora team.',
                    style: TextStyle(color: palette.warningText, fontSize: 12, height: 1.4),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('support-submit'),
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Sending…' : 'Send'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
