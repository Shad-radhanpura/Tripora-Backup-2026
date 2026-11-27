import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/destinations.dart';
import '../data/nearby_services.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Nearby services for each supported city. Records are demo unless they come
/// from the app's own attraction list. No phone numbers or hours are shown,
/// because none has been verified.
class NearbyServicesPage extends StatefulWidget {
  const NearbyServicesPage({super.key});

  @override
  State<NearbyServicesPage> createState() => _NearbyServicesPageState();
}

class _NearbyServicesPageState extends State<NearbyServicesPage> {
  String? _cityId;
  ServiceCategory? _category;
  bool _appOnly = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final results = NearbyServices.search(
      destinationId: _cityId,
      category: _category,
      query: _search.text,
      appCatalogueOnly: _appOnly,
      byCategory: true,
    );
    final cityName = _cityId == null ? null : DestinationCatalog.byId(_cityId!)?.name;
    final anyFilter = _cityId != null || _category != null || _appOnly || _search.text.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Nearby city services')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.warningSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.warningBorder),
                ),
                child: Text(NearbyServices.notice,
                    style: TextStyle(color: palette.warningText, fontSize: 12, height: 1.4)),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('nearby-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name or category',
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
                    child: DropdownButtonFormField<String?>(
                      key: const Key('nearby-city'),
                      initialValue: _cityId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'City', isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All cities')),
                        for (final id in NearbyServices.cityIds)
                          DropdownMenuItem(value: id, child: Text(DestinationCatalog.byId(id)?.name ?? id)),
                      ],
                      onChanged: (v) => setState(() => _cityId = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<ServiceCategory?>(
                      key: const Key('nearby-category'),
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category', isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All categories')),
                        for (final c in ServiceCategory.values)
                          DropdownMenuItem(value: c, child: Text(c.label)),
                      ],
                      onChanged: (v) => setState(() => _category = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      key: const Key('nearby-app-only'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Only places from the app catalogue'),
                      value: _appOnly,
                      onChanged: (v) => setState(() => _appOnly = v),
                    ),
                  ),
                  if (anyFilter)
                    TextButton(
                      key: const Key('nearby-clear'),
                      onPressed: () => setState(() {
                        _cityId = null;
                        _category = null;
                        _appOnly = false;
                        _search.clear();
                      }),
                      child: const Text('Clear filters'),
                    ),
                ],
              ),
              Text(
                '${results.length} record${results.length == 1 ? '' : 's'}'
                '${cityName == null ? '' : ' in $cityName'}',
                key: const Key('nearby-count'),
                style: TextStyle(color: palette.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              if (results.isEmpty)
                EmptyState(
                  icon: Icons.location_off_outlined,
                  title: 'No services match',
                  message: 'Try another city or category, or clear the search.',
                  actionLabel: anyFilter ? 'Clear filters' : null,
                  onAction: anyFilter
                      ? () => setState(() {
                            _cityId = null;
                            _category = null;
                            _appOnly = false;
                            _search.clear();
                          })
                      : null,
                )
              else
                for (final s in results) ...[
                  _ServiceTile(service: s),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final NearbyService service;

  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        key: Key('service-${service.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.border),
        ),
        leading: CircleAvatar(
          backgroundColor: palette.surfaceTint,
          child: Icon(_iconFor(service.category), color: palette.blue),
        ),
        title: Text(service.name, style: TextStyle(color: palette.text, fontWeight: FontWeight.w800)),
        subtitle: Text('${service.category.label} · ${service.city}',
            style: TextStyle(color: palette.muted, fontSize: 12.5)),
        trailing: TagChip(
          label: service.isDemo ? 'DEMO' : 'App catalogue',
          color: service.isDemo ? palette.coral : palette.green,
        ),
        onTap: () => SafeNav.push(context, NearbyServiceDetailPage(serviceId: service.id)),
      ),
    );
  }

  static IconData _iconFor(ServiceCategory c) => switch (c) {
        ServiceCategory.hospital || ServiceCategory.pharmacy => Icons.local_hospital_rounded,
        ServiceCategory.police => Icons.local_police_rounded,
        ServiceCategory.mall || ServiceCategory.market => Icons.shopping_bag_rounded,
        ServiceCategory.cinema => Icons.theaters_rounded,
        ServiceCategory.temple || ServiceCategory.mosque || ServiceCategory.church || ServiceCategory.gurudwara =>
          Icons.temple_hindu_rounded,
        ServiceCategory.school || ServiceCategory.university => Icons.school_rounded,
        ServiceCategory.museum => Icons.museum_rounded,
        ServiceCategory.zoo => Icons.pets_rounded,
        ServiceCategory.amusement || ServiceCategory.gameZone => Icons.sports_esports_rounded,
        ServiceCategory.attraction => Icons.photo_camera_rounded,
        ServiceCategory.atm => Icons.atm_rounded,
        ServiceCategory.transport => Icons.directions_bus_rounded,
      };
}

/// One record in full. The map link opens a search; no coordinates are stored.
class NearbyServiceDetailPage extends StatelessWidget {
  final String serviceId;

  const NearbyServiceDetailPage({super.key, required this.serviceId});

  NearbyService? _find() {
    for (final s in NearbyServices.all) {
      if (s.id == serviceId) return s;
    }
    return null;
  }

  Future<void> _openMap(BuildContext context, NearbyService s) async {
    bool opened;
    try {
      opened = await launchUrl(Uri.parse(s.mapSearchUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showAppMessage(context, 'Could not open the map. Search for "${s.category.singular} in ${s.city}" yourself.',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = _find();
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.location_off_outlined,
          title: 'Record not found',
          message: 'This service is not in the list.',
        ),
      );
    }
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(s.name, overflow: TextOverflow.ellipsis)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              TagChip(
                label: s.isDemo ? 'DEMO RECORD' : 'FROM THE APP CATALOGUE',
                color: s.isDemo ? palette.coral : palette.green,
              ),
              const SizedBox(height: 10),
              Text(s.name,
                  style: TextStyle(color: palette.text, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
              const SizedBox(height: 6),
              Text(s.category.label, style: TextStyle(color: palette.muted)),
              const SizedBox(height: 14),
              _Line(Icons.location_on_outlined, 'Address', s.address),
              _Line(Icons.schedule_rounded, 'Opening hours', s.hours),
              _Line(Icons.call_outlined, 'Contact', s.contact),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('service-open-map'),
                onPressed: () => _openMap(context, s),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Search this on the map'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('service-copy-address'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: s.address));
                  if (context.mounted) showAppMessage(context, 'Address copied.');
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy address'),
              ),
              const SizedBox(height: 14),
              Text(
                s.isDemo
                    ? 'This is a demo record. The name and address are illustrative, not a real place. '
                        'Use the map search to find real ones.'
                    : 'This name comes from Tripora\'s attraction list. Check opening hours and entry '
                        'conditions before you go.',
                style: TextStyle(color: palette.muted, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Line(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: palette.text, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
