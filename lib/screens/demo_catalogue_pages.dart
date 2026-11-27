import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_catalogue.dart';
import '../models/saved_trip.dart' show formatDate;
import '../models/tour_package.dart' show formatInr;
import '../services/app_firebase.dart';
import '../services/gift_card_service.dart';
import '../services/offers_service.dart';
import '../services/package_filters.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_image.dart';
import '../widgets/image_detail_dialog.dart';

/// Remembers the traveller's group type and sort between visits.
class CataloguePreferences {
  CataloguePreferences._();

  static const String groupKey = 'catalogue.group';
  static const String sortKey = 'catalogue.sort';

  static Future<(TravelGroup?, PackageSort?)> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final group = TravelGroup.values.where((g) => g.name == prefs.getString(groupKey));
      final sort = PackageSort.values.where((s) => s.name == prefs.getString(sortKey));
      return (group.isEmpty ? null : group.first, sort.isEmpty ? null : sort.first);
    } catch (_) {
      return (null, null);
    }
  }

  static Future<void> save({TravelGroup? group, PackageSort? sort}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (group == null) {
        await prefs.remove(groupKey);
      } else {
        await prefs.setString(groupKey, group.name);
      }
      if (sort != null) await prefs.setString(sortKey, sort.name);
    } catch (_) {
      // Storage is optional; the choice still applies for this visit.
    }
  }
}

/// The demo tour-package catalogue: group type, search, filters, sorting and
/// recommendations. Every price, date and seat count is a demo value.
class DemoCataloguePage extends StatefulWidget {
  const DemoCataloguePage({super.key});

  @override
  State<DemoCataloguePage> createState() => _DemoCataloguePageState();
}

