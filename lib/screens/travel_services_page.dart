import 'dart:math';

import 'package:flutter/material.dart';

import '../data/vehicle_photos.dart';
import '../models/tour_package.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/vehicle_photo.dart';
import 'booking_form_screen.dart';
import 'bus_seat_selection_page.dart';

/// One search result (a flight, train, bus, cab or hotel).
///
/// Results are SAMPLE data generated from the search, because Tripora is
/// not connected to an airline, IRCTC, bus or hotel provider. The same
/// search always gives the same results.
class ServiceOption {
  final String id;
  final String title;
  final String subtitle;
  final List<String> tags;
  final int price;
  final String priceLabel;
  final Map<String, String> details;

  /// Minutes after midnight the service leaves, for sorting. Null for hotels.
  final int? departMinutes;

  /// Journey length in minutes, for sorting.
  final int? durationMinutes;

  /// Filter category, for example "AC Sleeper (2+1)" for a bus.
  final String category;

  const ServiceOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.price,
    required this.priceLabel,
    required this.details,
    this.departMinutes,
    this.durationMinutes,
    this.category = '',
  });
}

class ServiceSearch {
  final String service;
  final String from;
  final String to;
  final DateTime date;
  final int nights;

  const ServiceSearch({
    required this.service,
    required this.from,
    required this.to,
    required this.date,
    this.nights = 1,
  });
}

/// Builds the sample results for a search.
class DemoServiceProvider {
  DemoServiceProvider._();

  static Random _rng(ServiceSearch s) => Random(
    '${s.service}|${s.from.toLowerCase()}|${s.to.toLowerCase()}|'
            '${s.date.year}-${s.date.month}-${s.date.day}|${s.nights}'
        .hashCode,
  );

  static String _time(int minutes) {
    final m = minutes % (24 * 60);
    return '${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
  }

  static String _duration(int minutes) =>
      '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';

  static int _round(num value, [int to = 10]) => (value / to).round() * to;

  static List<ServiceOption> search(ServiceSearch s) {
    return switch (s.service) {
      'Flights' => _flights(s),
      'Trains' => _trains(s),
      'Buses' => _buses(s),
      'Cabs' => _cabs(s),
      'Hotels' => _hotels(s),
      _ => const [],
    };
  }

  static List<ServiceOption> _flights(ServiceSearch s) {
    final r = _rng(s);
    const airlines = {
      'IndiGo': '6E',
      'Air India': 'AI',
      'Air India Express': 'IX',
      'Akasa Air': 'QP',
      'SpiceJet': 'SG',
    };
    final names = airlines.keys.toList();
    return List.generate(6, (i) {
      final airline = names[r.nextInt(names.length)];
      final number = '${airlines[airline]} ${100 + r.nextInt(8900)}';
      final depart = 5 * 60 + i * 150 + r.nextInt(60);
      final length = 75 + r.nextInt(120);
      final stops = r.nextInt(4) == 0 ? '1 stop' : 'Non-stop';
      final price = _round(
        3200 + r.nextInt(6800) + (stops == '1 stop' ? -600 : 0),
      );
      return ServiceOption(
        id: 'flight-$number',
        title: '$airline $number',
        subtitle:
            '${_time(depart)} → ${_time(depart + length)} • '
            '${_duration(length)} • $stops',
        tags: [stops, 'Economy', '15 kg check-in'],
        price: price,
        priceLabel: 'per passenger',
        departMinutes: depart,
        durationMinutes: length,
        details: {
          'From': s.from,
          'To': s.to,
          'Flight': number,
          'Departs': _time(depart),
          'Arrives': _time(depart + length),
          'Cabin': 'Economy',
        },
      );
    })..sort((a, b) => a.details['Departs']!.compareTo(b.details['Departs']!));
  }

