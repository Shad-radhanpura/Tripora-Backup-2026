import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/saved_trip.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_image.dart';
import 'itinerary_page.dart';
import 'trip_details_screen.dart';
import 'trip_readiness_page.dart';
import '../services/app_firebase.dart';

/// "My Trips" tab: the itineraries the signed-in user has saved.
///
/// Reads the existing `trips` collection filtered by the user's UID, so a
/// user only ever sees their own trips. Opening a trip shows the stored
/// itinerary; nothing is regenerated.
class MyTripsView extends StatefulWidget {
  final VoidCallback onExplore;

  const MyTripsView({super.key, required this.onExplore});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid != null) _stream = FirestoreService.userTripsStream(uid);
  }

  void _open(SavedTrip trip) {
    SafeNav.push(
      context,
      ItineraryPage(
        itinerary: trip.itinerary,
        destination: trip.destination,
        days: trip.days ?? 0,
        budget: trip.budget,
        interest: trip.interest,
        isSaved: true,
        savedAt: trip.createdAt,
        tripId: trip.id,
        showPlanAnother: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TabHeader(
          title: 'My Trips',
          subtitle: 'Itineraries you generated and saved.',
          action: IconButton.filledTonal(
            tooltip: 'Plan a new trip',
            onPressed: () => SafeNav.push(context, const TripDetailsScreen()),
            icon: Icon(Icons.add_rounded),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    final stream = _stream;
    if (stream == null) {
      return const EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Not signed in',
        message: 'Sign in again to see your saved trips.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(
            error: snapshot.error,
            title: 'Could not load your trips',
          );
        }
        if (!snapshot.hasData) {
          return const LoadingState(message: 'Loading your trips…');
        }

        final trips = snapshot.data!.docs.map(SavedTrip.fromDoc).toList()
          ..sort(SavedTrip.newestFirst);

        if (trips.isEmpty) {
          return EmptyState(
            icon: Icons.luggage_rounded,
            title: 'No saved trips yet',
            message:
                'Every itinerary you generate with Tripora AI is saved here '
                'automatically. Find a destination to get started.',
            actionLabel: 'Explore destinations',
            onAction: widget.onExplore,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          itemCount: trips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final trip = trips[index];
            return TripCard(
              trip: trip,
              onTap: () => _open(trip),
              onDelete: () => confirmAndDeleteTrip(context, trip),
              onReadiness: () => SafeNav.push(context, TripReadinessPage(trip: trip)),
            );
          },
        );
      },
    );
  }
}

/// Card for a saved trip; also used by the Admin Panel.
class TripCard extends StatelessWidget {
  final SavedTrip trip;
  final VoidCallback onTap;
  final String? ownerLabel;
  final VoidCallback? onDelete;

  /// Opens Trip Readiness for this trip. Only the owner's view passes this.
  final VoidCallback? onReadiness;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.ownerLabel,
    this.onDelete,
    this.onReadiness,
  });

  @override
  Widget build(BuildContext context) {
    final match = DestinationCatalog.matchName(trip.destination);

    return Material(
      color: context.palette.surface,
      elevation: 2,
      shadowColor: context.palette.teal.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: trip.hasItinerary ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                height: 124,
                child: DestinationImage(
                  url: match?.imageUrl,
                  label: trip.destination,
                  cacheWidth: 300,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.palette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ownerLabel ?? 'Saved ${formatDate(trip.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.palette.muted,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TagChip(
                            label: trip.daysLabel,
                            color: context.palette.orange,
                            icon: Icons.calendar_month_rounded,
                          ),
                          TagChip(
                            label: trip.budget,
                            color: context.palette.green,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          TagChip(
                            label: trip.interest,
                            color: AppColors.forCategory(trip.interest),
                            icon: AppColors.iconForCategory(trip.interest),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (onReadiness != null)
                IconButton(
                  key: Key('trip-readiness-${trip.id}'),
                  tooltip: 'Trip readiness',
                  onPressed: onReadiness,
                  icon: Icon(Icons.fact_check_rounded, color: context.palette.teal),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete trip',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: context.palette.danger),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  trip.hasItinerary
                      ? Icons.chevron_right_rounded
                      : Icons.error_outline_rounded,
                  color: context.palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _TabHeader({required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: SectionHeader(title: title, subtitle: subtitle, trailing: action),
    );
  }
}

/// Asks for confirmation, then deletes a saved trip (owner or admin; the
/// security rules allow nobody else). Favourites are not affected.
Future<void> confirmAndDeleteTrip(BuildContext context, SavedTrip trip) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this trip?'),
      content: Text(
        'The saved itinerary for ${trip.destination} will be removed '
        'permanently.',
      ),
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
  if (ok != true || !context.mounted) return;
  try {
    await FirestoreService.deleteTrip(trip.id)
        .timeout(const Duration(seconds: 15));
    if (context.mounted) showAppMessage(context, 'Trip deleted.');
  } catch (e) {
    if (context.mounted) {
      showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }
}
