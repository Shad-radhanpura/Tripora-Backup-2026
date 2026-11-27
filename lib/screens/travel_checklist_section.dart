import 'package:flutter/material.dart';

import '../theme/theme.dart';

import '../models/checklist_item.dart';
import '../services/checklist_service.dart';
import '../widgets/common.dart';

/// "Travel documents" checklist shown inside a saved trip.
///
/// Tracks document preparation only; no document files are requested or
/// stored. Progress is saved in Firestore, so it survives logout, restarts
/// and sign-in on another device.
class TravelChecklistSection extends StatefulWidget {
  final String tripId;

  const TravelChecklistSection({super.key, required this.tripId});

  @override
  State<TravelChecklistSection> createState() => _TravelChecklistSectionState();
}

class _TravelChecklistSectionState extends State<TravelChecklistSection> {
  static const Color _primary = Color(0xFF2563EB);
  static const Color _dark = Color(0xFF172033);
  static const Color _muted = Color(0xFF667085);

  late Future<void> _defaults;
  Stream<List<ChecklistItem>>? _items;
  final _addController = TextEditingController();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // Defaults are created once per open; existing items are left alone.
    _defaults = ChecklistService.ensureDefaults(widget.tripId);
    _items = ChecklistService.watch(widget.tripId);
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _toggle(ChecklistItem item, bool done) async {
    try {
      await ChecklistService.setDone(
        widget.tripId,
        item.id,
        done,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Could not update the item. ${describeFirestoreError(e)}',
          error: true,
        );
      }
    }
  }

  Future<void> _addCustom() async {
    final label = _addController.text.trim();
    if (label.length < 2) {
      showAppMessage(context, 'Enter at least 2 characters.', error: true);
      return;
    }
    if (label.length > 80) {
      showAppMessage(
        context,
        'Keep the item under 80 characters.',
        error: true,
      );
      return;
    }
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await ChecklistService.addCustom(
        widget.tripId,
        label,
      ).timeout(const Duration(seconds: 15));
      _addController.clear();
      if (mounted) showAppMessage(context, 'Item added.');
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Could not add the item. ${describeFirestoreError(e)}',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _remove(ChecklistItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this item?'),
        content: Text('"${item.label}" will be removed from this trip.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ChecklistService.removeCustom(
        widget.tripId,
        item.id,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Could not remove the item. ${describeFirestoreError(e)}',
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Material (not a coloured Container) so the checkbox rows show ripples.
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Material(
        color: context.palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE5E9F2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: FutureBuilder<void>(
            future: _defaults,
            builder: (context, defaultsSnap) {
              if (defaultsSnap.hasError) {
                return _errorBox(defaultsSnap.error);
              }
              return StreamBuilder<List<ChecklistItem>>(
                stream: _items,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return _errorBox(snapshot.error);
                  if (!snapshot.hasData ||
                      defaultsSnap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    );
                  }
                  return _content(snapshot.data!);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(List<ChecklistItem> items) {
    final done = items.where((i) => i.done).length;
    final total = items.length;
    final percent = total == 0 ? 0 : (done * 100 / total).round();
    final remaining = total - done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fact_check_rounded, color: _primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Travel documents',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                ),
              ),
            ),
            Text(
              '$percent%',
              key: const Key('checklist-percent'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          remaining == 0
              ? 'All items are ready.'
              : '$done done · $remaining remaining. Tick what you have prepared.',
          style: const TextStyle(color: _muted, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8EEF8),
            color: _primary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Track only. Do not upload passport scans, ID images or ticket files here.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
        const SizedBox(height: 6),
        for (final item in items) _tile(item),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('checklist-add-field'),
                controller: _addController,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Add your own item',
                  hintText: 'e.g. Vaccination certificate',
                  counterText: '',
                  isDense: true,
                ),
                onSubmitted: (_) => _addCustom(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('checklist-add'),
              tooltip: 'Add item',
              onPressed: _adding ? null : _addCustom,
              icon: _adding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tile(ChecklistItem item) {
    final hint = item.custom
        ? null
        : DefaultChecklist.items
              .where((d) => d.id == item.id)
              .firstOrNull
              ?.hint;
    return CheckboxListTile(
      key: Key('checklist-item-${item.id}'),
      value: item.done,
      onChanged: (value) => _toggle(item, value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: _primary,
      title: Text(
        item.label,
        style: TextStyle(
          color: _dark,
          fontWeight: FontWeight.w700,
          decoration: item.done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: hint == null
          ? null
          : Text(hint, style: const TextStyle(fontSize: 11.5, color: _muted)),
      secondary: item.custom
          ? IconButton(
              tooltip: 'Remove',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
              ),
              onPressed: () => _remove(item),
            )
          : null,
    );
  }

  Widget _errorBox(Object? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel documents',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _dark,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          describeFirestoreError(error),
          style: const TextStyle(color: Color(0xFFDC2626)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
