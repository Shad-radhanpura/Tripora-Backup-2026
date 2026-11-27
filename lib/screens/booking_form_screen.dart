import 'package:flutter/material.dart';

import '../models/tour_package.dart';
import '../services/app_firebase.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/vehicle_photo.dart';
import 'my_bookings_screen.dart';

/// What the user picked before filling in the booking form.
class BookingDraft {
  final String kind;
  final String itemId;
  final String title;
  final String subtitle;

  /// Price for one unit (one traveller, or one room for the whole stay).
  final int unitPrice;
  final String unitLabel;

  /// "Travellers", "Passengers" or "Rooms".
  final String quantityLabel;
  final DateTime initialDate;

  /// True when the date was already chosen in the search (flights etc.).
  final bool dateFixed;
  final int initialQuantity;

  /// When set, the quantity is fixed (for example by seats already chosen).
  final int? fixedQuantity;
  final Map<String, String> details;

  /// Optional illustrative vehicle photo (a bundled asset path) shown at the top.
  final String? imageAsset;

  const BookingDraft({
    required this.kind,
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.unitPrice,
    required this.unitLabel,
    required this.quantityLabel,
    required this.initialDate,
    this.dateFixed = false,
    this.initialQuantity = 1,
    this.fixedQuantity,
    this.details = const {},
    this.imageAsset,
  });
}

/// Contact details, date and quantity, then saves a DEMO booking request to
/// the `bookings` collection and shows the reference.
class BookingFormScreen extends StatefulWidget {
  final BookingDraft draft;

  const BookingFormScreen({super.key, required this.draft});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  static const int maxQuantity = 9;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  late DateTime _date;
  late int _quantity;
  bool _acknowledged = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AppFirebase.auth.currentUser;
    _name = TextEditingController(text: user?.displayName ?? '');
    _date = widget.draft.initialDate;
    _quantity = (widget.draft.fixedQuantity ?? widget.draft.initialQuantity).clamp(1, maxQuantity);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  int get _total => widget.draft.unitPrice * _quantity;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_acknowledged) {
      showAppMessage(
        context,
        'Please confirm you understand this is a demo booking.',
        error: true,
      );
      return;
    }

    final user = AppFirebase.auth.currentUser;
    if (user == null) {
      showAppMessage(context, 'Please log in again to book.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final reference = await FirestoreService.createBooking(
        user: user,
        kind: widget.draft.kind,
        itemId: widget.draft.itemId,
        title: widget.draft.title,
        subtitle: widget.draft.subtitle,
        travelDate: _date,
        travellers: _quantity,
        unitPrice: widget.draft.unitPrice,
        totalPrice: _total,
        contactName: _name.text.trim(),
        contactPhone: _phone.text.trim(),
        notes: _notes.text.trim(),
        details: widget.draft.details,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            reference: reference,
            title: widget.draft.title,
            total: _total,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Booking failed: $e');
      if (!mounted) return;
      showAppMessage(
        context,
        'Booking could not be saved. ${describeFirestoreError(e)}',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Booking details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                const DemoNotice(),
                const SizedBox(height: 14),
                if (draft.imageAsset != null) ...[
                  VehiclePhoto(
                    asset: draft.imageAsset!,
                    label: draft.title,
                    icon: vehicleIconFor(draft.kind),
                  ),
                  VehiclePhotoCaption(asset: draft.imageAsset!),
                  const SizedBox(height: 14),
                ],
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: context.palette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        draft.subtitle,
                        style: TextStyle(color: context.palette.muted),
                      ),
                      if (draft.details.isNotEmpty) ...[
                        const Divider(height: 22),
                        for (final entry in draft.details.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.event_rounded,
                          color: context.palette.blue,
                        ),
                        title: const Text('Travel date'),
                        subtitle: Text(_formatDay(_date)),
                        trailing: draft.dateFixed
                            ? null
                            : TextButton(
                                onPressed: _pickDate,
                                child: const Text('Change'),
                              ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.group_rounded,
                          color: context.palette.blue,
                        ),
                        title: Text(draft.quantityLabel),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Fewer',
                              onPressed: _quantity > 1 && widget.draft.fixedQuantity == null
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$_quantity',
                              key: const Key('booking-quantity'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              tooltip: 'More',
                              onPressed: _quantity < maxQuantity && widget.draft.fixedQuantity == null
                                  ? () => setState(() => _quantity++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Lead traveller name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter the traveller\'s name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '10-digit mobile number',
                        ),
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          return digits.length < 10 || digits.length > 13
                              ? 'Enter a valid mobile number'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notes,
                        maxLines: 2,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'Special requests (optional)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  Column(
                    children: [
                      _priceRow(
                        '${formatInr(draft.unitPrice)} ${draft.unitLabel}',
                        '× $_quantity',
                      ),
                      const Divider(height: 20),
                      _priceRow(
                        'Estimated total',
                        formatInr(_total),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  key: const Key('demo-ack'),
                  value: _acknowledged,
                  onChanged: (v) => setState(() => _acknowledged = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I understand this is a demo booking request. Nothing is '
                    'reserved and no payment is taken.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('submit-booking'),
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_saving ? 'Saving…' : 'Submit booking request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Material(
    color: context.palette.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: context.palette.border),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  Widget _priceRow(String left, String right, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 13.5,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      color: context.palette.text,
    );
    return Row(
      children: [
        Expanded(child: Text(left, style: style)),
        Text(right, style: style),
      ],
    );
  }
}

String _formatDay(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class BookingSuccessScreen extends StatelessWidget {
  final String reference;
  final String title;
  final int total;

  const BookingSuccessScreen({
    super.key,
    required this.reference,
    required this.title,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 84,
                    color: context.palette.green,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Booking request saved',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.muted),
                  ),
                  const SizedBox(height: 18),
                  SelectableText(
                    reference,
                    style: TextStyle(
                      fontSize: 26,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      color: context.palette.blue,
                    ),
                  ),
                  Text(
                    'Demo reference (not a PNR or voucher)',
                    style: TextStyle(color: context.palette.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated total ${formatInr(total)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  const DemoNotice(
                    message:
                        'Status: Requested. An admin can mark this demo '
                        'booking as confirmed, completed or cancelled. You can '
                        'follow it in My Bookings.',
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const MyBookingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('View my bookings'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      child: const Text('Back to home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
