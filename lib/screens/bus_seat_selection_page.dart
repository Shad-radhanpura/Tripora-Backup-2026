import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vehicle_photos.dart';
import '../models/saved_trip.dart' show formatDate;
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/vehicle_photo.dart';
import 'booking_form_screen.dart';
import 'travel_services_page.dart';

/// Seat map for a demo bus. Seats are illustrative: the booked seats are chosen
/// deterministically from the bus ID, so the same bus always shows the same map.
/// Nothing here reserves a real seat.
class BusSeatSelectionPage extends StatefulWidget {
  final ServiceOption option;
  final String from;
  final String to;
  final DateTime date;
  final int passengers;

  const BusSeatSelectionPage({
    super.key,
    required this.option,
    required this.from,
    required this.to,
    required this.date,
    required this.passengers,
  });

  static const int rows = 10;

  /// Seat IDs for one row, in layout order: two seats, an aisle, two seats.
  static const List<String> rowLetters = ['A', 'B', 'C', 'D'];

  /// Seats already taken on the demo bus. About a third of seats, fixed per bus.
  static Set<String> bookedSeatsFor(String busId) {
    final random = Random(busId.hashCode);
    final booked = <String>{};
    for (var row = 1; row <= rows; row++) {
      for (final letter in rowLetters) {
        if (random.nextDouble() < 0.33) booked.add('$row$letter');
      }
    }
    return booked;
  }

  @override
  State<BusSeatSelectionPage> createState() => _BusSeatSelectionPageState();
}

class _BusSeatSelectionPageState extends State<BusSeatSelectionPage> {
  final Set<String> _selected = {};
  late final Set<String> _booked = BusSeatSelectionPage.bookedSeatsFor(widget.option.id);

  int get _needed => widget.passengers;

  void _toggle(String seat) {
    if (_booked.contains(seat)) return;
    setState(() {
      if (_selected.contains(seat)) {
        _selected.remove(seat);
      } else if (_selected.length >= _needed) {
        showAppMessage(
          context,
          'You need exactly $_needed seat${_needed == 1 ? '' : 's'}. '
          'Deselect one first.',
          error: true,
        );
      } else {
        _selected.add(seat);
      }
    });
  }

  void _continue() {
    final seats = _selected.toList()..sort();
    final price = widget.option.price;
    SafeNav.push(
      context,
      BookingFormScreen(
        draft: BookingDraft(
          kind: 'bus',
          itemId: widget.option.id,
          title: widget.option.title,
          subtitle: '${widget.from} → ${widget.to} • ${widget.option.category}',
          unitPrice: price,
          unitLabel: 'per seat',
          quantityLabel: 'Passengers',
          initialDate: widget.date,
          dateFixed: true,
          initialQuantity: seats.length,
          fixedQuantity: seats.length,
          details: {
            ...widget.option.details,
            'Seats': seats.join(', '),
          },
          imageAsset: VehiclePhotos.forService(
            service: 'Buses',
            category: widget.option.category,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ready = _selected.length == _needed;
    final total = widget.option.price * _selected.length;
    final option = widget.option;
    final photo = VehiclePhotos.forService(
      service: 'Buses',
      category: option.category,
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Choose your seats')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seats ${_selected.isEmpty ? 'none' : (_selected.toList()..sort()).join(', ')}',
                      key: const Key('bus-selected-seats'),
                      style: TextStyle(color: palette.text, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Total ₹$total (${_selected.length} × ₹${option.price})',
                      key: const Key('bus-total'),
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              FilledButton(
                key: const Key('bus-continue'),
                onPressed: ready ? _continue : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (photo != null) ...[
                VehiclePhoto(
                  asset: photo,
                  label: option.title,
                  icon: Icons.directions_bus_rounded,
                  maxHeight: 200,
                ),
                VehiclePhotoCaption(asset: photo),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title,
                        style: TextStyle(color: palette.text, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${widget.from} → ${widget.to} · ${formatDate(widget.date)}',
                        style: TextStyle(color: palette.muted, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    Text(
                      '${option.category} · Departs ${option.details['Departs'] ?? '-'}',
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select exactly $_needed seat${_needed == 1 ? '' : 's'} for ${_needed == 1 ? 'the passenger' : 'the passengers'}.',
                key: const Key('bus-seat-instructions'),
                style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _Legend(),
              const SizedBox(height: 12),
              // Driver area, then the seat rows.
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.airline_seat_recline_extra_rounded, color: palette.muted),
              ),
              for (var row = 1; row <= BusSeatSelectionPage.rows; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final letter in BusSeatSelectionPage.rowLetters) ...[
                        if (letter == 'C') const SizedBox(width: 28),
                        _seat('$row$letter'),
                        if (letter != 'D') const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seat(String id) {
    final palette = context.palette;
    final booked = _booked.contains(id);
    final selected = _selected.contains(id);
    final Color fill = booked
        ? palette.border
        : selected
            ? palette.blue
            : palette.surface;
    final Color border = selected ? palette.blue : palette.border;
    return Semantics(
      label: 'Seat $id, ${booked ? 'booked' : selected ? 'selected' : 'available'}',
      button: !booked,
      child: InkWell(
        key: Key('seat-$id'),
        borderRadius: BorderRadius.circular(8),
        onTap: booked ? null : () => _toggle(id),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: booked
              ? Icon(Icons.close_rounded, size: 16, color: palette.muted)
              : Text(
                  id,
                  style: TextStyle(
                    color: selected ? Colors.white : palette.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget item(Color color, String label, {bool outlined = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: palette.border),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(palette.surface, 'Available'),
        item(palette.blue, 'Selected'),
        item(palette.border, 'Booked'),
      ],
    );
  }
}
