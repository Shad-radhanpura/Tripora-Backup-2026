import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/destination_review.dart';
import '../models/saved_trip.dart' show formatDate;
import '../services/review_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Admin: review moderation with live statistics.
///
/// Every number comes from the `reviews` documents. The public average uses
/// approved reviews only. Only admins can read every review, and the
/// security rules allow only admins to change a review's status or delete it.
class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final _stream = ReviewService.allReviews();
  String? _filter;
  final Set<String> _busy = {};

  Future<void> _setStatus(DestinationReview review, String status) async {
    if (_busy.contains(review.id)) return;
    setState(() => _busy.add(review.id));
    try {
      await ReviewService.setStatus(
        review.id,
        status,
      ).timeout(const Duration(seconds: 15));
      if (mounted) {
        showAppMessage(
          context,
          'Review marked ${ReviewStatus.label(status).toLowerCase()}.',
        );
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(context, describeFirestoreError(e), error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy.remove(review.id));
      }
    }
  }

  Future<void> _remove(DestinationReview review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this review?'),
        content: const Text(
          'The review is deleted permanently. Its author can write a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ReviewService.deleteReview(
        review.id,
      ).timeout(const Duration(seconds: 15));
      if (mounted) {
        showAppMessage(context, 'Review removed.');
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(context, describeFirestoreError(e), error: true);
      }
    }
  }

  void _details(DestinationReview review) {
    final name = _destinationName(review.destinationId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              _stars(context, review.rating),
              const SizedBox(height: 10),
              Text(review.text, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 12),
              _row(context, 'Reviewer', review.displayName),
              _row(context, 'Reviewer user ID', review.userId),
              _row(context, 'Status', ReviewStatus.label(review.status)),
              _row(context, 'Submitted', formatDate(review.createdAt, withTime: true)),
              _row(context, 
                'Last changed',
                formatDate(review.updatedAt, withTime: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _destinationName(String id) =>
      DestinationCatalog.byId(id)?.name ?? id;

  static Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(color: context.palette.muted, fontSize: 12.5),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5))),
      ],
    ),
  );

  static Widget _stars(BuildContext context, int rating) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: context.palette.orange,
          size: 18,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Ratings & Reviews')),
      body: StreamBuilder<List<DestinationReview>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              error: snapshot.error,
              title: 'Could not load reviews',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingState(message: 'Loading reviews…');
          }
          final all = snapshot.data!;
          final counts = ModerationCounts.from(all);
          final visible = _filter == null
              ? all
              : all.where((r) => r.status == _filter).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  _statsRow(counts),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in [null, ...ReviewStatus.all])
                        ChoiceChip(
                          key: Key('review-filter-${f ?? 'all'}'),
                          label: Text(
                            f == null ? 'All' : ReviewStatus.label(f),
                          ),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${visible.length} of ${all.length} reviews',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (all.isEmpty)
                    EmptyState(
                      icon: Icons.reviews_outlined,
                      title: 'No reviews yet',
                      message:
                          'Reviews appear here when travellers submit them.',
                    )
                  else if (visible.isEmpty)
                    const EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Nothing in this filter',
                      message: 'Choose another status to see reviews.',
                    )
                  else
                    for (final review in visible) _card(review),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statsRow(ModerationCounts c) {
    Widget tile(String label, String value, Color color, {Key? key}) =>
        Container(
          key: key,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.palette.border),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.muted, fontSize: 11.5),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 170,
          child: tile(
            'Total reviews',
            '${c.total}',
            context.palette.navy,
            key: const Key('stat-total'),
          ),
        ),
        SizedBox(
          width: 170,
          child: tile(
            'Pending',
            '${c.pending}',
            context.palette.orange,
            key: const Key('stat-pending'),
          ),
        ),
        SizedBox(
          width: 170,
          child: tile(
            'Approved',
            '${c.approved}',
            context.palette.green,
            key: const Key('stat-approved'),
          ),
        ),
        SizedBox(
          width: 170,
          child: tile(
            'Rejected',
            '${c.rejected}',
            context.palette.danger,
            key: const Key('stat-rejected'),
          ),
        ),
        SizedBox(
          width: 170,
          child: tile(
            'Average (approved)',
            c.averageApproved == null
                ? '—'
                : c.averageApproved!.toStringAsFixed(1),
            context.palette.blue,
            key: const Key('stat-average'),
          ),
        ),
      ],
    );
  }

  Widget _card(DestinationReview review) {
    final busy = _busy.contains(review.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _destinationName(review.destinationId),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TagChip(
                label: ReviewStatus.label(review.status),
                color: _statusColor(context, review.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _stars(context, review.rating),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${review.displayName} · ${formatDate(review.updatedAt ?? review.createdAt)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _details(review),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Details'),
              ),
              if (review.status != ReviewStatus.approved)
                TextButton.icon(
                  key: Key('approve-${review.id}'),
                  onPressed: busy
                      ? null
                      : () => _setStatus(review, ReviewStatus.approved),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Approve'),
                ),
              if (review.status != ReviewStatus.rejected)
                TextButton.icon(
                  key: Key('reject-${review.id}'),
                  onPressed: busy
                      ? null
                      : () => _setStatus(review, ReviewStatus.rejected),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Reject'),
                ),
              TextButton.icon(
                key: Key('remove-${review.id}'),
                style: TextButton.styleFrom(foregroundColor: context.palette.danger),
                onPressed: busy ? null : () => _remove(review),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(BuildContext context, String status) => switch (status) {
    ReviewStatus.approved => context.palette.green,
    ReviewStatus.rejected => context.palette.danger,
    _ => context.palette.orange,
  };
}
