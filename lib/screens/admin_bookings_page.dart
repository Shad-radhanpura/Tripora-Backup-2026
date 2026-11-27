import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/saved_trip.dart';
import '../models/tour_package.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'my_bookings_screen.dart';

/// Admin: every booking request, with search, status / type filters and
/// status changes (confirm, complete, cancel) or deletion.
class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  final _stream = FirestoreService.allBookingsStream();
  final _search = TextEditingController();
  String _query = '';
  String? _status;
  String? _kind;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setStatus(Booking b, String status) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _StatusDialog(booking: b, status: status),
    );
    if (note == null || !mounted) return;
    Navigator.of(context).pop(); // close the details sheet
    try {
      await FirestoreService.setBookingStatus(
        b.id,
        status,
        adminNote: note.isEmpty ? null : note,
      ).timeout(const Duration(seconds: 15));
      if (mounted) showAppMessage(context, '${b.reference} marked $status.');
    } catch (e) {
      if (mounted) showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  Future<void> _delete(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${b.reference}?'),
        content: const Text('The booking record is removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).pop();
    try {
      await FirestoreService.deleteBooking(b.id)
          .timeout(const Duration(seconds: 15));
      if (mounted) showAppMessage(context, '${b.reference} deleted.');
    } catch (e) {
      if (mounted) showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  void _open(Booking b) {
    Widget action(String status, String label, IconData icon, Color color) =>
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: color),
              onPressed: () => _setStatus(b, status),
              icon: Icon(icon),
              label: Text(label),
            ),
          ),
        );

    showBookingDetails(
      context,
      b,
      adminActions: [
        const Divider(height: 26),
        const Text('Admin actions',
            style: TextStyle(fontWeight: FontWeight.w900)),
        if (b.status != 'confirmed')
          action('confirmed', 'Mark confirmed (demo)', Icons.verified_rounded,
              context.palette.blue),
        if (b.status != 'completed')
          action('completed', 'Mark completed', Icons.task_alt_rounded,
              context.palette.green),
        if (b.status != 'cancelled')
          action('cancelled', 'Cancel booking', Icons.cancel_outlined,
              context.palette.danger),
        if (b.status != 'pending')
          action('pending', 'Move back to requested', Icons.undo_rounded,
              context.palette.orange),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: () => _delete(b),
            style: TextButton.styleFrom(foregroundColor: context.palette.danger),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete record'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Booking Management')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
                error: snapshot.error, title: 'Could not load bookings');
          }
          if (!snapshot.hasData) {
            return const LoadingState(message: 'Loading bookings…');
          }

          final all = snapshot.data!.docs.map(Booking.fromDoc).toList()
            ..sort((a, b) => compareNewestFirst(a.createdAt, b.createdAt));
          final filtered = all
              .where((b) => b.matches(_query))
              .where((b) => _status == null || b.status == _status)
              .where((b) => _kind == null || b.kind == _kind)
              .toList();
          final value = all
              .where((b) => b.status != 'cancelled')
              .fold<int>(0, (total, b) => total + b.totalPrice);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in Booking.statuses)
                        TagChip(
                          label:
                              '${all.where((b) => b.status == s).length} $s',
                          color: StatusPill.colorFor(context, s),
                        ),
                      TagChip(
                        label: '${formatInr(value)} requested value (demo)',
                        color: context.palette.navy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search reference, title, email or name',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in [null, ...Booking.statuses])
                        ChoiceChip(
                          label: Text(s ?? 'All statuses'),
                          selected: _status == s,
                          onSelected: (_) => setState(() => _status = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final k in [null, ...Booking.kinds])
                        ChoiceChip(
                          label: Text(k ?? 'All types'),
                          selected: _kind == k,
                          onSelected: (_) => setState(() => _kind = k),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${filtered.length} of ${all.length} bookings',
                      style: TextStyle(
                          color: context.palette.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  if (all.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Text('No bookings have been made yet.',
                          textAlign: TextAlign.center),
                    )
                  else if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Text('No bookings match these filters.',
                          textAlign: TextAlign.center),
                    )
                  else
                    for (final b in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookingCard(
                          booking: b,
                          showUser: true,
                          onTap: () => _open(b),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusDialog extends StatefulWidget {
  final Booking booking;
  final String status;

  const _StatusDialog({required this.booking, required this.status});

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late final _note = TextEditingController(text: widget.booking.adminNote);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mark ${widget.booking.reference} as ${widget.status}?'),
      content: TextField(
        controller: _note,
        maxLength: 200,
        decoration: const InputDecoration(
          labelText: 'Note for the traveller (optional)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _note.text.trim()),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