class _DemoCataloguePageState extends State<DemoCataloguePage> {
  PackageFilter _filter = const PackageFilter();
  PackageSort _sort = PackageSort.priceLowToHigh;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    CataloguePreferences.load().then((saved) {
      if (!mounted) return;
      setState(() {
        if (saved.$1 != null) _filter = _filter.copyWith(group: saved.$1);
        if (saved.$2 != null) _sort = saved.$2!;
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  DateTime get _today => DateTime.now();

  void _setGroup(TravelGroup? group) {
    setState(() => _filter = _filter.copyWith(group: group, clearGroup: group == null));
    CataloguePreferences.save(group: group);
  }

  void _clearFilters() {
    setState(() {
      _search.clear();
      _filter = const PackageFilter();
    });
    CataloguePreferences.save(group: null);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<PackageFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (result != null && mounted) setState(() => _filter = result.copyWith(query: _filter.query));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final all = DemoCatalogue.all;
    final results = PackageQuery.apply(
      all,
      _filter.copyWith(query: _search.text),
      sort: _sort,
      today: _today,
    );
    final recommended = _filter.group == null
        ? const <DemoPackage>[]
        : PackageRecommender.recommend(all, group: _filter.group, limit: 3);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Tour packages'),
        actions: [
          IconButton(
            key: const Key('catalogue-filters'),
            tooltip: 'Filters',
            icon: Badge(
              isLabelVisible: !_filter.isEmpty,
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              _DemoBanner(text: DemoCatalogue.notice),
              const SizedBox(height: 12),
              const _SectionLabel('Who are you travelling with?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('group-any'),
                    label: const Text('Anyone'),
                    selected: _filter.group == null,
                    onSelected: (_) => _setGroup(null),
                  ),
                  for (final g in TravelGroup.values)
                    ChoiceChip(
                      key: Key('group-${g.name}'),
                      label: Text(g.label),
                      selected: _filter.group == g,
                      onSelected: (_) => _setGroup(g),
                    ),
                ],
              ),
              if (_filter.group != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_filter.group!.description,
                      style: TextStyle(color: palette.muted, fontSize: 12.5)),
                ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('catalogue-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by city, state, category or package name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(_search.clear),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PackageSort>(
                      key: const Key('catalogue-sort'),
                      initialValue: _sort,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sort by', isDense: true),
                      items: [
                        for (final s in PackageSort.values)
                          DropdownMenuItem(value: s, child: Text(s.label)),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _sort = v);
                        CataloguePreferences.save(sort: v);
                      },
                    ),
                  ),
                  if (!_filter.isEmpty || _search.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      key: const Key('catalogue-clear'),
                      onPressed: _clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${results.length} of ${all.length} packages',
                key: const Key('catalogue-count'),
                style: TextStyle(color: palette.muted, fontSize: 12.5),
              ),
              if (recommended.isNotEmpty && _search.text.isEmpty && _filter.isEmpty) ...[
                const SizedBox(height: 14),
                _SectionLabel('Recommended for ${_filter.group!.label.toLowerCase()} travellers'),
                for (final p in recommended) ...[
                  _PackageCard(package: p, group: _filter.group),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 12),
              if (results.isEmpty)
                EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No packages match these filters',
                  message: 'Try a wider price range, another city, or clear the filters.',
                  actionLabel: 'Clear filters',
                  onAction: _clearFilters,
                )
              else
                for (final p in results) ...[
                  _PackageCard(package: p, group: _filter.group),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final PackageFilter initial;

  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late PackageFilter _f = widget.initial;
  late RangeValues _price = RangeValues(
    (_f.minPrice ?? demoPriceLadder.first).toDouble(),
    (_f.maxPrice ?? demoPriceLadder.last).toDouble(),
  );
  late RangeValues _days = RangeValues(
    (_f.minDays ?? 3).toDouble(),
    (_f.maxDays ?? 15).toDouble(),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cities = DemoCatalogue.indianDestinationIds
        .map((id) => DemoCatalogue.all.firstWhere((p) => p.destinationId == id))
        .toList();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: TextStyle(color: palette.text, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: const Key('filter-city'),
              initialValue: _f.destinationId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'City'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any city')),
                for (final p in cities)
                  DropdownMenuItem(value: p.destinationId, child: Text('${p.city}, ${p.state}')),
              ],
              onChanged: (v) => setState(() => _f = _f.copyWith(destinationId: v, clearDestination: v == null)),
            ),
            const SizedBox(height: 14),
            Text('Price per person: ${formatInr(_price.start.round())} to ${formatInr(_price.end.round())}',
                style: TextStyle(color: palette.text)),
            RangeSlider(
              key: const Key('filter-price'),
              min: demoPriceLadder.first.toDouble(),
              max: demoPriceLadder.last.toDouble(),
              values: _price,
              onChanged: (v) => setState(() => _price = v),
            ),
            const SizedBox(height: 6),
            Text('Duration: ${_days.start.round()} to ${_days.end.round()} days',
                style: TextStyle(color: palette.text)),
            RangeSlider(
              key: const Key('filter-days'),
              min: 3,
              max: 15,
              divisions: 12,
              values: _days,
              onChanged: (v) => setState(() => _days = v),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              key: const Key('filter-category'),
              initialValue: _f.category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Interest or category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any category')),
                for (final c in _categories())
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _f = _f.copyWith(category: v, clearCategory: v == null)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('filter-dates'),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: demoFirstDeparture,
                  lastDate: DateTime(2027, 12, 31),
                  initialDateRange: _f.departureFrom == null || _f.departureTo == null
                      ? null
                      : DateTimeRange(start: _f.departureFrom!, end: _f.departureTo!),
                );
                if (range != null) {
                  setState(() => _f = _f.copyWith(departureFrom: range.start, departureTo: range.end));
                }
              },
              icon: const Icon(Icons.date_range_rounded),
              label: Text(_f.departureFrom == null
                  ? 'Departure dates: any'
                  : 'Departs ${formatDate(_f.departureFrom)} to ${formatDate(_f.departureTo)}'),
            ),
            if (_f.departureFrom != null)
              TextButton(
                onPressed: () => setState(() => _f = _f.copyWith(clearDates: true)),
                child: const Text('Clear dates'),
              ),
            SwitchListTile(
              key: const Key('filter-available'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Only packages with seats left (demo inventory)'),
              value: _f.availableOnly,
              onChanged: (v) => setState(() => _f = _f.copyWith(availableOnly: v)),
            ),
            DropdownButtonFormField<double?>(
              key: const Key('filter-rating'),
              initialValue: _f.minRating,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Minimum demo rating'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any rating')),
                DropdownMenuItem(value: 4.0, child: Text('4.0 and above')),
                DropdownMenuItem(value: 4.5, child: Text('4.5 and above')),
              ],
              onChanged: (v) => setState(() => _f = _f.copyWith(minRating: v, clearRating: v == null)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _f = PackageFilter(group: _f.group);
                      _price = RangeValues(demoPriceLadder.first.toDouble(), demoPriceLadder.last.toDouble());
                      _days = const RangeValues(3, 15);
                    }),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('filter-apply'),
                    onPressed: () {
                      final fullPrice = _price.start <= demoPriceLadder.first && _price.end >= demoPriceLadder.last;
                      final fullDays = _days.start <= 3 && _days.end >= 15;
                      Navigator.pop(
                        context,
                        _f.copyWith(
                          minPrice: fullPrice ? null : _price.start.round(),
                          maxPrice: fullPrice ? null : _price.end.round(),
                          clearPrice: fullPrice,
                          minDays: fullDays ? null : _days.start.round(),
                          maxDays: fullDays ? null : _days.end.round(),
                          clearDays: fullDays,
                        ),
                      );
                    },
                    child: const Text('Show results'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _categories() {
    final set = <String>{for (final p in DemoCatalogue.all) p.category};
    return set.toList()..sort();
  }
}

class _PackageCard extends StatelessWidget {
  final DemoPackage package;
  final TravelGroup? group;

  const _PackageCard({required this.package, this.group});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final today = DateTime.now();
    final bookable = package.isBookableFrom(today);
    final reason = group == null ? null : PackageRecommender.score(package, group: group);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('package-card-${package.id}'),
        onTap: () => SafeNav.push(context, DemoPackageDetailPage(packageId: package.id, group: group)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(url: package.imageUrl, label: package.city),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: TagChip(label: 'DEMO', color: palette.coral, onDark: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.title,
                      style: TextStyle(color: palette.text, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${package.city}, ${package.state} · ${package.durationLabel}',
                      style: TextStyle(color: palette.muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text('${formatInr(package.pricePerPerson)} per person',
                            style: TextStyle(color: palette.blue, fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                      TagChip(
                        label: bookable ? 'Seats available (demo)' : 'Sold out (demo)',
                        color: bookable ? palette.green : palette.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Demo rating ${package.demoRating.toStringAsFixed(1)} (${package.demoReviews} reviews, demo)',
                    style: TextStyle(color: palette.muted, fontSize: 11.5),
                  ),
                  if (reason != null && reason > 0) ...[
                    const SizedBox(height: 6),
                    Text('Good fit for ${group!.label.toLowerCase()} travellers',
                        style: TextStyle(color: palette.teal, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One package in full, with departures, terms and the booking preview.
class DemoPackageDetailPage extends StatefulWidget {
  final String packageId;
  final TravelGroup? group;

  const DemoPackageDetailPage({super.key, required this.packageId, this.group});

  @override
  State<DemoPackageDetailPage> createState() => _DemoPackageDetailPageState();
}

class _DemoPackageDetailPageState extends State<DemoPackageDetailPage> {
  DemoDeparture? _departure;
  int _travellers = 2;
  final _coupon = TextEditingController();
  DemoOffer? _appliedOffer;
  int _couponDiscount = 0;
  String? _couponMessage;
  DemoGiftCard? _giftCard;
  int _giftApplied = 0;

  DemoPackage? get _pkg => DemoCatalogue.byId(widget.packageId);

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final pkg = _pkg;
    if (pkg == null) return;
    final uid = AppFirebase.auth.currentUser?.uid ?? '';
    final check = CouponValidator.check(
      code: _coupon.text,
      package: pkg,
      group: widget.group,
      travellers: _travellers,
      today: DateTime.now(),
      usesByPerson: 0,
      totalUses: 0,
    );
    setState(() {
      _couponMessage = check.message;
      if (check.valid) {
        _appliedOffer = check.offer;
        _couponDiscount = check.discount;
      } else {
        _appliedOffer = null;
        _couponDiscount = 0;
      }
    });
    if (uid.isEmpty) {
      showAppMessage(context, 'Sign in to use a coupon in the preview.', error: true);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedOffer = null;
      _couponDiscount = 0;
      _couponMessage = 'Coupon removed.';
      _coupon.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pkg = _pkg;
    if (pkg == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Package not found',
          message: 'This demo package is not in the catalogue.',
        ),
      );
    }
    final today = DateTime.now();
    final departures = pkg.departures;
    final selectable = departures.where((d) => !d.soldOut && !_isPast(d.date, today)).toList();
    final departure = _departure != null && selectable.contains(_departure) ? _departure : null;
    final breakdown = PriceBreakdown.calculate(
      pricePerPerson: pkg.pricePerPerson,
      travellers: _travellers,
      couponDiscount: _couponDiscount,
      giftCardBalance: _giftApplied,
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(pkg.city)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              _DemoBanner(text: DemoCatalogue.notice),
              const SizedBox(height: 12),
              GestureDetector(
                key: const Key('package-photo'),
                onTap: () => showImageDetailDialog(
                  context,
                  image: ColoredBox(
                    color: Colors.black,
                    child: DestinationImage(url: pkg.imageUrl, label: pkg.city, fit: BoxFit.contain),
                  ),
                  title: pkg.city,
                  footer: 'Photo credit: ${pkg.imageCredit}',
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: DestinationImage(url: pkg.imageUrl, label: pkg.city),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(pkg.title,
                  style: TextStyle(color: palette.text, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
              const SizedBox(height: 6),
              Text('${pkg.city}, ${pkg.state} · ${pkg.durationLabel} · ${pkg.category}',
                  style: TextStyle(color: palette.muted)),
              const SizedBox(height: 4),
              Text('Demo rating ${pkg.demoRating.toStringAsFixed(1)} (${pkg.demoReviews} reviews, demo)',
                  style: TextStyle(color: palette.muted, fontSize: 12)),
              const SizedBox(height: 12),
              _Block(
                title: 'Price',
                child: Text(
                  '${formatInr(pkg.pricePerPerson)} per person. ${pkg.pricingBasis} (Demo price, not a live quote.)',
                  style: TextStyle(color: palette.text, height: 1.45),
                ),
              ),
              _Block(
                title: 'Stay, transport and season',
                child: Text(
                  'Hotel: ${pkg.hotel}\nTransport: ${pkg.transport}\nBest season: ${pkg.season}',
                  style: TextStyle(color: palette.text, height: 1.5),
                ),
              ),
              _Block(
                title: 'Day by day (demo itinerary)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final day in pkg.itinerary)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${day.days}: ${day.title}. ${day.details}',
                            style: TextStyle(color: palette.text, height: 1.4)),
                      ),
                  ],
                ),
              ),
              _Block(
                title: 'Included',
                child: _Bullets(items: pkg.inclusions, color: palette.green),
              ),
              _Block(
                title: 'Not included',
                child: _Bullets(items: pkg.exclusions, color: palette.danger),
              ),
              _Block(
                title: 'Who it suits',
                child: Text(
                  pkg.groupTypes.map((g) => g.label).join(', '),
                  style: TextStyle(color: palette.text),
                ),
              ),
              _Block(
                title: 'Cancellation and terms',
                child: Text(
                  '${pkg.cancellationPolicy}\n\nPrices, seats and dates are illustrative. Terms of a real '
                  'operator would apply to a real booking. This demo cannot make a booking.',
                  style: TextStyle(color: palette.text, height: 1.45),
                ),
              ),
              _Block(
                title: 'Departure dates (demo inventory)',
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                  children: [
                    for (final d in departures)
                      ListTile(
                        key: Key('departure-${d.date.millisecondsSinceEpoch}'),
                        contentPadding: EdgeInsets.zero,
                        selected: departure == d,
                        leading: Icon(
                          departure == d ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: departure == d ? palette.blue : palette.muted,
                        ),
                        title: Text(formatDate(d.date)),
                        subtitle: Text(
                          _isPast(d.date, today)
                              ? 'Date has passed'
                              : d.soldOut
                                  ? 'Sold out (demo)'
                                  : '${d.seatsLeft} seats left (demo)',
                          style: TextStyle(color: palette.muted),
                        ),
                        onTap: (d.soldOut || _isPast(d.date, today))
                            ? null
                            : () => setState(() => _departure = d),
                      ),
                  ],
                  ),
                ),
              ),
              _Block(
                title: 'Booking preview (no booking is made)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Travellers')),
                        IconButton(
                          tooltip: 'Fewer',
                          onPressed: _travellers > 1 ? () => setState(() => _travellers--) : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Text('$_travellers', key: const Key('preview-travellers')),
                        IconButton(
                          tooltip: 'More',
                          onPressed: _travellers < 9 ? () => setState(() => _travellers++) : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                      ],
                    ),
                    if (widget.group != null)
                      Text('Travelling as: ${widget.group!.label}', style: TextStyle(color: palette.muted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('coupon-input'),
                            controller: _coupon,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: 'Coupon code (demo)', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('coupon-apply'),
                          onPressed: _applyCoupon,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    if (_couponMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_couponMessage!,
                            key: const Key('coupon-message'),
                            style: TextStyle(color: _appliedOffer == null ? palette.danger : palette.green)),
                      ),
                    if (_appliedOffer != null)
                      TextButton(
                        key: const Key('coupon-remove'),
                        onPressed: _removeCoupon,
                        child: const Text('Remove coupon'),
                      ),
                    const SizedBox(height: 8),
                    _GiftCardPicker(
                      selected: _giftCard,
                      applied: _giftApplied,
                      subtotal: breakdown.subtotal - breakdown.couponDiscount,
                      onChanged: (card, amount) => setState(() {
                        _giftCard = card;
                        _giftApplied = amount;
                      }),
                    ),
                    const Divider(height: 26),
                    _PriceRow('Subtotal ($_travellers × ${formatInr(pkg.pricePerPerson)})', formatInr(breakdown.subtotal)),
                    if (breakdown.couponDiscount > 0)
                      _PriceRow('Coupon ${_appliedOffer!.code}', '− ${formatInr(breakdown.couponDiscount)}'),
                    if (breakdown.giftCardApplied > 0)
                      _PriceRow('Demo gift card', '− ${formatInr(breakdown.giftCardApplied)}'),
                    _PriceRow('Total in this demo preview', formatInr(breakdown.total), bold: true),
                    const SizedBox(height: 10),
                    Text(
                      departure == null
                          ? 'Choose a departure date to continue.'
                          : 'Departure ${formatDate(departure.date)} · ${departure.seatsLeft} seats left (demo).',
                      key: const Key('preview-departure'),
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      key: const Key('preview-continue'),
                      onPressed: departure == null
                          ? null
                          : () => showAppMessage(
                                context,
                                'Demo preview only. No booking, payment or gift-card charge was made.',
                              ),
                      icon: const Icon(Icons.fact_check_rounded),
                      label: const Text('Review demo preview'),
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

  static bool _isPast(DateTime date, DateTime today) {
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    return d.isBefore(t);
  }
}

class _GiftCardPicker extends StatelessWidget {
  final DemoGiftCard? selected;
  final int applied;
  final int subtotal;
  final void Function(DemoGiftCard? card, int amount) onChanged;

  const _GiftCardPicker({
    required this.selected,
    required this.applied,
    required this.subtotal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uid = AppFirebase.auth.currentUser?.uid ?? '';
    final palette = context.palette;
    return ListenableBuilder(
      listenable: GiftCardStore.instance,
      builder: (context, _) {
        final store = GiftCardStore.instance;
        if (uid.isEmpty) {
          return Text('Sign in to use a demo gift card in the preview.', style: TextStyle(color: palette.muted));
        }
        final usable = store.cardsFor(uid).where((c) => c.statusOn(DateTime.now()) == 'Active (demo)').toList();
        if (usable.isEmpty) {
          return Text('No active demo gift cards. Buy one from Gift cards (demo).',
              style: TextStyle(color: palette.muted, fontSize: 12.5));
        }
        final card = selected != null && usable.any((c) => c.code == selected!.code) ? selected : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String?>(
              key: const Key('preview-giftcard'),
              initialValue: card?.code,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Use a demo gift card (optional)', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('No gift card')),
                for (final c in usable)
                  DropdownMenuItem(
                    value: c.code,
                    child: Text('${c.code} · balance ${formatInr(c.balance)}'),
                  ),
              ],
              onChanged: (code) {
                if (code == null) {
                  onChanged(null, 0);
                  return;
                }
                final picked = usable.firstWhere((c) => c.code == code);
                onChanged(picked, picked.balance < subtotal ? picked.balance : subtotal);
              },
            ),
            if (card != null)
              Text('Up to ${formatInr(card.balance)} will be applied to this preview (demo).',
                  style: TextStyle(color: palette.muted, fontSize: 12)),
          ],
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _PriceRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(
      color: palette.text,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final Widget child;

  const _Block({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: palette.navy, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  final Color color;

  const _Bullets({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 7, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: TextStyle(color: palette.text, height: 1.35))),
              ],
            ),
          ),
      ],
    );
  }
}

class _DemoBanner extends StatelessWidget {
  final String text;

  const _DemoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.warningSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.warningBorder),
      ),
      child: Text(text, style: TextStyle(color: palette.warningText, fontSize: 12, height: 1.4)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(color: context.palette.navy, fontSize: 15, fontWeight: FontWeight.w900)),
    );
  }
}
