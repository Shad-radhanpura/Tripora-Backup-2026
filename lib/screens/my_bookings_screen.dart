import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/saved_trip.dart';
import '../models/tour_package.dart';
import '../services/app_firebase.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Standalone page (opened after booking or from Profile).
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('My Bookings')),
      body: const MyBookingsView(showHeader: false),
    );
  }
}

/// Live list of the signed-in user's bookings, newest first.
class MyBookingsView extends StatefulWidget {
  final bool showHeader;
  final VoidCallback? onBrowse;

  const MyBookingsView({super.key, this.showHeader = true, this.onBrowse});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid != null) _stream = FirestoreService.userBookingsStream(uid);
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 6),
            child: SectionHeader(
              title: 'My Bookings',
              subtitle: 'Package, hotel and transport requests (demo).',
            ),
          ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            children: [
              for (final value in ['all', ...Booking.statuses])
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(value == 'all'
                        ? 'All'
                        : value[0].toUpperCase() + value.substring(1)),
                    selected: _filter == value,
                    onSelected: (_) => setState(() => _filter = value),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: stream == null
              ? const EmptyState(
                  icon: Icons.lock_outline,
                  title: 'Not signed in',
                  message: 'Log in to see your bookings.',
                )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorState(error: snapshot.error);
                    }
                    if (!snapshot.hasData) return const LoadingState();

                    final all = snapshot.data!.docs.map(Booking.fromDoc).toList()
                      ..sort((a, b) => compareNewestFirst(a.createdAt, b.createdAt));
                    final bookings = _filter == 'all'
                        ? all
                        : all.where((b) => b.status == _filter).toList();

                    if (bookings.isEmpty) {
                      return EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: all.isEmpty ? 'No bookings yet' : 'Nothing here',
                        message: all.isEmpty
                            ? 'Book a tour package, hotel, flight, train or bus '
                                'and it will appear here.'
                            : 'No bookings with this status.',
                        actionLabel: all.isEmpty ? 'Browse packages' : null,
                        onAction: all.isEmpty ? widget.onBrowse : null,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      itemCount: bookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => BookingCard(
                        booking: bookings[i],
                        onTap: () => showBookingDetails(context, bookings[i]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

IconData bookingIcon(String kind) => switch (kind) {
      'package' => Icons.card_travel_rounded,
      'hotel' => Icons.hotel_rounded,
      'flight' => Icons.flight_takeoff_rounded,
      'train' => Icons.train_rounded,
      'bus' => Icons.directions_bus_rounded,
      'cab' => Icons.local_taxi_rounded,
      _ => Icons.receipt_long_rounded,
    };

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final bool showUser;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.showUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
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
                  color: context.palette.surfaceTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(bookingIcon(b.kind), color: context.palette.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.palette.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${b.kindLabel} • ${formatDate(b.travelDate)} • '
                      '${b.travellers} × • ${formatInr(b.totalPrice)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.palette.muted, fontSize: 12),
                    ),
                    if (showUser)
                      Text(
                        b.userEmail.isEmpty ? b.userId : b.userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: context.palette.muted, fontSize: 11.5),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusPill(status: b.status, label: b.statusLabel),
                        TagChip(label: b.reference, color: context.palette.navy),
                      ],
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

/// Bottom sheet with every booking field. Owners can cancel from here.
Future<void> showBookingDetails(
  BuildContext context,
  Booking booking, {
  List<Widget> adminActions = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _BookingDetailsSheet(
      booking: booking,
      adminActions: adminActions,
    ),
  );
}

class _BookingDetailsSheet extends StatefulWidget {
  final Booking booking;
  final List<Widget> adminActions;

  const _BookingDetailsSheet({
    required this.booking,
    required this.adminActions,
  });

  @override
  State<_BookingDetailsSheet> createState() => _BookingDetailsSheetState();
}

class _BookingDetailsSheetState extends State<_BookingDetailsSheet> {
  bool _busy = false;

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text('The request will be marked as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await FirestoreService.cancelBooking(widget.booking.id)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      Navigator.pop(context);
      showAppMessage(context, 'Booking ${widget.booking.reference} cancelled.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isOwner = AppFirebase.auth.currentUser?.uid == b.userId;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(label,
                    style: TextStyle(color: context.palette.muted, fontSize: 13)),
              ),
              Expanded(
                child: Text(value.isEmpty ? '—' : value,
                    style: const TextStyle(fontSize: 13.5)),
              ),
            ],
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(bookingIcon(b.kind), color: context.palette.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    b.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StatusPill(status: b.status, label: b.statusLabel),
            const SizedBox(height: 14),
            row('Reference', '${b.reference} (demo)'),
            row('Type', b.kindLabel),
            row('Summary', b.subtitle),
            row('Travel date', formatDate(b.travelDate)),
            row('Quantity', '${b.travellers}'),
            row('Price', '${formatInr(b.unitPrice)} each'),
            row('Total', formatInr(b.totalPrice)),
            row('Lead traveller', b.contactName),
            row('Mobile', b.contactPhone),
            if (b.userEmail.isNotEmpty) row('Account', b.userEmail),
            for (final e in b.details.entries) row(e.key, e.value),
            if (b.notes.isNotEmpty) row('Requests', b.notes),
            if (b.adminNote.isNotEmpty) row('Admin note', b.adminNote),
            row('Requested on', formatDate(b.createdAt, withTime: true)),
            if (b.updatedAt != null)
              row('Updated', formatDate(b.updatedAt, withTime: true)),
            const SizedBox(height: 8),
            const DemoNotice(),
            const SizedBox(height: 14),
            if (isOwner && b.canUserCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: context.palette.danger),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel booking'),
                ),
              ),
            ...widget.adminActions,
          ],
        ),
      ),
    );
  }
}
