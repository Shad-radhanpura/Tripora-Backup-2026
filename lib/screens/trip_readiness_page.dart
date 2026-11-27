import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/checklist_item.dart';
import '../models/destination.dart';
import '../models/saved_trip.dart';
import '../services/checklist_progress.dart';
import '../services/checklist_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'emergency_help_page.dart';

/// Pre-trip readiness for one saved trip.
///
/// Progress is calculated from the trip's stored checklist, so it only moves
/// when the user ticks an item. Packing and etiquette advice is general and
/// labelled as such. No live weather or forecast is used.
class TripReadinessPage extends StatefulWidget {
  final SavedTrip trip;

  const TripReadinessPage({super.key, required this.trip});

  /// Items offered as one-tap additions. Added items are saved to the trip.
  static const List<String> suggestedItems = [
    'Identification documents',
    'Tickets and reservations',
    'Accommodation confirmation',
    'Phone charger',
    'Essential medicines',
    'Clothing suited to the destination',
    'Toiletries',
    'Emergency contacts',
    'Payment methods (cards and cash)',
    'Required travel documents (visa, permits)',
  ];

  @override
  State<TripReadinessPage> createState() => _TripReadinessPageState();
}

class _TripReadinessPageState extends State<TripReadinessPage> {
  late final Future<void> _setup = ChecklistService.ensureDefaults(widget.trip.id);

  Destination? get _destination => DestinationCatalog.matchName(widget.trip.destination);

