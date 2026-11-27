import 'package:flutter/material.dart';

import '../models/tourist_attraction.dart';
import '../theme/theme.dart';
import 'destination_image.dart';

/// "Tourist attractions" grid for one destination: one card per place, with
/// a photo, name, location and a short description. Two columns on wide
/// screens, one column on phones.
class AttractionSection extends StatelessWidget {
  final String destinationName;
  final List<TouristAttraction> attractions;

  const AttractionSection({
    super.key,
    required this.destinationName,
    required this.attractions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_rounded,
                size: 19, color: context.palette.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tourist attractions',
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${attractions.length} places',
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Places to see in $destinationName. Tap a card for more.',
          style: TextStyle(color: context.palette.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 2 : 1;
            const gap = 12.0;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final attraction in attractions)
                  SizedBox(
                    width: width,
                    child: AttractionCard(attraction: attraction),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One tourist place. Shows a placeholder (not an unrelated photo) when no
/// verified image exists, and a loading indicator while the photo loads.
class AttractionCard extends StatelessWidget {
  final TouristAttraction attraction;

  const AttractionCard({super.key, required this.attraction});

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attraction.name,
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.place_rounded,
                      size: 16, color: context.palette.coral),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      attraction.location,
                      style: TextStyle(
                        color: context.palette.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                attraction.description,
                style: TextStyle(height: 1.5, color: context.palette.text),
              ),
              const SizedBox(height: 16),
              Text(
                'Photo: ${attraction.imageCredit}',
                style: TextStyle(color: context.palette.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
        boxShadow: AppColors.softShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Semantics(
              label: 'Photo of ${attraction.name}',
              image: true,
              // No label: the card title already names the place, so the
              // placeholder shows only the gradient and icon.
              child: DestinationImage(
                url: attraction.imageUrl,
                cacheWidth: 700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attraction.name,
                  style: TextStyle(
                    color: context.palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  attraction.location,
                  style: TextStyle(
                    color: context.palette.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  attraction.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showDetails(context),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('View details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
