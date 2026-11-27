import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../data/tour_packages.dart';
import '../models/tour_package.dart';
import '../services/firestore_service.dart';
import '../services/package_store.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'packages_screen.dart';

/// Admin: every tour package (built-in and admin-created), with create,
/// edit, hide / show, restore-default and delete. Changes are written to
/// `packages/{id}` and appear for every user immediately.
class AdminPackagesPage extends StatefulWidget {
  const AdminPackagesPage({super.key});

  @override
  State<AdminPackagesPage> createState() => _AdminPackagesPageState();
}

class _AdminPackagesPageState extends State<AdminPackagesPage> {
  int? _days;

  @override
  void initState() {
    super.initState();
    PackageStore.instance.start();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action().timeout(const Duration(seconds: 15));
      if (mounted) showAppMessage(context, done);
    } catch (e) {
      if (mounted) showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _edit([TourPackage? package]) {
    SafeNav.push(context, PackageEditorPage(package: package));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Package Management')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-package'),
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New package'),
      ),
      body: ListenableBuilder(
        listenable: PackageStore.instance,
        builder: (context, _) {
          final store = PackageStore.instance;
          final packages = store.allIncludingHidden
              .where((p) => _days == null || p.durationDays == _days)
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                children: [
                  if (store.lastError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DemoNotice(
                        message: 'Could not read the packages collection: '
                            '${describeFirestoreError(store.lastError)} '
                            'Showing built-in packages only.',
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _days == null,
                        onSelected: (_) => setState(() => _days = null),
                      ),
                      for (final d in TourPackageCatalog.durations)
                        ChoiceChip(
                          label: Text('$d days'),
                          selected: _days == d,
                          onSelected: (_) => setState(() => _days = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final p in packages) _tile(p, store),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(TourPackage p, PackageStore store) {
    final overridden = store.isOverridden(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.active ? context.palette.surface : context.palette.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            '${p.durationLabel} • ${formatInr(p.pricePerPerson)}/person • '
            '${p.route}',
            style: TextStyle(color: context.palette.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TagChip(
                label: p.builtIn ? 'Built-in' : 'Admin-created',
                color: context.palette.navy,
              ),
              if (p.builtIn && overridden)
                TagChip(label: 'Edited', color: context.palette.purple),
              TagChip(
                label: p.active ? 'Visible' : 'Hidden',
                color: p.active ? context.palette.green : context.palette.danger,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => SafeNav.push(
                    context, PackageDetailsScreen(package: p)),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
              ),
              TextButton.icon(
                onPressed: () => _edit(p),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _run(
                  () => FirestoreService.savePackage(
                      p.copyWith(active: !p.active)),
                  p.active ? '${p.title} hidden.' : '${p.title} is visible.',
                ),
                icon: Icon(
                    p.active
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_rounded,
                    size: 18),
                label: Text(p.active ? 'Hide' : 'Show'),
              ),
              if (p.builtIn && overridden)
                TextButton.icon(
                  onPressed: () async {
                    if (await _confirm('Restore default?',
                        'Your edits to "${p.title}" will be discarded.')) {
                      await _run(() => FirestoreService.deletePackage(p.id),
                          'Default restored.');
                    }
                  },
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Restore default'),
                ),
              if (!p.builtIn)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: context.palette.danger),
                  onPressed: () async {
                    if (await _confirm('Delete package?',
                        '"${p.title}" will be removed for all users.')) {
                      await _run(() => FirestoreService.deletePackage(p.id),
                          'Package deleted.');
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Create or edit a package.
class PackageEditorPage extends StatefulWidget {
  final TourPackage? package;

  const PackageEditorPage({super.key, this.package});

  @override
  State<PackageEditorPage> createState() => _PackageEditorPageState();
}

class _PackageEditorPageState extends State<PackageEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _cities;
  late final TextEditingController _region;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _highlights;
  late final TextEditingController _itinerary;
  late int _days;
  late String _category;
  late String _hotelClass;
  late Set<String> _facilities;
  late bool _active;
  String? _imageFrom;
  bool _saving = false;

  bool get _isNew => widget.package == null;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _title = TextEditingController(text: p?.title ?? '');
    _cities = TextEditingController(text: p?.cities.join(', ') ?? '');
    _region = TextEditingController(text: p?.region ?? '');
    _price = TextEditingController(
        text: p == null ? '' : p.pricePerPerson.toString());
    _description = TextEditingController(text: p?.description ?? '');
    _highlights = TextEditingController(text: p?.highlights.join('\n') ?? '');
    _itinerary = TextEditingController(
      text: p?.itinerary
              .map((d) => '${d.days} | ${d.title} | ${d.details}')
              .join('\n') ??
          '',
    );
    _days = p?.durationDays ?? 10;
    _category = p != null && TourPackageCatalog.categories.contains(p.category)
        ? p.category
        : TourPackageCatalog.categories.first;
    _hotelClass = p != null && TourPackageCatalog.hotelClasses.contains(p.hotelClass)
        ? p.hotelClass
        : '3-star';
    _facilities = {...?p?.facilities};
    _active = p?.active ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _cities,
      _region,
      _price,
      _description,
      _highlights,
      _itinerary,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<PackageDay> _parseItinerary() {
    return _itinerary.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
      final parts = line.split('|').map((p) => p.trim()).toList();
      return PackageDay(
        parts.isNotEmpty ? parts[0] : '',
        parts.length > 1 ? parts[1] : '',
        parts.length > 2 ? parts.sublist(2).join(' | ') : '',
      );
    }).toList();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_facilities.isEmpty) {
      showAppMessage(context, 'Select at least one facility.', error: true);
      return;
    }

    final old = widget.package;
    var imageUrl = old?.imageUrl ?? '';
    if (_imageFrom != null) {
      imageUrl = DestinationCatalog.all
          .firstWhere((d) => d.id == _imageFrom)
          .imageUrl;
    }

    final package = TourPackage(
      id: old?.id ?? FirestoreService.newPackageId(),
      title: _title.text.trim(),
      durationDays: _days,
      cities: _cities.text
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList(),
      region: _region.text.trim(),
      category: _category,
      pricePerPerson: int.parse(_price.text.trim()),
      hotelClass: _hotelClass,
      facilities: TourPackageCatalog.allFacilities
          .where(_facilities.contains)
          .toList(),
      highlights: _highlights.text
          .split('\n')
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList(),
      itinerary: _parseItinerary(),
      description: _description.text.trim(),
      imageUrl: imageUrl,
      active: _active,
    );

    setState(() => _saving = true);
    try {
      await FirestoreService.savePackage(package)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      showAppMessage(context, _isNew ? 'Package created.' : 'Package saved.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(_isNew ? 'New package' : 'Edit package')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                TextFormField(
                  key: const Key('pkg-title'),
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Package title'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _days,
                        decoration: const InputDecoration(labelText: 'Duration'),
                        items: [
                          for (final d in TourPackageCatalog.durations)
                            DropdownMenuItem(value: d, child: Text('$d days')),
                        ],
                        onChanged: (v) => setState(() => _days = v ?? _days),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('pkg-price'),
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Price per person (₹)'),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return n == null || n < 1000 || n > 2000000
                              ? '₹1,000 – ₹20,00,000'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('pkg-cities'),
                  controller: _cities,
                  decoration: const InputDecoration(
                      labelText: 'Cities (comma separated)'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _region,
                  decoration: const InputDecoration(
                      labelText: 'Region (e.g. North India)'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: [
                          for (final c in TourPackageCatalog.categories)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) =>
                            setState(() => _category = v ?? _category),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _hotelClass,
                        decoration: const InputDecoration(labelText: 'Hotels'),
                        items: [
                          for (final h in TourPackageCatalog.hotelClasses)
                            DropdownMenuItem(value: h, child: Text(h)),
                        ],
                        onChanged: (v) =>
                            setState(() => _hotelClass = v ?? _hotelClass),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _imageFrom,
                  decoration: InputDecoration(
                    labelText: _isNew || (widget.package?.imageUrl ?? '').isEmpty
                        ? 'Cover photo'
                        : 'Cover photo (keep current)',
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(_isNew ? 'No photo' : 'Keep current photo'),
                    ),
                    for (final d in DestinationCatalog.all)
                      DropdownMenuItem<String?>(
                          value: d.id, child: Text('Photo of ${d.name}')),
                  ],
                  onChanged: (v) => setState(() => _imageFrom = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _highlights,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Highlights (one per line)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('pkg-itinerary'),
                  controller: _itinerary,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Itinerary: one line per stop',
                    hintText: 'Days 1–3 | Jaipur | Amber Fort, City Palace…',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => _required(v) ??
                      (_parseItinerary().any((d) => d.title.isEmpty)
                          ? 'Use the format: Days | Title | Details'
                          : null),
                ),
                const SizedBox(height: 16),
                const Text('Facilities',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in TourPackageCatalog.allFacilities)
                      FilterChip(
                        label: Text(f),
                        selected: _facilities.contains(f),
                        onSelected: (on) => setState(() {
                          on ? _facilities.add(f) : _facilities.remove(f);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text('Visible to travellers'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    key: const Key('save-package'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Saving…' : 'Save package'),
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