  Future<void> _toggle(ChecklistItem item) async {
    try {
      await ChecklistService.setDone(widget.trip.id, item.id, !item.done);
    } catch (e) {
      if (mounted) showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  Future<void> _addSuggestion(String label, List<ChecklistItem> items) async {
    final exists = items.any((item) => item.label.toLowerCase() == label.toLowerCase());
    if (exists) {
      showAppMessage(context, '"$label" is already on your list.');
      return;
    }
    try {
      await ChecklistService.addCustom(widget.trip.id, label);
      if (mounted) showAppMessage(context, 'Added "$label".');
    } catch (e) {
      if (mounted) showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  Future<void> _remove(ChecklistItem item) async {
    try {
      await ChecklistService.removeCustom(widget.trip.id, item.id);
    } catch (e) {
      if (mounted) showAppMessage(context, describeFirestoreError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationName = _destination?.name ?? widget.trip.destination;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Trip readiness')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FutureBuilder<void>(
            future: _setup,
            builder: (context, setup) {
              if (setup.hasError) {
                return ErrorState(
                  error: setup.error,
                  title: 'Could not prepare your checklist',
                );
              }
              return StreamBuilder<List<ChecklistItem>>(
                stream: ChecklistService.watch(widget.trip.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorState(
                      error: snapshot.error,
                      title: 'Could not load your checklist',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const LoadingState(message: 'Loading your checklist…');
                  }
                  final items = snapshot.data!;
                  return _content(items, destinationName);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(List<ChecklistItem> items, String destinationName) {
    final todo = items.where((item) => !item.done).toList();
    final done = items.where((item) => item.done).toList();
    final days = widget.trip.days ?? 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      children: [
        _progressCard(items, destinationName),
        const SizedBox(height: 16),
        _sectionTitle('Still to do (${todo.length})'),
        const SizedBox(height: 8),
        if (todo.isEmpty)
          Text(
            'Everything is ticked off. Well done!',
            style: TextStyle(color: context.palette.green, fontWeight: FontWeight.w700),
          )
        else
          for (final item in todo) _itemTile(item),
        const SizedBox(height: 18),
        _sectionTitle('Suggested additions'),
        const SizedBox(height: 4),
        Text(
          'Tap to add to this trip. You can tick them off here.',
          style: TextStyle(color: context.palette.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in TripReadinessPage.suggestedItems)
              ActionChip(
                label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                onPressed: () => _addSuggestion(suggestion, items),
              ),
          ],
        ),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 18),
          _sectionTitle('Completed (${done.length})'),
          const SizedBox(height: 8),
          for (final item in done) _itemTile(item),
        ],
        const SizedBox(height: 18),
        _guidanceCard(days),
        const SizedBox(height: 14),
        _etiquetteCard(),
        const SizedBox(height: 14),
        _documentsCard(),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => SafeNav.push(context, const EmergencyHelpPage()),
          icon: const Icon(Icons.health_and_safety_rounded),
          label: const Text('Emergency help'),
        ),
      ],
    );
  }

  Widget _progressCard(List<ChecklistItem> items, String destinationName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Getting ready for $destinationName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            items.isEmpty ? 'No tasks yet.' : ChecklistProgress.summary(items),
            key: const Key('readiness-summary'),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ChecklistProgress.fraction(items),
              minHeight: 9,
              color: context.palette.coral,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Checkbox(
            key: Key('readiness-check-${item.id}'),
            value: item.done,
            activeColor: context.palette.teal,
            onChanged: (_) => _toggle(item),
          ),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: item.done ? context.palette.muted : context.palette.text,
                decoration: item.done ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (item.custom)
            IconButton(
              tooltip: 'Remove ${item.label}',
              icon: Icon(Icons.delete_outline_rounded, color: context.palette.danger),
              onPressed: () => _remove(item),
            ),
        ],
      ),
    );
  }

  Widget _guidanceCard(int days) {
    final destination = _destination;
    final categories = destination?.categories ?? const <String>[];
    final tips = <String>[
      'Pack about ${days <= 3 ? days : (days / 2).ceil()} sets of clothes and do laundry on longer trips.',
      if (categories.contains('Nature') || categories.contains('Adventure')) ...[
        'Bring warm layers and a waterproof jacket; mountain weather changes quickly.',
        'Wear sturdy walking shoes.',
      ],
      if (categories.contains('Beach')) ...[
        'Pack sunscreen, sunglasses and a hat.',
        'Bring swimwear and a light cover-up.',
      ],
      if (categories.contains('Culture')) ...[
        'Pack clothes that cover shoulders and knees for temples and religious sites.',
        'Wear shoes that are easy to take on and off.',
      ],
      if (categories.contains('Shopping')) 'Carry small notes for markets, plus a card.',
    ];

    return _infoCard(
      icon: Icons.luggage_rounded,
      title: 'Packing guidance',
      label: 'General advice, not a live forecast',
      children: [
        if (destination != null)
          Text(
            'Best time to visit: ${destination.bestTime}',
            style: TextStyle(color: context.palette.text, fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 8),
        for (final tip in tips) _bullet(tip),
      ],
    );
  }

  Widget _etiquetteCard() {
    final categories = _destination?.categories ?? const <String>[];
    return _infoCard(
      icon: Icons.people_alt_rounded,
      title: 'Local travel notes',
      label: 'General guidance',
      children: [
        _bullet('Ask before photographing people, especially at religious sites.'),
        _bullet('Keep the hotel address with you in a language you can show to a driver.'),
        if (categories.contains('Culture'))
          _bullet('Remove shoes before entering temples and some homes.'),
        if (categories.contains('Nature') || categories.contains('Adventure'))
          _bullet('Check local permit rules before trekking or visiting restricted areas.'),
      ],
    );
  }

  Widget _documentsCard() {
    return _infoCard(
      icon: Icons.badge_outlined,
      title: 'Travel documents',
      label: 'Privacy',
      children: [
        _bullet('Tick off the documents you have. Tripora does not store passport or ID photos.'),
        _bullet('Keep copies of important documents somewhere safe, separate from your phone.'),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String label,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.palette.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: context.palette.muted, fontSize: 11.5)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: context.palette.teal, fontWeight: FontWeight.w900)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.palette.text, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: context.palette.text,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