  static List<ServiceOption> _trains(ServiceSearch s) {
    final r = _rng(s);
    const trains = [
      'Rajdhani Express',
      'Shatabdi Express',
      'Vande Bharat Express',
      'Duronto Express',
      'Superfast Express',
      'Garib Rath Express',
    ];
    const classes = {
      'Sleeper (SL)': 1.0,
      'AC 3 Tier (3A)': 2.6,
      'AC 2 Tier (2A)': 3.7,
      'AC Chair Car (CC)': 2.1,
    };
    final classNames = classes.keys.toList();
    return List.generate(5, (i) {
      final name = trains[(i + r.nextInt(trains.length)) % trains.length];
      final number = '${12000 + r.nextInt(8000)}';
      final travelClass = classNames[r.nextInt(classNames.length)];
      final depart = 4 * 60 + i * 200 + r.nextInt(90);
      final length = 6 * 60 + r.nextInt(14 * 60);
      final price = _round((380 + r.nextInt(420)) * classes[travelClass]!);
      final seats = r.nextInt(5) == 0 ? 'RAC' : 'Available';
      return ServiceOption(
        id: 'train-$number-$travelClass',
        title: '$number $name',
        subtitle:
            '${_time(depart)} → ${_time(depart + length)} • '
            '${_duration(length)}',
        tags: [travelClass, seats],
        price: price,
        priceLabel: 'per passenger',
        departMinutes: depart,
        durationMinutes: length,
        details: {
          'From': s.from,
          'To': s.to,
          'Train': '$number $name',
          'Class': travelClass,
          'Departs': _time(depart),
          'Arrives': _time(depart + length),
        },
      );
    });
  }

  static List<ServiceOption> _buses(ServiceSearch s) {
    final r = _rng(s);
    const operators = [
      'VRL Travels',
      'IntrCity SmartBus',
      'Zingbus',
      'Orange Travels',
      'State Transport Volvo',
    ];
    const types = {
      'AC Sleeper (2+1)': 1.6,
      'Volvo AC Seater (2+2)': 1.2,
      'Non-AC Sleeper': 0.9,
    };
    final typeNames = types.keys.toList();
    return List.generate(5, (i) {
      final operator = operators[(i + r.nextInt(3)) % operators.length];
      final type = typeNames[r.nextInt(typeNames.length)];
      final depart = 17 * 60 + i * 75 + r.nextInt(45);
      final length = 5 * 60 + r.nextInt(8 * 60);
      final price = _round((550 + r.nextInt(700)) * types[type]!);
      return ServiceOption(
        id: 'bus-$operator-$i',
        title: operator,
        subtitle:
            '${_time(depart)} → ${_time(depart + length)} • '
            '${_duration(length)}',
        tags: [type, '${8 + r.nextInt(25)} seats left'],
        price: price,
        priceLabel: 'per seat',
        departMinutes: depart,
        durationMinutes: length,
        category: type,
        details: {
          'From': s.from,
          'To': s.to,
          'Operator': operator,
          'Bus type': type,
          'Departs': _time(depart),
        },
      );
    });
  }

  static List<ServiceOption> _cabs(ServiceSearch s) {
    final r = _rng(s);
    final km = 40 + r.nextInt(460);
    const cars = {
      'Hatchback (WagonR or similar)': 11,
      'Sedan (Dzire or similar)': 13,
      'SUV (Ertiga or similar)': 17,
      'Premium SUV (Innova Crysta)': 21,
    };
    return [
      for (final entry in cars.entries)
        ServiceOption(
          id: 'cab-${entry.key}',
          title: entry.key,
          subtitle: 'Approx. $km km one way • driver allowance included',
          tags: ['AC', 'Toll & parking extra'],
          price: _round(km * entry.value + 300, 50),
          priceLabel: 'per cab',
          details: {
            'Pick-up': s.from,
            'Drop': s.to,
            'Car': entry.key,
            'Distance': '~$km km',
          },
        ),
    ];
  }

