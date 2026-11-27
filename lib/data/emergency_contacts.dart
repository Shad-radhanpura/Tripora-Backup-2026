/// An official source for emergency numbers, shown on the Emergency help page.
class EmergencySource {
  final String title;
  final String url;

  const EmergencySource({required this.title, required this.url});
}

/// One emergency or helpline number for a country.
class EmergencyContact {
  final String service;
  final String number;

  /// When to use this number, in plain words.
  final String whenToCall;

  /// Official page this number was checked against.
  final EmergencySource source;

  const EmergencyContact({
    required this.service,
    required this.number,
    required this.whenToCall,
    required this.source,
  });

  /// Digits to dial, without hyphens: 112, or 0111070 for 011-1070.
  String get dialDigits => number.replaceAll(RegExp(r'[^0-9+]'), '');
}

/// Emergency numbers for each country Tripora has verified.
///
/// Numbers differ between countries. Only India is listed for now, so the app
/// never shows one country's numbers as if they applied everywhere.
class EmergencyDirectory {
  EmergencyDirectory._();

  /// Date the numbers below were last checked against the sources.
  static const String checkedOn = '17 October 2026';

  static const EmergencySource mhaSource = EmergencySource(
    title: 'Ministry of Home Affairs: ERSS-112',
    url: 'https://www.mha.gov.in/en/commoncontent/emergency-response-support-system-erss',
  );

  static const EmergencySource touristSource = EmergencySource(
    title: 'Incredible India (Ministry of Tourism): Emergency numbers',
    url: 'https://www.incredibleindia.gov.in/en/emergency',
  );

  static const EmergencySource ndmaSource = EmergencySource(
    title: 'NDMA: Emergency Operations Centre contacts',
    url: 'https://ndma.gov.in/en/emergency-operations-center',
  );

  static const String indiaName = 'India';

  static const List<EmergencyContact> india = [
    EmergencyContact(
      service: 'Unified emergency number',
      number: '112',
      whenToCall:
          'Any emergency in India: police, fire, ambulance or danger to a woman. '
          'The Home Ministry describes 112 as the single number for all emergencies.',
      source: mhaSource,
    ),
    EmergencyContact(
      service: 'Police',
      number: '100',
      whenToCall: 'A crime is happening, you are in danger, or you need the police quickly.',
      source: touristSource,
    ),
    EmergencyContact(
      service: 'Fire',
      number: '101',
      whenToCall: 'A fire, a gas smell or a building or vehicle on fire.',
      source: touristSource,
    ),
    EmergencyContact(
      service: 'Ambulance',
      number: '102',
      whenToCall:
          'A medical emergency that needs an ambulance. If 102 does not connect '
          'where you are, call 112.',
      source: touristSource,
    ),
    EmergencyContact(
      service: "Women's helpline",
      number: '1091',
      whenToCall:
          'Harassment, threats or violence against a woman. In immediate danger, '
          'call 112 or 100 first.',
      source: touristSource,
    ),
    EmergencyContact(
      service: 'Tourist helpline',
      number: '1363',
      whenToCall:
          'Travel information and help for visitors to India. For an emergency, '
          'call 112 instead.',
      source: touristSource,
    ),
    EmergencyContact(
      service: 'Disaster management',
      number: '011-1070',
      whenToCall:
          'Floods, earthquakes, cyclones, landslides or other disasters. Listed as '
          "the National Emergency Response Centre's helpline on NDMA's page.",
      source: ndmaSource,
    ),
  ];

  /// Shown on every country page. It does not give other countries' numbers.
  static const String internationalNote =
      'Travelling outside India? Emergency numbers differ from country to country, '
      'and 112 does not work everywhere. Look up the number for the country you are '
      'in, for example on your government\'s travel advice page, and save it before '
      'you leave. Your embassy or consulate can also help.';
}
