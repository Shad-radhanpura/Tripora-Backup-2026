import 'package:flutter/material.dart';

import '../data/attractions.dart';
import '../data/local_food.dart';
import 'food_explorer_page.dart';
import '../models/destination.dart';
import '../models/destination_review.dart';
import '../theme/theme.dart';
import '../widgets/attraction_section.dart';
import '../widgets/common.dart';
import '../widgets/destination_image.dart';
import '../widgets/favourite_button.dart';
import 'trip_details_screen.dart';
import '../widgets/destination_reviews_section.dart';

/// Details for one destination, with a favourite button and a prominent
/// "Plan My Trip" action that opens the existing AI trip planner with the
/// destination already filled in.
class DestinationDetailsScreen extends StatelessWidget {
  final Destination destination;

  const DestinationDetailsScreen({super.key, required this.destination});

  void _plan(BuildContext context) {
    SafeNav.push(
      context,
      TripDetailsScreen(initialDestination: destination.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attractions = AttractionCatalog.forDestination(destination.id);

    return Scaffold(
      backgroundColor: context.palette.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: context.palette.navy,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: 'Back',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
              ),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FavouriteButton(destination: destination),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(
                    url: destination.imageUrl,
                    label: destination.name,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          Color(0x00000000),
                          Color(0xDD0B1530),
                        ],
                        stops: [0, 0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TagChip(
                          label: destination.location,
                          color: Colors.white,
                          icon: Icons.location_on_rounded,
                          onDark: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          destination.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination.tagline,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: destination.categories
                      .map(
                        (c) => TagChip(
                          label: c,
                          color: AppColors.forCategory(c),
                          icon: AppColors.iconForCategory(c),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                _Panel(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  child: Text(
                    destination.description,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (attractions.isNotEmpty) ...[
                  AttractionSection(
                    destinationName: destination.name,
                    attractions: attractions,
                  ),
                  const SizedBox(height: 12),
                ],
                if (attractions.isEmpty)
                _Panel(
                  icon: Icons.place_rounded,
                  title: 'Popular places to visit',
                  child: Column(
                    children: destination.highlights
                        .map(
                          (place) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: context.palette.surfaceTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: context.palette.blue,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    place,
                                    style: TextStyle(
                                      color: context.palette.text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _Panel(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Best time to visit',
                  child: Text(
                    destination.bestTime,
                    style: TextStyle(
                      color: context.palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (FoodCatalog.hasFood(destination.id)) ...[
                  OutlinedButton.icon(
                    key: const Key('open-local-food'),
                    onPressed: () => SafeNav.push(
                      context,
                      FoodExplorerPage(destinationId: destination.id),
                    ),
                    icon: const Icon(Icons.restaurant_menu_rounded),
                    label: Text('Local food in ${destination.name}'),
                  ),
                  const SizedBox(height: 12),
                ],
                // Reviews are only offered where the security rules allow them.
                if (ReviewRules.isReviewable(destination.id))
                  DestinationReviewsSection(destination: destination),
                const SizedBox(height: 14),
                Text(
                  'Photo: ${destination.imageCredit}',
                  style: TextStyle(color: context.palette.muted, fontSize: 10.5),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.actionGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.softShadow(context.palette.blue),
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _plan(context),
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                'Plan My Trip to ${destination.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Panel({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: context.palette.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