  static List<ServiceOption> _hotels(ServiceSearch s) {
    final r = _rng(s);
    final city = s.to;
    const names = [
      'Grand Residency',
      'Heritage Inn',
      'Lakeview Suites',
      'Comfort Stay',
      'Royal Palace Hotel',
      'Backpacker Hostel',
    ];
    const amenities = [
      'Free Wi-Fi',
      'Breakfast',
      'Pool',
      'Parking',
      'Airport shuttle',
      'Gym',
      'Spa',
    ];
    return List.generate(6, (i) {
      final stars = [5, 4, 4, 3, 5, 2][i];
      final perNight = _round(stars * (900 + r.nextInt(900)) + 500, 50);
      final rating = (3.6 + r.nextInt(14) / 10).toStringAsFixed(1);
      final picked = ([...amenities]..shuffle(r)).take(3).toList();
      return ServiceOption(
        id: 'hotel-${city.toLowerCase()}-$i',
        title: '$city ${names[i]}',
        subtitle:
            '$stars-star • Guest rating $rating/5 • '
            '${formatInr(perNight)} per night',
        tags: picked,
        price: perNight * s.nights,
        priceLabel:
            'per room, ${s.nights} '
            '${s.nights == 1 ? 'night' : 'nights'}',
        details: {
          'City': city,
          'Check-in': '${s.date.day}/${s.date.month}/${s.date.year}',
          'Nights': '${s.nights}',
          'Room': 'Deluxe double',
          'Rate': '${formatInr(perNight)} per night',
          'Stars': '$stars',
          'Guest rating': '$rating / 5',
        },
      );
    });
  }
}

/// Travel Services: search sample flights, trains, buses, cabs and hotels
/// and send a demo booking request for any result.
class TravelServicesPage extends StatefulWidget {
  final String initialService;

  const TravelServicesPage({super.key, this.initialService = 'Flights'});

  @override
  State<TravelServicesPage> createState() => _TravelServicesPageState();
}

class _TravelServicesPageState extends State<TravelServicesPage> {
  static const services = <String, IconData>{
    'Flights': Icons.flight_takeoff_rounded,
    'Trains': Icons.train_rounded,
    'Buses': Icons.directions_bus_rounded,
    'Cabs': Icons.local_taxi_rounded,
    'Hotels': Icons.hotel_rounded,
  };

  final _from = TextEditingController(text: 'Ahmedabad');
  final _to = TextEditingController();

  late String _service = services.containsKey(widget.initialService)
      ? widget.initialService
      : 'Flights';
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  int _passengers = 1;
  int _nights = 2;
  ServiceSearch? _search;
  List<ServiceOption> _results = const [];
  final List<ServiceOption> _compare = [];

  static const int _maxCompare = 3;

  /// Sorting and filtering of the results. Demo values only.
  String _sort = 'price-asc';
  String? _busType;

  static const Map<String, String> _sortLabels = {
    'price-asc': 'Price: low to high',
    'price-desc': 'Price: high to low',
    'depart-asc': 'Departure: earliest first',
    'duration-asc': 'Duration: shortest first',
  };

  /// The results after the current filter and sort are applied.
  List<ServiceOption> _visibleResults() {
    var list = _results.where((o) {
      if (_service == 'Buses' && _busType != null) {
        return o.category == _busType;
      }
      return true;
    }).toList();
    int byPrice(ServiceOption a, ServiceOption b) => a.price.compareTo(b.price);
    list.sort(switch (_sort) {
      'price-desc' => (a, b) => byPrice(b, a),
      'depart-asc' => (a, b) => (a.departMinutes ?? 0).compareTo(
        b.departMinutes ?? 0,
      ),
      'duration-asc' => (a, b) => (a.durationMinutes ?? 0).compareTo(
        b.durationMinutes ?? 0,
      ),
      _ => byPrice,
    });
    return list;
  }

