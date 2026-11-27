import '../models/tour_package.dart';
import 'destinations.dart';

/// Built-in tour packages bundled with the app.
///
/// Prices are indicative per-person sample prices in INR for twin sharing.
/// They are demo content for the booking workflow, not live quotes from a
/// tour operator. Admins can override or hide any of these, or add new
/// packages, from Admin Panel > Package Management.
class TourPackageCatalog {
  TourPackageCatalog._();

  static const List<int> durations = [10, 15, 20, 30];

  static const List<String> categories = [
    'Culture',
    'Nature',
    'Beach',
    'Adventure',
    'Spiritual',
    'International',
  ];

  static const List<String> hotelClasses = ['3-star', '4-star', '5-star'];

  static const List<String> allFacilities = [
    'Hotel stay',
    'Daily breakfast',
    'Breakfast & dinner',
    'AC private cab',
    'Train tickets',
    'Domestic flights',
    'International flights',
    'Airport transfers',
    'Sightseeing tours',
    'English-speaking guide',
    'Entry tickets',
    'Houseboat stay',
    'Inner-line permits',
    'Visa assistance',
    'Travel insurance',
    '24×7 trip support',
  ];

  static String _image(String destinationId) {
    for (final d in DestinationCatalog.all) {
      if (d.id == destinationId) return d.imageUrl;
    }
    return '';
  }

