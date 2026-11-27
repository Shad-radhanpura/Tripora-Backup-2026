import 'package:flutter/material.dart';

import '../data/tour_packages.dart';
import '../models/tour_package.dart';
import '../services/package_store.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_image.dart';
import 'booking_form_screen.dart';
import 'trip_details_screen.dart';

/// Tour Packages tab: search, duration / category / budget filters and
/// sorting over the merged package list (see [PackageStore]).
class PackagesView extends StatefulWidget {
  const PackagesView({super.key});

  @override
  State<PackagesView> createState() => _PackagesViewState();
}

class _PackagesViewState extends State<PackagesView> {
  static const _budgets = <int?, String>{
    null: 'Any budget',
    50000: 'Up to ₹50,000',
    100000: 'Up to ₹1,00,000',
    200000: 'Up to ₹2,00,000',
  };

  final _search = TextEditingController();
  String _query = '';
  int? _days;
  String? _category;
  int? _maxPrice;
  String _sort = 'days';

  @override
  void initState() {
    super.initState();
    PackageStore.instance.start();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    setState(() {
      _query = '';
      _days = null;
      _category = null;
      _maxPrice = null;
      _sort = 'days';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PackageStore.instance,
      builder: (context, _) {
        final store = PackageStore.instance;
        final results = PackageStore.filter(
          store.visible,
          query: _query,
          days: _days,
          category: _category,
          maxPrice: _maxPrice,
          sort: _sort,
        );

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 4),
                child: SectionHeader(
                  title: 'Tour Packages',
                  subtitle: '10, 15, 20 and 30-day trips with stays, '
                      'transport and sightseeing.',
                ),
              ),
            ),
            SliverToBoxAdapter(child: _filters()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${results.length} '
                        '${results.length == 1 ? 'package' : 'packages'}',
                        style: TextStyle(
                            color: context.palette.muted, fontWeight: FontWeight.w700),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _sort,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'days', child: Text('Shortest first')),
                        DropdownMenuItem(
                            value: 'price-low', child: Text('Price: low to high')),
                        DropdownMenuItem(
                            value: 'price-high', child: Text('Price: high to low')),
                      ],
                      onChanged: (v) => setState(() => _sort = v ?? 'days'),
                    ),
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No packages match',
                  message: 'Try a different duration, budget or search.',
                  actionLabel: 'Clear filters',
                  onAction: _reset,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                sliver: SliverList.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => PackageCard(
                    package: results[i],
                    onTap: () => SafeNav.push(
                      context,
                      PackageDetailsScreen(package: results[i]),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _filters() {
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search city, region or package',
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
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            children: [
              chip('Any length', _days == null, () => setState(() => _days = null)),
              for (final d in TourPackageCatalog.durations)
                chip('$d days', _days == d, () => setState(() => _days = d)),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            children: [
              chip('All types', _category == null,
                  () => setState(() => _category = null)),
              for (final c in TourPackageCatalog.categories)
                chip(c, _category == c, () => setState(() => _category = c)),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            children: [
              for (final entry in _budgets.entries)
                chip(entry.value, _maxPrice == entry.key,
                    () => setState(() => _maxPrice = entry.key)),
            ],
          ),
        ),
      ],
    );
  }
}

class PackageCard extends StatelessWidget {
  final TourPackage package;
  final VoidCallback onTap;

  const PackageCard({super.key, required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = package;
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(url: p.imageUrl, label: p.title, cacheWidth: 900),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: TagChip(
                      label: '${p.durationDays} DAYS',
                      color: Colors.white,
                      icon: Icons.schedule_rounded,
                      onDark: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: context.palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.route,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.palette.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TagChip(label: p.category, color: context.palette.purple),
                      TagChip(
                          label: p.hotelClass,
                          color: context.palette.teal,
                          icon: Icons.hotel_rounded),
                      TagChip(label: p.region, color: context.palette.blue),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.facilities.length} facilities included',
                          style: TextStyle(
                              color: context.palette.muted, fontSize: 12),
                        ),
                      ),
                      Text(
                        formatInr(p.pricePerPerson),
                        style: TextStyle(
                          color: context.palette.blue,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(' /person',
                          style: TextStyle(color: context.palette.muted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackageDetailsScreen extends StatelessWidget {
  final TourPackage package;

  const PackageDetailsScreen({super.key, required this.package});

  void _book(BuildContext context) {
    final p = package;
    SafeNav.push(
      context,
      BookingFormScreen(
        draft: BookingDraft(
          kind: 'package',
          itemId: p.id,
          title: p.title,
          subtitle: '${p.durationLabel} • ${p.route}',
          unitPrice: p.pricePerPerson,
          unitLabel: 'per person',
          quantityLabel: 'Travellers',
          initialDate: DateTime.now().add(const Duration(days: 21)),
          initialQuantity: 2,
          details: {
            'Duration': p.durationLabel,
            'Hotels': p.hotelClass,
            'Route': p.route,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = package;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            foregroundColor: Colors.white,
            backgroundColor: context.palette.navy,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(url: p.imageUrl, label: p.title),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: context.palette.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(p.durationLabel,
                          style: TextStyle(
                              color: context.palette.blue, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TagChip(label: p.category, color: context.palette.purple),
                          TagChip(label: p.hotelClass, color: context.palette.teal),
                          TagChip(label: p.region, color: context.palette.blue),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(p.description,
                          style: TextStyle(height: 1.5, color: context.palette.text)),
                      _section(context, 'Route'),
                      Text(p.route, style: const TextStyle(height: 1.5)),
                      _section(context, 'Highlights'),
                      for (final h in p.highlights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 18, color: context.palette.orange),
                              const SizedBox(width: 8),
                              Expanded(child: Text(h)),
                            ],
                          ),
                        ),
                      _section(context, 'Facilities included'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final f in p.facilities)
                            Chip(
                              avatar: Icon(Icons.check_rounded,
                                  size: 16, color: context.palette.green),
                              label: Text(f, style: const TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      _section(context, 'Day-by-day itinerary'),
                      for (final day in p.itinerary) _DayTile(day: day),
                      const SizedBox(height: 14),
                      const DemoNotice(
                        message: 'Sample package with indicative prices for '
                            'twin sharing. Booking creates a demo request; '
                            'it is not a confirmed reservation.',
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => SafeNav.push(
                          context,
                          TripDetailsScreen(
                            initialDestination:
                                p.cities.isEmpty ? null : p.cities.first,
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          'Plan a custom AI trip to '
                          '${p.cities.isEmpty ? 'this destination' : p.cities.first}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          decoration: BoxDecoration(
            color: context.palette.surface,
            border: Border(top: BorderSide(color: context.palette.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatInr(p.pricePerPerson),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.palette.blue,
                      ),
                    ),
                    Text('per person (sample)',
                        style: TextStyle(color: context.palette.muted, fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                key: const Key('book-package'),
                onPressed: () => _book(context),
                icon: const Icon(Icons.event_available_rounded),
                label: const Text('Book package'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: context.palette.text,
          ),
        ),
      );
}

class _DayTile extends StatelessWidget {
  final PackageDay day;

  const _DayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              day.days,
              style: TextStyle(
                color: context.palette.blue,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(day.details,
                    style: TextStyle(
                        color: context.palette.muted, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
