import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/saved_trip.dart';
import '../models/travel_experience.dart';
import '../services/app_firebase.dart';
import '../services/experience_store.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Write a new travel experience, or edit one you wrote ([existing]).
/// Returns the saved experience to the previous screen.
class ExperienceEditorPage extends StatefulWidget {
  final TravelExperience? existing;

  const ExperienceEditorPage({super.key, this.existing});

  @override
  State<ExperienceEditorPage> createState() => _ExperienceEditorPageState();
}

class _ExperienceEditorPageState extends State<ExperienceEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _story = TextEditingController(text: widget.existing?.story ?? '');
  late final _tips = TextEditingController(text: widget.existing?.tips ?? '');
  late final _highlights = TextEditingController(
    text: widget.existing?.highlights.join('\n') ?? '',
  );
  late String? _destinationId = widget.existing?.destinationId;
  late String? _tripId = widget.existing?.tripId;
  late int? _rating = widget.existing?.rating;
  bool _showRatingError = false;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _story.dispose();
    _tips.dispose();
    _highlights.dispose();
    super.dispose();
  }

  /// Picking a saved trip fills in its destination when the name matches one
  /// in the catalogue. The destination can still be changed by hand.
  void _pickTrip(String? tripId, List<SavedTrip> trips) {
    setState(() {
      _tripId = tripId;
      if (tripId == null) return;
      final trip = trips.where((t) => t.id == tripId).firstOrNull;
      final match = trip == null ? null : DestinationCatalog.matchName(trip.destination);
      if (match != null) _destinationId = match.id;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showRatingError = _rating == null);
    if (!formValid || _rating == null) return;

    final destination = DestinationCatalog.byId(_destinationId ?? '');
    if (destination == null) return;
    final user = AppFirebase.auth.currentUser;
    final uid = user?.uid ?? '';
    final highlights = ExperienceRules.parseHighlights(_highlights.text);

    setState(() => _saving = true);
    try {
      final TravelExperience saved;
      if (_editing) {
        saved = await ExperienceStore.instance.update(
          uid: uid,
          id: widget.existing!.id,
          destinationId: destination.id,
          destinationName: destination.name,
          tripId: _tripId,
          title: _title.text,
          story: _story.text,
          tips: _tips.text,
          highlights: highlights,
          rating: _rating!,
        );
      } else {
        saved = await ExperienceStore.instance.create(
          authorId: uid,
          authorName: user?.displayName ?? '',
          destinationId: destination.id,
          destinationName: destination.name,
          tripId: _tripId,
          title: _title.text,
          story: _story.text,
          tips: _tips.text,
          highlights: highlights,
          rating: _rating!,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
      showAppMessage(
        context,
        _editing
            ? 'Experience updated on this device.'
            : 'Experience saved on this device.',
      );
    } on ArgumentError catch (e) {
      if (mounted) showAppMessage(context, '${e.message}', error: true);
    } catch (e) {
      if (mounted) showAppMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final uid = AppFirebase.auth.currentUser?.uid;
    final destinations = [...DestinationCatalog.all]
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(_editing ? 'Edit experience' : 'Write an experience'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                if (uid != null) ...[
                  _TripPicker(
                    uid: uid,
                    selectedTripId: _tripId,
                    onChanged: (id, trips) => _pickTrip(id, trips),
                  ),
                  const SizedBox(height: 14),
                ],
                DropdownButtonFormField<String>(
                  key: const Key('experience-destination'),
                  initialValue: destinations.any((d) => d.id == _destinationId)
                      ? _destinationId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Destination'),
                  items: [
                    for (final d in destinations)
                      DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setState(() => _destinationId = v),
                  validator: (v) => v == null ? 'Choose the destination you visited.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('experience-title'),
                  controller: _title,
                  maxLength: ExperienceRules.titleMax,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'For example: Five days of street food in Ahmedabad',
                  ),
                  validator: ExperienceRules.validateTitle,
                ),
                const SizedBox(height: 14),
                _RatingPicker(
                  rating: _rating,
                  showError: _showRatingError,
                  onChanged: (value) => setState(() {
                    _rating = value;
                    _showRatingError = false;
                  }),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('experience-story'),
                  controller: _story,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: ExperienceRules.storyMax,
                  decoration: const InputDecoration(
                    labelText: 'Your experience',
                    helperText: 'What you did, what stood out and what you would change.',
                    alignLabelWithHint: true,
                  ),
                  validator: ExperienceRules.validateStory,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('experience-tips'),
                  controller: _tips,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: ExperienceRules.tipsMax,
                  decoration: const InputDecoration(
                    labelText: 'Travel tips (optional)',
                    alignLabelWithHint: true,
                  ),
                  validator: ExperienceRules.validateTips,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('experience-highlights'),
                  controller: _highlights,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Highlights (optional)',
                    helperText: 'One per line, up to ${ExperienceRules.highlightsMax}.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => ExperienceRules.validateHighlights(
                    ExperienceRules.parseHighlights(v ?? ''),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surfaceTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Photos are not available yet. Photo upload is not set up for '
                    'Tripora, so your card shows the destination photo from our '
                    'catalogue.',
                    style: TextStyle(color: palette.text, fontSize: 12.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('experience-save'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving…' : (_editing ? 'Save changes' : 'Publish to my experiences')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final int? rating;
  final bool showError;
  final ValueChanged<int> onChanged;

  const _RatingPicker({
    required this.rating,
    required this.showError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your rating',
          style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 1; i <= ExperienceRules.ratingMax; i++)
              IconButton(
                key: Key('experience-star-$i'),
                tooltip: '$i star${i == 1 ? '' : 's'}',
                onPressed: () => onChanged(i),
                icon: Icon(
                  i <= (rating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: palette.orange,
                  size: 32,
                ),
              ),
          ],
        ),
        if (showError)
          Text(
            ExperienceRules.validateRating(null) ?? '',
            style: TextStyle(color: palette.danger, fontSize: 12),
          ),
      ],
    );
  }
}

/// Lets the traveller link the experience to one of their saved trips. Trips
/// are read from the cloud; if that fails, the editor still works without it.
class _TripPicker extends StatelessWidget {
  final String uid;
  final String? selectedTripId;
  final void Function(String? tripId, List<SavedTrip> trips) onChanged;

  const _TripPicker({
    required this.uid,
    required this.selectedTripId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.userTripsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Your saved trips could not be loaded. You can still write the experience.',
            style: TextStyle(color: palette.muted, fontSize: 12.5),
          );
        }
        if (!snapshot.hasData) {
          return Text(
            'Loading your saved trips…',
            style: TextStyle(color: palette.muted, fontSize: 12.5),
          );
        }
        final trips = snapshot.data!.docs.map(SavedTrip.fromDoc).toList();
        final current = trips.any((t) => t.id == selectedTripId)
            ? selectedTripId
            : null;
        return DropdownButtonFormField<String?>(
          key: const Key('experience-trip'),
          initialValue: current,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Linked saved trip (optional)'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Not linked to a saved trip'),
            ),
            for (final trip in trips)
              DropdownMenuItem<String?>(
                value: trip.id,
                child: Text(
                  '${trip.destination}'
                  '${trip.days == null ? '' : ' · ${trip.days} days'}',
                ),
              ),
          ],
          onChanged: (id) => onChanged(id, trips),
        );
      },
    );
  }
}
