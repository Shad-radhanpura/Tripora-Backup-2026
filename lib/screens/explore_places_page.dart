import 'package:flutter/material.dart';

import '../data/attractions.dart';
import '../data/destinations.dart';
import '../models/destination.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_image.dart';
import 'destination_details_screen.dart';

/// Browse every destination and open its attractions and food guide.
class ExplorePlacesPage extends StatefulWidget {
  const ExplorePlacesPage({super.key});

  @override
  State<ExplorePlacesPage> createState() => _ExplorePlacesPageState();
}

class _ExplorePlacesPageState extends State<ExplorePlacesPage> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = DestinationCatalog.search(query: _query);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Explore places')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              TextField(
                key: const Key('explore-search'),
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search a destination or place',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              SizedBox(height: 14),
              if (results.isEmpty)
                const EmptyState(
                  icon: Icons.travel_explore_rounded,
                  title: 'No destinations found',
                  message: 'Try another name, such as Goa or Jaipur.',
                )
              else
                for (final destination in results) ...[
                  _PlaceTile(destination: destination),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final Destination destination;

  const _PlaceTile({required this.destination});

  @override
  Widget build(BuildContext context) {
    final count = AttractionCatalog.forDestination(destination.id).length;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => SafeNav.push(
          context,
          DestinationDetailsScreen(destination: destination),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 80,
                  child: DestinationImage(url: destination.imageUrl, cacheWidth: 300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.location,
                      style: TextStyle(color: context.palette.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count == 0
                          ? 'Attraction guide coming soon'
                          : '$count attractions to explore',
                      style: TextStyle(
                        color: context.palette.coral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
