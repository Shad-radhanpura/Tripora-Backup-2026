import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/destination.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_card.dart';
import 'destination_details_screen.dart';
import 'trip_details_screen.dart';
import '../services/app_firebase.dart';

/// "Favourites" tab: destinations the user liked with the heart button.
///
/// Stored in users/{uid}/favourites/{destinationId}. Removing a favourite
/// only deletes that marker; saved trips are never affected.
class FavouritesView extends StatefulWidget {
  final VoidCallback onExplore;

  const FavouritesView({super.key, required this.onExplore});

  @override
  State<FavouritesView> createState() => _FavouritesViewState();
}

class _FavouritesViewState extends State<FavouritesView> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid != null) _stream = FirestoreService.favouritesStream(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: SectionHeader(
            title: 'Favourites',
            subtitle: 'Places you love. Plan a trip to any of them.',
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
        message: 'Sign in again to see your favourites.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(
            error: snapshot.error,
            title: 'Could not load favourites',
          );
        }
        if (!snapshot.hasData) {
          return const LoadingState(message: 'Loading favourites…');
        }

        // Newest favourite first. Favourites whose destination is no longer
        // in the catalogue are skipped rather than shown half-empty.
        final docs = [...snapshot.data!.docs]
          ..sort((a, b) {
            final aTime = a.data()['addedAt'];
            final bTime = b.data()['addedAt'];
            // A favourite added a moment ago has no server time yet.
            if (aTime is! Timestamp && bTime is! Timestamp) return 0;
            if (aTime is! Timestamp) return -1;
            if (bTime is! Timestamp) return 1;
            return bTime.compareTo(aTime);
          });

        final destinations = docs
            .map((doc) => DestinationCatalog.byId(doc.id))
            .whereType<Destination>()
            .toList();

        if (destinations.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_rounded,
            color: context.palette.pink,
            title: 'No favourites yet',
            message:
                'Tap the heart on any destination to save it here for later.',
            actionLabel: 'Explore destinations',
            onAction: widget.onExplore,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          itemCount: destinations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final destination = destinations[index];
            return DestinationCard(
              destination: destination,
              onOpen: () => SafeNav.push(
                context,
                DestinationDetailsScreen(destination: destination),
              ),
              onPlan: () => SafeNav.push(
                context,
                TripDetailsScreen(initialDestination: destination.name),
              ),
            );
          },
        );
      },
    );
  }
}
