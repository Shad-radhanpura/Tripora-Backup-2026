import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../theme/theme.dart';
import 'common.dart';
import 'destination_image.dart';
import 'favourite_button.dart';

/// Full-width destination card used in Discovery results and Favourites.
class DestinationCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback onOpen;
  final VoidCallback onPlan;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.onOpen,
    required this.onPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.palette.border),
        boxShadow: AppColors.softShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 168,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DestinationImage(
                      url: destination.imageUrl,
                      label: destination.name,
                      cacheWidth: 900,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x66000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FavouriteButton(destination: destination),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: TagChip(
                        label: destination.location,
                        color: Colors.white,
                        icon: Icons.location_on_rounded,
                        onDark: true,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: TextStyle(
                        color: context.palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      destination.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
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
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onPlan,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Plan'),
                          style: TextButton.styleFrom(
                            foregroundColor: context.palette.blue,
                            backgroundColor: context.palette.surfaceTint,
                            minimumSize: const Size(48, 40),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact photo card for the horizontal "Featured" carousel.
class FeaturedDestinationCard extends StatelessWidget {
  final Destination destination;
  final VoidCallback onOpen;

  const FeaturedDestinationCard({
    super.key,
    required this.destination,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DestinationImage(
                  url: destination.imageUrl,
                  label: destination.name,
                  cacheWidth: 700,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC0B1530)],
                      stops: [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FavouriteButton(destination: destination, size: 36),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