  static TourPackage? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static final List<TourPackage> all = [
    // ------------------------------------------------------------ 10 DAYS
    TourPackage(
      id: 'golden-triangle-udaipur-10',
      title: 'Golden Triangle & Udaipur',
      durationDays: 10,
      cities: ['Delhi', 'Agra', 'Jaipur', 'Udaipur'],
      region: 'North India',
      category: 'Culture',
      pricePerPerson: 38500,
      hotelClass: '3-star',
      facilities: [
        'Hotel stay',
        'Daily breakfast',
        'AC private cab',
        'Sightseeing tours',
        'Entry tickets',
        '24×7 trip support',
      ],
      highlights: [
        'Taj Mahal at sunrise',
        'Amber Fort and Hawa Mahal',
        'Boat ride on Lake Pichola',
        'Old Delhi rickshaw ride',
      ],
      description:
          'The classic first trip to India: Mughal monuments, Rajput forts '
          'and the lakes of Udaipur, with a private cab throughout.',
      imageUrl: _image('agra'),
      builtIn: true,
      itinerary: const [
        PackageDay('Day 1', 'Arrive in Delhi',
            'Airport pick-up, check in, evening at India Gate and Connaught Place.'),
        PackageDay('Day 2', 'Delhi sightseeing',
            'Red Fort, Jama Masjid, Chandni Chowk rickshaw ride, Qutub Minar and Humayun\'s Tomb.'),
        PackageDay('Day 3', 'Delhi → Agra',
            'Drive by expressway (4 h). Agra Fort in the afternoon, Mehtab Bagh at sunset.'),
        PackageDay('Day 4', 'Taj Mahal → Jaipur',
            'Taj Mahal at sunrise, Fatehpur Sikri on the way, arrive Jaipur by evening.'),
        PackageDay('Days 5–6', 'Jaipur',
            'Amber Fort, Hawa Mahal, City Palace, Jantar Mantar and the bazaars of the Pink City.'),
        PackageDay('Day 7', 'Jaipur → Udaipur',
            'Drive via Chittorgarh Fort (7 h with stops).'),
        PackageDay('Days 8–9', 'Udaipur',
            'City Palace, Jagdish Temple, Saheliyon ki Bari, sunset boat ride on Lake Pichola.'),
        PackageDay('Day 10', 'Departure',
            'Transfer to Udaipur airport or railway station.'),
      ],
    ),
    TourPackage(
      id: 'kerala-backwaters-hills-10',
      title: 'Kerala Backwaters & Hills',
      durationDays: 10,
      cities: ['Kochi', 'Munnar', 'Thekkady', 'Alappuzha', 'Kovalam'],
      region: 'South India',
      category: 'Nature',
      pricePerPerson: 42000,
      hotelClass: '4-star',
      facilities: [
        'Hotel stay',
        'Breakfast & dinner',
        'Houseboat stay',
        'AC private cab',
        'Sightseeing tours',
        'Airport transfers',
      ],
      highlights: [
        'Overnight houseboat in Alappuzha',
        'Tea estates of Munnar',
        'Periyar wildlife boat safari',
        'Kathakali show in Kochi',
      ],
      description:
          'Tea hills, spice gardens, a night on a private houseboat and '
          'relaxed beach days in Kovalam.',
      imageUrl: _image('alappuzha'),
      builtIn: true,
      itinerary: const [
        PackageDay('Day 1', 'Arrive in Kochi',
            'Fort Kochi walk, Chinese fishing nets, evening Kathakali performance.'),
        PackageDay('Days 2–3', 'Munnar',
            'Drive to Munnar (4 h). Tea museum, Eravikulam National Park, Mattupetty Dam.'),
        PackageDay('Days 4–5', 'Thekkady',
            'Spice plantation tour, Periyar Lake boat safari, optional bamboo rafting.'),
        PackageDay('Day 6', 'Alappuzha houseboat',
            'Board a private houseboat; cruise the backwaters with all meals on board.'),
        PackageDay('Days 7–9', 'Kovalam',
            'Beach time, Padmanabhaswamy Temple in Thiruvananthapuram, optional Ayurveda session.'),
        PackageDay('Day 10', 'Departure',
            'Transfer to Thiruvananthapuram airport.'),
      ],
    ),
    TourPackage(
      id: 'goa-konkan-beaches-10',
      title: 'Goa & Gokarna Beach Escape',
      durationDays: 10,
      cities: ['North Goa', 'South Goa', 'Gokarna'],
      region: 'West India',
      category: 'Beach',
      pricePerPerson: 29900,
      hotelClass: '3-star',
      facilities: [
        'Hotel stay',
        'Daily breakfast',
        'Airport transfers',
        'Sightseeing tours',
        '24×7 trip support',
      ],
      highlights: [
        'Old Goa churches (UNESCO)',
        'Palolem and Agonda beaches',
        'Dudhsagar Falls jeep trip',
        'Om Beach, Gokarna',
      ],
      description:
          'Ten unhurried days across Goa\'s best beaches and the quieter '
          'coves of Gokarna in Karnataka.',
      imageUrl: _image('goa'),
      builtIn: true,
      itinerary: const [
        PackageDay('Day 1', 'Arrive in North Goa',
            'Airport pick-up, sunset at Baga or Candolim beach.'),
        PackageDay('Days 2–3', 'North Goa',
            'Fort Aguada, Chapora Fort, Anjuna flea market (Wednesdays), Old Goa churches.'),
        PackageDay('Day 4', 'Dudhsagar Falls',
            'Full-day jeep excursion to Dudhsagar Falls and a spice farm.'),
        PackageDay('Days 5–7', 'South Goa',
            'Palolem, Agonda and Cola beaches; Cabo de Rama fort; kayaking.'),
        PackageDay('Days 8–9', 'Gokarna',
            'Drive to Gokarna (3 h). Mahabaleshwar Temple, Kudle and Om beaches.'),
        PackageDay('Day 10', 'Departure',
            'Transfer back to Goa airport.'),
      ],
    ),

    // ------------------------------------------------------------ 15 DAYS
    TourPackage(
      id: 'manali-leh-adventure-15',
      title: 'Himalayan Road Trip: Manali to Ladakh',
      durationDays: 15,
      cities: ['Manali', 'Jispa', 'Leh', 'Nubra Valley', 'Pangong Tso'],
      region: 'North India',
      category: 'Adventure',
      pricePerPerson: 68000,
      hotelClass: '3-star',
      facilities: [
        'Hotel stay',
        'Breakfast & dinner',
        'AC private cab',
        'Inner-line permits',
        'English-speaking guide',
        'Travel insurance',
      ],
      highlights: [
        'Atal Tunnel and Baralacha La',
        'Khardung La pass',
        'Camel safari in Hunder dunes',
        'Night under the stars at Pangong',
      ],
      description:
          'A high-altitude road journey over the Manali–Leh highway with '
          'acclimatisation days built in. Best from June to September.',
      imageUrl: _image('ladakh'),
      builtIn: true,
      itinerary: const [
        PackageDay('Day 1', 'Arrive in Manali',
            'Check in, evening walk on Mall Road and Old Manali.'),
        PackageDay('Days 2–3', 'Manali',
            'Hadimba Temple, Vashisht hot springs, Solang Valley adventure activities.'),
        PackageDay('Day 4', 'Manali → Jispa',
            'Cross the Atal Tunnel into Lahaul; overnight by the Bhaga river.'),
        PackageDay('Day 5', 'Jispa → Leh',
            'Long scenic drive over Baralacha La, More Plains and Tanglang La.'),
        PackageDay('Days 6–7', 'Leh (acclimatise)',
            'Rest day, then Shanti Stupa, Leh Palace, Thiksey and Hemis monasteries.'),
        PackageDay('Days 8–9', 'Nubra Valley',
            'Over Khardung La to Diskit Monastery and the sand dunes of Hunder.'),
        PackageDay('Days 10–11', 'Pangong Tso',
            'Drive via Shyok to Pangong Lake; lakeside camp overnight.'),
        PackageDay('Days 12–14', 'Leh',
            'Return to Leh. Magnetic Hill, Sangam viewpoint, local markets, buffer day.'),
        PackageDay('Day 15', 'Departure', 'Transfer to Leh airport.'),
      ],
    ),
    TourPackage(
      id: 'spiritual-north-india-15',
      title: 'Spiritual North India',
      durationDays: 15,
      cities: ['Delhi', 'Haridwar', 'Rishikesh', 'Varanasi', 'Bodh Gaya'],
      region: 'North India',
      category: 'Spiritual',
      pricePerPerson: 45500,
      hotelClass: '3-star',
      facilities: [
        'Hotel stay',
        'Daily breakfast',
        'Train tickets',
        'AC private cab',
        'English-speaking guide',
        'Sightseeing tours',
      ],
      highlights: [
        'Ganga Aarti at Har Ki Pauri',
        'Yoga sessions in Rishikesh',
        'Sunrise boat on the Varanasi ghats',
        'Mahabodhi Temple (UNESCO)',
      ],
      description:
          'A calm journey along the Ganga: temples, ghats, yoga and the '
          'place of the Buddha\'s enlightenment.',
      imageUrl: _image('varanasi'),
      builtIn: true,
      itinerary: const [
        PackageDay('Days 1–2', 'Delhi',
            'Arrival, Akshardham, Lotus Temple, Gurudwara Bangla Sahib.'),
        PackageDay('Days 3–4', 'Haridwar',
            'Train to Haridwar. Har Ki Pauri evening aarti, Mansa Devi by ropeway.'),
        PackageDay('Days 5–8', 'Rishikesh',
            'Morning yoga, Laxman Jhula, Beatles Ashram, Triveni Ghat aarti, optional rafting.'),
        PackageDay('Day 9', 'Rishikesh → Varanasi',
            'Overnight train via Haridwar.'),
        PackageDay('Days 10–12', 'Varanasi',
            'Sunrise boat ride, Kashi Vishwanath corridor, Sarnath, Dashashwamedh Ghat aarti.'),
        PackageDay('Days 13–14', 'Bodh Gaya',
            'Drive to Bodh Gaya. Mahabodhi Temple, the Great Buddha statue, monasteries.'),
        PackageDay('Day 15', 'Departure', 'Transfer to Gaya airport.'),
      ],
    ),
    TourPackage(
      id: 'singapore-bali-15',
      title: 'Singapore & Bali Island Hopper',
      durationDays: 15,
      cities: ['Singapore', 'Ubud', 'Seminyak', 'Nusa Penida'],
      region: 'South-East Asia',
      category: 'International',
      pricePerPerson: 145000,
      hotelClass: '4-star',
      facilities: [
        'Hotel stay',
        'Daily breakfast',
        'International flights',
        'Airport transfers',
        'Sightseeing tours',
        'Visa assistance',
        'Travel insurance',
      ],
      highlights: [
        'Gardens by the Bay light show',
        'Sentosa Island',
        'Ubud rice terraces and temples',
        'Kelingking Beach, Nusa Penida',
      ],
      description:
          'City lights in Singapore followed by temples, rice terraces and '
          'beaches in Bali. Return flights from Mumbai or Delhi included.',
      imageUrl: _image('bali'),
      builtIn: true,
      itinerary: const [
        PackageDay('Day 1', 'Fly to Singapore',
            'Arrival and transfer; evening at Marina Bay Sands promenade.'),
        PackageDay('Days 2–5', 'Singapore',
            'Gardens by the Bay, Sentosa, Universal Studios, Night Safari, Chinatown.'),
        PackageDay('Day 6', 'Singapore → Bali',
            'Short flight to Denpasar; transfer to Ubud.'),
        PackageDay('Days 7–9', 'Ubud',
            'Tegallalang rice terraces, Sacred Monkey Forest, Tirta Empul, Ulun Danu Bratan.'),
        PackageDay('Day 10', 'Nusa Penida day trip',
            'Speed boat to Kelingking, Broken Beach and Crystal Bay.'),
        PackageDay('Days 11–14', 'Seminyak',
            'Beach days, Tanah Lot and Uluwatu sunset temples, Kecak dance.'),
        PackageDay('Day 15', 'Return home', 'Flight back to India.'),
      ],
    ),

    // ------------------------------------------------------------ 20 DAYS
    TourPackage(
      id: 'grand-rajasthan-gujarat-20',
      title: 'Grand Rajasthan & Gujarat Heritage',
      durationDays: 20,
      cities: [
        'Ahmedabad',
        'Udaipur',
        'Jodhpur',
        'Jaisalmer',
        'Bikaner',
        'Jaipur',
        'Agra',
      ],
      region: 'West India',
      category: 'Culture',
      pricePerPerson: 78000,
      hotelClass: '4-star',
      facilities: [
        'Hotel stay',
        'Daily breakfast',
        'AC private cab',
        'English-speaking guide',
        'Entry tickets',
        'Sightseeing tours',
        '24×7 trip support',
      ],
      highlights: [
        'Ahmedabad heritage walk (UNESCO city)',
        'Mehrangarh Fort, Jodhpur',
        'Desert camp in Jaisalmer',
        'Taj Mahal finale',
      ],
      description:
          'Starting from Ahmedabad, a slow loop through Rajasthan\'s royal '
          'cities and the Thar desert, ending at the Taj Mahal.',
      imageUrl: _image('udaipur'),
      builtIn: true,
      itinerary: const [
        PackageDay('Days 1–2', 'Ahmedabad',
            'Old city heritage walk, Sabarmati Ashram, Adalaj stepwell, Sidi Saiyyed mosque.'),
        PackageDay('Day 3', 'Ahmedabad → Udaipur', 'Drive (5 h) via Shamlaji.'),
        PackageDay('Days 4–5', 'Udaipur',
            'City Palace, Lake Pichola cruise, Bagore ki Haveli folk show.'),
        PackageDay('Day 6', 'Ranakpur → Jodhpur',
            'Ranakpur Jain temples on the way to the Blue City.'),
        PackageDay('Days 7–8', 'Jodhpur',
            'Mehrangarh Fort, Jaswant Thada, Umaid Bhawan, blue-house lanes.'),
        PackageDay('Days 9–11', 'Jaisalmer',
            'Golden Fort, Patwon ki Haveli, Sam dunes camel ride and a night in a desert camp.'),
        PackageDay('Days 12–13', 'Bikaner',
            'Junagarh Fort, camel breeding farm, Karni Mata temple.'),
        PackageDay('Days 14–17', 'Jaipur',
            'Amber Fort, City Palace, Nahargarh sunset, block-printing workshop in Sanganer.'),
        PackageDay('Days 18–19', 'Agra',
            'Fatehpur Sikri on the way; Taj Mahal at sunrise, Agra Fort.'),
        PackageDay('Day 20', 'Departure', 'Transfer to Delhi airport (3.5 h).'),
      ],
    ),
    TourPackage(
      id: 'east-northeast-20',
      title: 'East & North-East Discovery',
      durationDays: 20,
      cities: [
        'Kolkata',
        'Darjeeling',
        'Gangtok',
        'Shillong',
        'Cherrapunji',
        'Kaziranga',
      ],
      region: 'East India',
      category: 'Nature',
      pricePerPerson: 72000,
      hotelClass: '3-star',
      facilities: [
        'Hotel stay',
        'Breakfast & dinner',
        'Domestic flights',
        'AC private cab',
        'Inner-line permits',
        'Sightseeing tours',
      ],
      highlights: [
        'Toy train in Darjeeling',
        'Tsomgo Lake, Sikkim',
        'Living root bridges, Meghalaya',
        'Rhino safari in Kaziranga',
      ],
      description:
          'Tea gardens, Himalayan monasteries, the wettest place on earth '
          'and one-horned rhinos, in one long journey.',
      imageUrl: _image('darjeeling'),
      builtIn: true,
      itinerary: const [
        PackageDay('Days 1–2', 'Kolkata',
            'Victoria Memorial, Howrah Bridge, Kumartuli, College Street.'),
        PackageDay('Days 3–6', 'Darjeeling',
            'Fly to Bagdogra. Tiger Hill sunrise, toy train, Happy Valley tea estate.'),
        PackageDay('Days 7–10', 'Gangtok',
            'Rumtek Monastery, MG Marg, Tsomgo Lake and Baba Mandir (permit included).'),
        PackageDay('Day 11', 'Fly to Guwahati',
            'Kamakhya Temple; drive to Shillong.'),
        PackageDay('Days 12–14', 'Shillong',
            'Umiam Lake, Elephant Falls, Mawlynnong village, Dawki river.'),
        PackageDay('Days 15–16', 'Cherrapunji',
            'Double-decker living root bridge trek, Nohkalikai Falls, Mawsmai caves.'),
        PackageDay('Days 17–19', 'Kaziranga',
            'Jeep and elephant safaris in Kaziranga National Park, tea-garden visit.'),
        PackageDay('Day 20', 'Departure', 'Transfer to Guwahati airport.'),
      ],
    ),

    // ------------------------------------------------------------ 30 DAYS
    TourPackage(
      id: 'incredible-india-grand-30',
      title: 'Incredible India Grand Tour',
      durationDays: 30,
      cities: [
        'Delhi',
        'Agra',
        'Jaipur',
        'Varanasi',
        'Goa',
        'Kochi',
        'Alappuzha',
        'Port Blair',
        'Havelock Island',
      ],
      region: 'Pan India',
      category: 'Culture',
      pricePerPerson: 165000,
      hotelClass: '4-star',
      facilities: [
        'Hotel stay',
        'Daily breakfast',
        'Domestic flights',
        'AC private cab',
        'Houseboat stay',
        'English-speaking guide',
        'Entry tickets',
        'Travel insurance',
        '24×7 trip support',
      ],
      highlights: [
        'Taj Mahal and Amber Fort',
        'Evening aarti in Varanasi',
        'Goa beaches and Kerala houseboat',
        'Radhanagar Beach, Havelock',
      ],
      description:
          'A month across India, from Mughal monuments and the Ganga to '
          'tropical beaches and the Andaman Islands, with all domestic '
          'flights included.',
      imageUrl: _image('andaman'),
      builtIn: true,
      itinerary: const [
        PackageDay('Days 1–3', 'Delhi', 'Old and New Delhi sightseeing; Qutub Minar.'),
        PackageDay('Days 4–5', 'Agra', 'Taj Mahal, Agra Fort, Fatehpur Sikri.'),
        PackageDay('Days 6–8', 'Jaipur', 'Amber Fort, City Palace, Hawa Mahal, bazaars.'),
        PackageDay('Days 9–11', 'Varanasi',
            'Fly from Jaipur. Ghats at sunrise, Sarnath, Ganga aarti.'),
        PackageDay('Days 12–16', 'Goa',
            'Fly to Goa. North and South Goa beaches, Old Goa churches, spice farm.'),
        PackageDay('Days 17–19', 'Kochi', 'Fly to Kochi. Fort Kochi, Mattancherry, Kathakali.'),
        PackageDay('Days 20–21', 'Alappuzha', 'Overnight houseboat on the backwaters.'),
        PackageDay('Days 22–24', 'Port Blair',
            'Fly via Chennai. Cellular Jail light show, Ross Island.'),
        PackageDay('Days 25–29', 'Havelock & Neil Islands',
            'Ferry to Havelock. Radhanagar Beach, snorkelling at Elephant Beach, Neil Island day trip.'),
        PackageDay('Day 30', 'Departure', 'Ferry to Port Blair and flight home.'),
      ],
    ),
    TourPackage(
      id: 'asia-explorer-30',
      title: 'Asia Explorer: Dubai, Singapore, Bali & Tokyo',
      durationDays: 30,
      cities: ['Dubai', 'Singapore', 'Bali', 'Tokyo', 'Kyoto'],
      region: 'Asia',
      category: 'International',
      pricePerPerson: 340000,
      hotelClass: '5-star',
      facilities: [
        'Hotel stay',
        'Daily breakfast',
        'International flights',
        'Airport transfers',
        'Sightseeing tours',
        'English-speaking guide',
        'Visa assistance',
        'Travel insurance',
        '24×7 trip support',
      ],
      highlights: [
        'Burj Khalifa observation deck',
        'Desert safari in Dubai',
        'Bali temples and beaches',
        'Bullet train from Tokyo to Kyoto',
      ],
      description:
          'Four countries in thirty days: desert skyline, garden city, '
          'island temples and Japan\'s blend of neon and tradition.',
      imageUrl: _image('tokyo'),
      builtIn: true,
      itinerary: const [
        PackageDay('Days 1–6', 'Dubai',
            'Burj Khalifa, Dubai Mall fountains, desert safari, Abu Dhabi day trip, Old Dubai souks.'),
        PackageDay('Days 7–11', 'Singapore',
            'Marina Bay, Gardens by the Bay, Sentosa, Night Safari, Little India.'),
        PackageDay('Days 12–18', 'Bali',
            'Ubud temples and rice terraces, Nusa Penida, Seminyak and Uluwatu.'),
        PackageDay('Days 19–25', 'Tokyo',
            'Shibuya, Asakusa, Meiji Shrine, teamLab, day trip to Mount Fuji and Hakone.'),
        PackageDay('Days 26–29', 'Kyoto',
            'Shinkansen to Kyoto. Fushimi Inari, Arashiyama bamboo grove, Nara deer park.'),
        PackageDay('Day 30', 'Return home', 'Flight from Osaka to India.'),
      ],
    ),
  ];
}