  Widget _sortBar() {
    final palette = context.palette;
    final busTypes = {
      for (final o in _results)
        if (o.category.isNotEmpty) o.category,
    }.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('results-sort'),
          initialValue: _sort,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Sort results',
            isDense: true,
          ),
          items: [
            for (final e in _sortLabels.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => setState(() => _sort = v ?? _sort),
        ),
        if (_service == 'Buses' && busTypes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const Key('bus-type-all'),
                label: const Text('All bus types'),
                selected: _busType == null,
                onSelected: (_) => setState(() => _busType = null),
              ),
              for (final type in busTypes)
                ChoiceChip(
                  key: Key('bus-type-$type'),
                  label: Text(type),
                  selected: _busType == type,
                  onSelected: (_) => setState(() => _busType = type),
                ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Results are sample schedules for demonstration. Prices and seats are not live.',
          style: TextStyle(color: palette.muted, fontSize: 11.5),
        ),
      ],
    );
  }

  bool get _isHotel => _service == 'Hotels';

  void _toggleCompare(ServiceOption option) {
    setState(() {
      if (_compare.any((o) => o.id == option.id)) {
        _compare.removeWhere((o) => o.id == option.id);
      } else if (_compare.length >= _maxCompare) {
        showAppMessage(
          context,
          'You can compare up to $_maxCompare hotels at a time.',
          error: true,
        );
      } else {
        _compare.add(option);
      }
    });
  }

  void _openCompare() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => HotelCompareSheet(options: List.of(_compare)),
    );
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

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

  void _runSearch() {
    FocusScope.of(context).unfocus();
    final from = _from.text.trim();
    final to = _to.text.trim();

    if (_isHotel) {
      if (to.isEmpty) {
        showAppMessage(
          context,
          'Enter the city you want to stay in.',
          error: true,
        );
        return;
      }
    } else {
      if (from.isEmpty || to.isEmpty) {
        showAppMessage(
          context,
          'Enter where you are leaving from and going to.',
          error: true,
        );
        return;
      }
      if (from.toLowerCase() == to.toLowerCase()) {
        showAppMessage(
          context,
          'Starting point and destination must be different.',
          error: true,
        );
        return;
      }
    }

    final search = ServiceSearch(
      service: _service,
      from: from,
      to: to,
      date: _date,
      nights: _nights,
    );
    setState(() {
      _search = search;
      _results = DemoServiceProvider.search(search);
      _compare.clear();
    });
  }

  void _book(ServiceOption option) {
    final s = _search!;
    if (s.service == 'Buses') {
      SafeNav.push(
        context,
        BusSeatSelectionPage(
          option: option,
          from: s.from,
          to: s.to,
          date: s.date,
          passengers: _passengers,
        ),
      );
      return;
    }
    final kind = switch (s.service) {
      'Flights' => 'flight',
      'Trains' => 'train',
      'Buses' => 'bus',
      'Cabs' => 'cab',
      _ => 'hotel',
    };
    final quantityLabel = switch (kind) {
      'hotel' => 'Rooms',
      'cab' => 'Cabs',
      _ => 'Passengers',
    };
    SafeNav.push(
      context,
      BookingFormScreen(
        draft: BookingDraft(
          kind: kind,
          itemId: option.id,
          title: option.title,
          subtitle: _isHotelSearch(s)
              ? '${s.to} • ${s.nights} ${s.nights == 1 ? 'night' : 'nights'}'
              : '${s.from} → ${s.to} • ${option.subtitle}',
          unitPrice: option.price,
          unitLabel: option.priceLabel,
          quantityLabel: quantityLabel,
          initialDate: s.date,
          dateFixed: true,
          initialQuantity: kind == 'cab' ? 1 : _passengers,
          details: option.details,
          imageAsset: _photoFor(option),
        ),
      ),
    );
  }

  bool _isHotelSearch(ServiceSearch s) => s.service == 'Hotels';

  /// Illustrative vehicle photo for a result, or null (hotels have none).
  String? _photoFor(ServiceOption option) => VehiclePhotos.forService(
    service: _search?.service ?? _service,
    category: option.category,
    details: option.details,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Travel Services')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final entry in services.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(entry.value, size: 18),
                          label: Text(entry.key),
                          selected: _service == entry.key,
                          onSelected: (_) => setState(() {
                            _service = entry.key;
                            _search = null;
                            _results = const [];
                            _compare.clear();
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _form(),
              const SizedBox(height: 14),
              const DemoNotice(
                message:
                    'Sample schedules and prices for demonstration. '
                    'Tripora is not connected to an airline, IRCTC, bus or '
                    'hotel provider, so bookings are demo requests only.',
              ),
              if (_search != null) ...[
                const SizedBox(height: 18),
                SectionHeader(
                  title: '${_results.length} sample ${_service.toLowerCase()}',
                  subtitle: _isHotel
                      ? 'In ${_search!.to}'
                      : '${_search!.from} → ${_search!.to}',
                ),
                const SizedBox(height: 10),
                if (_isHotel && _compare.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comparing ${_compare.length} of $_maxCompare hotels',
                          style: TextStyle(
                            color: context.palette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        key: const Key('hotel-compare-open'),
                        onPressed: _compare.length >= 2 ? _openCompare : null,
                        icon: const Icon(Icons.compare_arrows_rounded),
                        label: const Text('Compare'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (_results.isNotEmpty) ...[
                  _sortBar(),
                  const SizedBox(height: 12),
                ],
                if (_visibleResults().isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No results match this filter. Choose another bus type.',
                      key: const Key('results-empty'),
                      style: TextStyle(color: context.palette.muted),
                    ),
                  ),
                for (final option in _visibleResults())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ResultCard(
                      option: option,
                      icon: services[_service]!,
                      onBook: () => _book(option),
                      onCompare: _isHotel ? () => _toggleCompare(option) : null,
                      compared: _compare.any((o) => o.id == option.id),
                      photo: _photoFor(option),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Material(
      color: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_isHotel) ...[
              TextField(
                key: const Key('service-from'),
                controller: _from,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: _service == 'Cabs' ? 'Pick-up city' : 'From',
                  prefixIcon: const Icon(Icons.trip_origin_rounded),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              key: const Key('service-to'),
              controller: _to,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _isHotel
                    ? 'City'
                    : (_service == 'Cabs' ? 'Drop city' : 'To'),
                prefixIcon: const Icon(Icons.place_rounded),
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_rounded, color: context.palette.blue),
              title: Text(_isHotel ? 'Check-in' : 'Travel date'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            if (_isHotel)
              _stepper('Nights', _nights, (v) => setState(() => _nights = v))
            else if (_service != 'Cabs')
              _stepper(
                'Passengers',
                _passengers,
                (v) => setState(() => _passengers = v),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                key: const Key('service-search'),
                onPressed: _runSearch,
                icon: const Icon(Icons.search_rounded),
                label: Text('Search $_service'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(String label, int value, ValueChanged<int> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.group_rounded, color: context.palette.blue),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Fewer',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: value < 9 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ServiceOption option;
  final IconData icon;
  final VoidCallback onBook;

  /// Only set for hotels: adds a Compare toggle to the card.
  final VoidCallback? onCompare;
  final bool compared;

  /// Illustrative vehicle photo (a bundled asset), or null for no photo.
  final String? photo;

  const _ResultCard({
    required this.option,
    required this.icon,
    required this.onBook,
    this.onCompare,
    this.compared = false,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[
            VehiclePhoto(
              asset: photo!,
              label: option.title,
              icon: icon,
              aspectRatio: 2.1,
              maxHeight: 180,
            ),
            VehiclePhotoCaption(asset: photo!),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(icon, color: context.palette.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            option.subtitle,
            style: TextStyle(color: context.palette.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in option.tags)
                TagChip(label: t, color: context.palette.teal),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatInr(option.price),
                      style: TextStyle(
                        color: context.palette.blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    TextSpan(
                      text: '  ${option.priceLabel}',
                      style: TextStyle(
                        color: context.palette.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (onCompare != null) ...[
                OutlinedButton.icon(
                  key: Key('hotel-compare-${option.id}'),
                  onPressed: onCompare,
                  icon: Icon(
                    compared ? Icons.check_rounded : Icons.add_rounded,
                    size: 18,
                  ),
                  label: Text(compared ? 'Added' : 'Compare'),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(onPressed: onBook, child: const Text('Select')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Side-by-side view of up to three sample hotels. All values come from the
/// same sample search, and the sheet says so.
class HotelCompareSheet extends StatelessWidget {
  final List<ServiceOption> options;

  const HotelCompareSheet({super.key, required this.options});

  static String _detail(ServiceOption o, String key) => o.details[key] ?? '—';

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String Function(ServiceOption))>[
      ('Total price', (o) => formatInr(o.price)),
      ('Rate', (o) => _detail(o, 'Rate')),
      ('Stars', (o) => _detail(o, 'Stars')),
      ('Guest rating', (o) => _detail(o, 'Guest rating')),
      ('Room', (o) => _detail(o, 'Room')),
      ('Amenities', (o) => o.tags.join(', ')),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Compare hotels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Sample prices and ratings from the demo search. Nothing here is a live rate.',
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(width: 96),
                for (final o in options)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        o.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 18),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: context.palette.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    for (final o in options)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value(o),
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
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
