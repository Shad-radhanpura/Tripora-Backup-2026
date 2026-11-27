import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/destination_review.dart';
import '../models/saved_trip.dart' show formatDate;
import '../services/app_firebase.dart';
import '../services/review_service.dart';
import '../theme/theme.dart';
import 'common.dart';

/// Ratings and reviews for one catalogue destination.
///
/// Shows the average rating and count from APPROVED reviews only, the
/// signed-in user's own review with its moderation status, and a form to
/// write or edit it. Edited reviews go back to "pending" for admin approval.
class DestinationReviewsSection extends StatelessWidget {
  final Destination destination;

  const DestinationReviewsSection({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final user = AppFirebase.auth.currentUser;

    return Material(
      color: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: StreamBuilder<List<DestinationReview>>(
          stream: ReviewService.approvedFor(destination.id),
          builder: (context, approvedSnap) {
            if (approvedSnap.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context),
                  const SizedBox(height: 8),
                  Text(
                    describeFirestoreError(approvedSnap.error),
                    style: TextStyle(
                      color: context.palette.danger,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }
            if (!approvedSnap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final approved = approvedSnap.data!;
            final stats = ReviewStats.fromApproved(approved);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summary(context, stats),
                const SizedBox(height: 14),
                if (user == null)
                  Text(
                    'Log in to rate this destination and write a review.',
                    style: TextStyle(color: context.palette.muted, fontSize: 13),
                  )
                else
                  _MyReview(destination: destination, user: user),
                const SizedBox(height: 16),
                Text(
                  'What travellers say',
                  style: TextStyle(
                    color: context.palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (approved.isEmpty)
                  Text(
                    'No published reviews yet. Be the first to share your experience.',
                    style: TextStyle(color: context.palette.muted, fontSize: 13),
                  )
                else
                  for (final review in approved.take(10))
                    _ReviewTile(review: review),
                if (approved.length > 10)
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Showing the 10 most recent reviews.',
                      style: TextStyle(color: context.palette.muted, fontSize: 11.5),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _title(BuildContext context) => Text(
    'Ratings & reviews',
    style: TextStyle(
      color: context.palette.text,
      fontSize: 16,
      fontWeight: FontWeight.w900,
    ),
  );

  Widget _summary(BuildContext context, ReviewStats stats) {
    final average = stats.average;
    return Row(
      children: [
        _title(context),
        const Spacer(),
        if (average == null)
          Text(
            'No ratings yet',
            style: TextStyle(color: context.palette.muted, fontSize: 12.5),
          )
        else
          Row(
            children: [
              Icon(Icons.star_rounded, color: context.palette.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                average.toStringAsFixed(1),
                key: const Key('review-average'),
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${stats.count} ${stats.count == 1 ? 'review' : 'reviews'})',
                key: const Key('review-count'),
                style: TextStyle(color: context.palette.muted, fontSize: 12.5),
              ),
            ],
          ),
      ],
    );
  }
}

/// The signed-in user's own review: shows status, and opens the form.
class _MyReview extends StatelessWidget {
  final Destination destination;
  final User user;

  const _MyReview({required this.destination, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DestinationReview?>(
      stream: ReviewService.myReview(destination.id, user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            describeFirestoreError(snapshot.error),
            style: TextStyle(color: context.palette.danger, fontSize: 13),
          );
        }
        final mine = snapshot.data;
        final ready = snapshot.connectionState != ConnectionState.waiting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ready && mine != null) ...[
              Row(
                children: [
                  Text(
                    'Your review',
                    style: TextStyle(
                      color: context.palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TagChip(
                    key: const Key('my-review-status'),
                    label: ReviewStatus.label(mine.status),
                    color: _statusColor(context, mine.status),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _Stars(rating: mine.rating),
              const SizedBox(height: 4),
              Text(
                mine.text,
                style: TextStyle(color: context.palette.text, fontSize: 13),
              ),
              if (mine.status == ReviewStatus.pending)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Your review is waiting for approval. It is only shown to you until then.',
                    style: TextStyle(color: context.palette.muted, fontSize: 11.5),
                  ),
                ),
              if (mine.status == ReviewStatus.rejected)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'This review was not published. You can edit it and send it again.',
                    style: TextStyle(color: context.palette.muted, fontSize: 11.5),
                  ),
                ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('write-review'),
                onPressed: !ready ? null : () => _openForm(context, mine),
                icon: Icon(
                  mine == null
                      ? Icons.rate_review_outlined
                      : Icons.edit_rounded,
                ),
                label: Text(
                  mine == null ? 'Write a review' : 'Edit your review',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openForm(BuildContext context, DestinationReview? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _ReviewForm(
        destination: destination,
        userId: user.uid,
        displayName: user.displayName ?? '',
        existing: existing,
      ),
    );
  }

  static Color _statusColor(BuildContext context, String status) => switch (status) {
    ReviewStatus.approved => context.palette.green,
    ReviewStatus.rejected => context.palette.danger,
    _ => context.palette.orange,
  };
}

class _ReviewForm extends StatefulWidget {
  final Destination destination;
  final String userId;
  final String displayName;
  final DestinationReview? existing;

  const _ReviewForm({
    required this.destination,
    required this.userId,
    required this.displayName,
    required this.existing,
  });

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _text = TextEditingController(text: widget.existing?.text ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_rating < 1) {
      setState(() => _error = 'Tap a star to choose your rating.');
      return;
    }
    final textError = ReviewRules.validateText(_text.text);
    if (textError != null) {
      setState(() => _error = textError);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ReviewService.save(
        destinationId: widget.destination.id,
        userId: widget.userId,
        displayName: widget.displayName,
        rating: _rating,
        text: _text.text,
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      Navigator.pop(context);
      showAppMessage(context, 'Thanks! Your review is pending approval.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save your review. ${describeFirestoreError(e)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null
                  ? 'Review ${widget.destination.name}'
                  : 'Edit your review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reviews are checked by an admin before they are shown to others.',
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: Key('review-star-$i'),
                    tooltip: '$i star${i == 1 ? '' : 's'}',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: context.palette.orange,
                      size: 34,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('review-text'),
              controller: _text,
              enabled: !_saving,
              maxLines: 5,
              maxLength: ReviewRules.maxTextLength,
              decoration: const InputDecoration(
                labelText: 'Your experience',
                hintText: 'What did you enjoy? What would you tell a friend?',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  key: const Key('review-error'),
                  style: TextStyle(color: context.palette.danger, fontSize: 13),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                key: const Key('review-submit'),
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving…' : 'Submit for approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final DestinationReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                formatDate(review.updatedAt ?? review.createdAt),
                style: TextStyle(color: context.palette.muted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _Stars(rating: review.rating),
          const SizedBox(height: 4),
          Text(
            review.text,
            style: TextStyle(
              color: context.palette.text,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;

  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: context.palette.orange,
            size: 16,
          ),
      ],
    );
  }
}
