import '../models/destination.dart';

/// Curated destination catalogue used by Destination Discovery.
///
/// Photos come from Wikimedia Commons under the licences shown in
/// [Destination.imageCredit]; each one was checked to load before it was added.
/// The categories match the interests used by the AI trip planner:
/// Nature, Adventure, Culture, Beach and Shopping.
class DestinationCatalog {
  DestinationCatalog._();

  static const List<String> categories = [
    'Nature',
    'Adventure',
    'Culture',
    'Beach',
    'Shopping',
  ];

  static const String _thumb =
      'https://thumb.wikimedia.org/wikipedia/commons/thumb';

  static const List<Destination> all = [
    Destination(
      id: 'manali',
      name: 'Manali',
      region: 'Himachal Pradesh',
      country: 'India',
      tagline: 'Snowy peaks and pine valleys',
      description:
          'A Himalayan hill town on the Beas river, loved for cool weather, '
          'apple orchards, cafés in Old Manali and easy access to snow '
          'activities in Solang Valley.',
      categories: ['Nature', 'Adventure'],
      highlights: [
        'Solang Valley',
        'Hadimba Devi Temple',
        'Old Manali',
        'Rohtang Pass (permit required)',
      ],
      bestTime: 'March to June; December to February for snow',
      imageUrl: '$_thumb/2/21/Mountain_valleys_in_Manali%2C_Himachal_Pradesh%2C_India_%282015%29.jpg/960px-Mountain_valleys_in_Manali%2C_Himachal_Pradesh%2C_India_%282015%29.jpg',
      imageCredit: 'TANYASHUKLA · Wikimedia Commons · CC BY-SA 4.0',
      featured: true,
      aliases: ['himachal', 'kullu'],
    ),
    Destination(
      id: 'goa',
      name: 'Goa',
      region: 'Goa',
      country: 'India',
      tagline: 'Golden beaches and Portuguese heritage',
      description:
          'India\'s favourite coastal escape: palm-lined beaches, old '
          'Portuguese churches, lively night markets and laid-back villages.',
      categories: ['Beach', 'Culture', 'Shopping'],
      highlights: [
        'Palolem Beach',
        'Basilica of Bom Jesus',
        'Fort Aguada',
        'Anjuna Flea Market',
      ],
      bestTime: 'November to February',
      imageUrl: '$_thumb/9/9c/Palolem_Beach%2C_South_Goa.jpg/960px-Palolem_Beach%2C_South_Goa.jpg',
      imageCredit: 'iMahesh · Wikimedia Commons · CC BY-SA 4.0',
      featured: true,
      aliases: ['palolem', 'panaji', 'calangute', 'baga'],
    ),
    Destination(
      id: 'jaipur',
      name: 'Jaipur',
      region: 'Rajasthan',
      country: 'India',
      tagline: 'The Pink City of palaces',
      description:
          'Rajasthan\'s capital, famous for its pink sandstone old city, '
          'hilltop forts, royal palaces and colourful bazaars for textiles '
          'and jewellery.',
      categories: ['Culture', 'Shopping'],
      highlights: [
        'Hawa Mahal',
        'Amber Fort',
        'City Palace',
        'Johari Bazaar',
      ],
      bestTime: 'October to March',
      imageUrl: '$_thumb/3/37/Hawa_Mahal_2011.jpg/960px-Hawa_Mahal_2011.jpg',
      imageCredit: 'Marcin Białek · Wikimedia Commons · CC BY-SA 4.0',
      featured: true,
      aliases: ['pink city', 'rajasthan'],
    ),
    Destination(
      id: 'alappuzha',
      name: 'Alappuzha',
      region: 'Kerala',
      country: 'India',
      tagline: 'Houseboats on calm backwaters',
      description:
          'The gateway to Kerala\'s backwaters, where traditional houseboats '
          'drift past coconut groves, paddy fields and quiet canal villages.',
      categories: ['Nature', 'Beach'],
      highlights: [
        'Backwater houseboat cruise',
        'Vembanad Lake',
        'Alappuzha Beach',
        'Marari Beach',
      ],
      bestTime: 'September to March',
      imageUrl: '$_thumb/4/4e/Kerala_backwaters%2C_Houseboats%2C_India.jpg/960px-Kerala_backwaters%2C_Houseboats%2C_India.jpg',
      imageCredit: 'Vyacheslav Argenberg · Wikimedia Commons · CC BY 4.0',
      featured: true,
      aliases: ['alleppey', 'kerala', 'backwaters'],
    ),
    Destination(
      id: 'ladakh',
      name: 'Ladakh',
      region: 'Ladakh',
      country: 'India',
      tagline: 'High-altitude lakes and monasteries',
      description:
          'A dramatic cold desert of mountain passes, blue lakes and '
          'Buddhist monasteries, best explored on a road trip.',
      categories: ['Adventure', 'Nature', 'Culture'],
      highlights: [
        'Pangong Tso',
        'Nubra Valley',
        'Khardung La',
        'Thiksey Monastery',
      ],
      bestTime: 'May to September',
      imageUrl: '$_thumb/8/8b/Pangong_Tso_2.jpg/960px-Pangong_Tso_2.jpg',
      imageCredit: 'KennyOMG · Wikimedia Commons · CC BY-SA 4.0',
      featured: true,
      aliases: ['leh', 'pangong'],
    ),
    Destination(
      id: 'rishikesh',
      name: 'Rishikesh',
      region: 'Uttarakhand',
      country: 'India',
      tagline: 'Yoga capital on the Ganges',
      description:
          'A riverside town in the Himalayan foothills known for yoga '
          'ashrams, the evening Ganga Aarti and white-water rafting.',
      categories: ['Adventure', 'Culture', 'Nature'],
      highlights: [
        'Lakshman Jhula',
        'Ganga Aarti at Triveni Ghat',
        'River rafting',
        'Beatles Ashram',
      ],
      bestTime: 'September to November; February to May',
      imageUrl: '$_thumb/6/63/Lakshman_Jhula_Bridge_-_Hrishikesh_-_Uttarakhand_001.jpg/960px-Lakshman_Jhula_Bridge_-_Hrishikesh_-_Uttarakhand_001.jpg',
      imageCredit: 'Snehrashmi · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['hrishikesh', 'uttarakhand'],
    ),
    Destination(
      id: 'udaipur',
      name: 'Udaipur',
      region: 'Rajasthan',
      country: 'India',
      tagline: 'The City of Lakes',
      description:
          'A romantic lakeside city of marble palaces, sunset boat rides and '
          'old havelis overlooking Lake Pichola.',
      categories: ['Culture'],
      highlights: [
        'City Palace',
        'Lake Pichola boat ride',
        'Jag Mandir',
        'Saheliyon ki Bari',
      ],
      bestTime: 'October to March',
      imageUrl: '$_thumb/7/74/20191207_Lake_Pichola%2C_City_Palace%2C_Udaipur%2C_1516_7254.jpg/960px-20191207_Lake_Pichola%2C_City_Palace%2C_Udaipur%2C_1516_7254.jpg',
      imageCredit: 'Jakub Hałun · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['city of lakes', 'pichola'],
    ),
    Destination(
      id: 'varanasi',
      name: 'Varanasi',
      region: 'Uttar Pradesh',
      country: 'India',
      tagline: 'Ancient ghats on the Ganges',
      description:
          'One of the world\'s oldest living cities, with sunrise boat rides '
          'along the ghats and the evening aarti on the river.',
      categories: ['Culture'],
      highlights: [
        'Dashashwamedh Ghat aarti',
        'Sunrise boat ride',
        'Kashi Vishwanath Temple',
        'Sarnath',
      ],
      bestTime: 'October to March',
      imageUrl: '$_thumb/5/5c/Varanasi%2C_India%2C_Ghats_on_Ganges_River.jpg/960px-Varanasi%2C_India%2C_Ghats_on_Ganges_River.jpg',
      imageCredit: 'Vyacheslav Argenberg · Wikimedia Commons · CC BY 4.0',
      aliases: ['banaras', 'benares', 'kashi'],
    ),
    Destination(
      id: 'andaman',
      name: 'Andaman Islands',
      region: 'Andaman and Nicobar',
      country: 'India',
      tagline: 'Turquoise water and white sand',
      description:
          'Tropical islands in the Bay of Bengal with clear water, coral '
          'reefs and some of India\'s most beautiful beaches.',
      categories: ['Beach', 'Adventure', 'Nature'],
      highlights: [
        'Radhanagar Beach',
        'Snorkelling at Elephant Beach',
        'Cellular Jail, Port Blair',
      ],
      bestTime: 'October to May',
      imageUrl: '$_thumb/e/e4/Havelock_Island%2C_Radhanagar_Beach%2C_Andaman_Islands.jpg/960px-Havelock_Island%2C_Radhanagar_Beach%2C_Andaman_Islands.jpg',
      imageCredit: 'Vyacheslav Argenberg · Wikimedia Commons · CC BY 4.0',
      aliases: ['andaman', 'havelock', 'port blair', 'swaraj dweep'],
    ),
    Destination(
      id: 'agra',
      name: 'Agra',
      region: 'Uttar Pradesh',
      country: 'India',
      tagline: 'Home of the Taj Mahal',
      description:
          'The Mughal city of the Taj Mahal, with grand red-sandstone forts '
          'and gardens along the Yamuna river.',
      categories: ['Culture'],
      highlights: [
        'Taj Mahal',
        'Agra Fort',
        'Mehtab Bagh',
        'Fatehpur Sikri',
      ],
      bestTime: 'October to March',
      imageUrl: '$_thumb/7/74/Taj_Mahal%2C_Agra%2C_India_edit2.jpg/960px-Taj_Mahal%2C_Agra%2C_India_edit2.jpg',
      imageCredit: 'Yann, edited by King of Hearts · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['taj mahal'],
    ),
    Destination(
      id: 'darjeeling',
      name: 'Darjeeling',
      region: 'West Bengal',
      country: 'India',
      tagline: 'Tea gardens facing Kanchenjunga',
      description:
          'A Himalayan hill station of rolling tea estates, a heritage toy '
          'train and sunrise views of Kanchenjunga.',
      categories: ['Nature', 'Culture'],
      highlights: [
        'Tiger Hill sunrise',
        'Tea estate tour',
        'Darjeeling Himalayan Railway',
        'Batasia Loop',
      ],
      bestTime: 'March to May; October to December',
      imageUrl: '$_thumb/d/d6/Kanchenjunga_range_from_tea_gardens_of_darjeeling.jpg/960px-Kanchenjunga_range_from_tea_gardens_of_darjeeling.jpg',
      imageCredit: 'Souviknshm · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['kanchenjunga'],
    ),
    Destination(
      id: 'dubai',
      name: 'Dubai',
      region: 'Dubai',
      country: 'United Arab Emirates',
      tagline: 'Skyscrapers, souks and desert',
      description:
          'A futuristic skyline beside the desert, with record-breaking '
          'towers, huge malls, traditional souks and desert safaris.',
      categories: ['Shopping', 'Adventure'],
      highlights: [
        'Burj Khalifa',
        'The Dubai Mall',
        'Desert safari',
        'Gold Souk',
      ],
      bestTime: 'November to March',
      imageUrl: '$_thumb/4/46/Dubai_Skyline_mit_Burj_Khalifa_%28cropped%29.jpg/960px-Dubai_Skyline_mit_Burj_Khalifa_%28cropped%29.jpg',
      imageCredit: 'Tim Reckmann · Wikimedia Commons · CC BY-SA 3.0',
      featured: true,
      aliases: ['uae', 'burj khalifa'],
    ),
    Destination(
      id: 'bali',
      name: 'Bali',
      region: 'Bali',
      country: 'Indonesia',
      tagline: 'Temples, rice terraces and surf',
      description:
          'An island of Hindu temples, green rice terraces, volcano views '
          'and beach towns for surfing and sunsets.',
      categories: ['Beach', 'Culture', 'Nature'],
      highlights: [
        'Pura Ulun Danu Bratan',
        'Tegallalang Rice Terraces',
        'Uluwatu Temple',
        'Ubud',
      ],
      bestTime: 'April to October',
      imageUrl: '$_thumb/c/c0/Brantan_Bali_Pura-Ulun-Danu-Bratan-01.jpg/960px-Brantan_Bali_Pura-Ulun-Danu-Bratan-01.jpg',
      imageCredit: 'CEphoto, Uwe Aranas · Wikimedia Commons · CC BY-SA 3.0',
      featured: true,
      aliases: ['ubud', 'indonesia'],
    ),
    Destination(
      id: 'paris',
      name: 'Paris',
      region: 'Île-de-France',
      country: 'France',
      tagline: 'Art, cafés and the Eiffel Tower',
      description:
          'The French capital of world-class museums, riverside walks, '
          'historic neighbourhoods and elegant shopping streets.',
      categories: ['Culture', 'Shopping'],
      highlights: [
        'Eiffel Tower',
        'Louvre Museum',
        'Montmartre',
        'Seine river cruise',
      ],
      bestTime: 'April to June; September to October',
      imageUrl: '$_thumb/b/b7/Paris_-_The_Eiffel_Tower_in_spring_-_2307.jpg/960px-Paris_-_The_Eiffel_Tower_in_spring_-_2307.jpg',
      imageCredit: 'Jorge Royan · Wikimedia Commons · CC BY-SA 3.0',
      aliases: ['france', 'eiffel'],
    ),
    Destination(
      id: 'singapore',
      name: 'Singapore',
      region: 'Singapore',
      country: 'Singapore',
      tagline: 'Garden city of the future',
      description:
          'A clean, compact city-state with futuristic gardens, diverse food '
          'neighbourhoods and some of Asia\'s best shopping.',
      categories: ['Shopping', 'Culture'],
      highlights: [
        'Gardens by the Bay',
        'Marina Bay Sands',
        'Sentosa Island',
        'Orchard Road',
      ],
      bestTime: 'All year; February to April is drier',
      imageUrl: '$_thumb/b/b0/Singapore_Marina_Bay_Dusk_2018-02-27.jpg/960px-Singapore_Marina_Bay_Dusk_2018-02-27.jpg',
      imageCredit: 'Benh LIEU SONG · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['marina bay', 'sentosa'],
    ),
    Destination(
      id: 'tokyo',
      name: 'Tokyo',
      region: 'Kantō',
      country: 'Japan',
      tagline: 'Neon streets and quiet shrines',
      description:
          'Japan\'s vast capital, where neon districts, ancient temples, '
          'peaceful gardens and electronics markets sit side by side.',
      categories: ['Culture', 'Shopping'],
      highlights: [
        'Shibuya Crossing',
        'Senso-ji Temple',
        'Shinjuku Gyoen',
        'Akihabara',
      ],
      bestTime: 'March to May; October to November',
      imageUrl: '$_thumb/c/cf/Shinjuku_skyline%2C_Tokyo_-_Sony_A7R_%2811831328835%29.jpg/960px-Shinjuku_skyline%2C_Tokyo_-_Sony_A7R_%2811831328835%29.jpg',
      imageCredit: 'Luke Ma · Wikimedia Commons · CC BY 2.0',
      aliases: ['japan', 'shinjuku', 'shibuya'],
    ),
    Destination(
      id: 'ahmedabad',
      name: 'Ahmedabad',
      region: 'Gujarat',
      country: 'India',
      tagline: 'Heritage, handloom and street food by the Sabarmati',
      description:
          'A UNESCO World Heritage City on the Sabarmati River, known for its '
          'historic old city, stepwells, handloom textiles and lively food streets.',
      categories: ['Culture', 'Shopping'],
      highlights: [
        'Sabarmati Ashram',
        'Adalaj Stepwell',
        'Kankaria Lake',
        'Sabarmati Riverfront',
      ],
      bestTime: 'October to March (cooler months)',
      imageUrl: '$_thumb/1/1b/SG_Highway_Skyline.jpg/960px-SG_Highway_Skyline.jpg',
      imageCredit: 'Kushagra140 · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['amdavad', 'gujarat'],
    ),
    Destination(
      id: 'mumbai',
      name: 'Mumbai',
      region: 'Maharashtra',
      country: 'India',
      tagline: 'Sea-facing promenades, colonial landmarks and film city buzz',
      description:
          'India\'s financial capital and film hub, with a curved sea promenade, '
          'Victorian Gothic architecture, island caves and bustling local trains.',
      categories: ['Culture', 'Shopping'],
      highlights: [
        'Gateway of India',
        'Chhatrapati Shivaji Maharaj Terminus',
        'Marine Drive',
        'Elephanta Caves',
      ],
      bestTime: 'November to February (dry, cooler weather)',
      imageUrl: '$_thumb/5/5c/Marine_Lines_Mumbai_2021.jpg/960px-Marine_Lines_Mumbai_2021.jpg',
      imageCredit: 'Dr Vikramjit Kakati · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['bombay'],
    ),
    Destination(
      id: 'delhi',
      name: 'Delhi',
      region: 'Delhi',
      country: 'India',
      tagline: 'Mughal monuments, bazaars and the heart of the capital',
      description:
          'India\'s capital, where Mughal-era monuments such as the Red Fort and '
          'Humayun\'s Tomb stand beside India Gate and busy old-city bazaars.',
      categories: ['Culture', 'Shopping'],
      highlights: [
        'Red Fort',
        'India Gate',
        'Qutub Minar',
        'Humayun\'s Tomb',
      ],
      bestTime: 'October to March (pleasant weather)',
      imageUrl: '$_thumb/d/df/India_Gate%2C_New_Delhi_from_West.jpg/960px-India_Gate%2C_New_Delhi_from_West.jpg',
      imageCredit: 'Nikhilb239 · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['new delhi', 'old delhi'],
    ),
    // Added in the completion pass. Each photo is a licensed Wikimedia Commons
    // image of the place, checked by eye; its credit is in imageCredit.
    Destination(
      id: 'kolkata',
      name: 'Kolkata',
      region: 'West Bengal',
      country: 'India',
      tagline: 'Colonial landmarks, street food and literary cafés',
      description:
          'A river city known for colonial-era buildings, tram rides, '
          'Bengali sweets and a strong arts scene.',
      categories: ['Culture', 'Shopping'],
      highlights: ['Victoria Memorial', 'Howrah Bridge', 'Dakshineswar Kali Temple', 'Park Street'],
      bestTime: 'October to March',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/30/Pavilion_at_the_Victoria_Memorial%2C_Kolkata_01.jpg/960px-Pavilion_at_the_Victoria_Memorial%2C_Kolkata_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Bernard Gagnon · Wikimedia Commons · CC BY-SA 3.0',
      aliases: ['calcutta', 'bengal'],
    ),
    Destination(
      id: 'hyderabad',
      name: 'Hyderabad',
      region: 'Telangana',
      country: 'India',
      tagline: 'Old-city charm, biryani and historic forts',
      description:
          'A city of lakes, royal monuments and famous biryani, with an old '
          'quarter full of bazaars and a modern tech corridor.',
      categories: ['Culture', 'Shopping'],
      highlights: ['Charminar', 'Golconda Fort', 'Hussain Sagar Lake', 'Laad Bazaar'],
      bestTime: 'October to February',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fb/Charminar%2C_Hyderabad%2C_11-12-2022.jpg/960px-Charminar%2C_Hyderabad%2C_11-12-2022.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'TheAafi · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['deccan', 'nizam'],
    ),
    Destination(
      id: 'bengaluru',
      name: 'Bengaluru',
      region: 'Karnataka',
      country: 'India',
      tagline: 'Gardens, cafés and a relaxed city climate',
      description:
          'A garden city with pleasant weather most of the year, good cafés '
          'and easy day trips to the hills around it.',
      categories: ['Nature', 'Shopping'],
      highlights: ['Lalbagh Botanical Garden', 'Cubbon Park', 'Bangalore Palace', 'Nandi Hills (day trip)'],
      bestTime: 'September to February',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ec/Bangalore_Palace_facade_on_a_cloudy_day.jpg/960px-Bangalore_Palace_facade_on_a_cloudy_day.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Anupam Chatterjee · Wikimedia Commons · CC BY 4.0',
      aliases: ['bangalore'],
    ),
    Destination(
      id: 'chennai',
      name: 'Chennai',
      region: 'Tamil Nadu',
      country: 'India',
      tagline: 'Marina beach, temples and classical music',
      description:
          'A coastal city with a long beach, historic temples and a strong '
          'tradition of classical music and dance.',
      categories: ['Beach', 'Culture'],
      highlights: ['Marina Beach', 'Kapaleeshwarar Temple', 'Fort St George', 'Government Museum'],
      bestTime: 'November to February',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2a/Chennai_Marina_Beach_in_2022%2C_October_01.jpg/960px-Chennai_Marina_Beach_in_2022%2C_October_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Pinakpani · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['madras'],
    ),
    Destination(
      id: 'kochi',
      name: 'Kochi',
      region: 'Kerala',
      country: 'India',
      tagline: 'Harbour views, Chinese fishing nets and Kathakali',
      description:
          'A harbour city with colonial streets in Fort Kochi, backwater '
          'access and traditional Kerala performing arts.',
      categories: ['Beach', 'Culture'],
      highlights: ['Fort Kochi', 'Chinese fishing nets', 'Mattancherry Palace', 'Kathakali performance'],
      bestTime: 'October to March',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a6/Fort_Kochi_-_Fisher_-_1.jpg/960px-Fort_Kochi_-_Fisher_-_1.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Ingo Mehling · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['cochin', 'ernakulam'],
    ),
    Destination(
      id: 'madurai',
      name: 'Madurai',
      region: 'Tamil Nadu',
      country: 'India',
      tagline: 'A temple city that never fully sleeps',
      description:
          'One of South India\'s oldest continuously inhabited cities, built '
          'around the Meenakshi Amman Temple.',
      categories: ['Culture', 'Shopping'],
      highlights: ['Meenakshi Amman Temple', 'Thirumalai Nayak Palace', 'Puthu Mandapam', 'Gandhi Memorial Museum'],
      bestTime: 'October to March',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fe/Inside_Meenakshi_Amman_Temple%2C_Madurai.JPG/960px-Inside_Meenakshi_Amman_Temple%2C_Madurai.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Viswa2625 · Wikimedia Commons · CC BY-SA 3.0',
      aliases: ['temple city'],
    ),
    Destination(
      id: 'pune',
      name: 'Pune',
      region: 'Maharashtra',
      country: 'India',
      tagline: 'Hill forts, museums and a student-city buzz',
      description:
          'A hill-fringed city with Maratha-era forts within easy reach, '
          'historic palaces and a lively café and student scene.',
      categories: ['Culture', 'Nature'],
      highlights: ['Shaniwar Wada', 'Sinhagad Fort', 'Aga Khan Palace', 'Pataleshwar Cave Temple'],
      bestTime: 'June to February',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/93/Front_view_closeup_of_Shaniwar_Wada_illuminated.jpg/960px-Front_view_closeup_of_Shaniwar_Wada_illuminated.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'DesiBoy101 · Wikimedia Commons · CC BY 4.0',
      aliases: ['poona'],
    ),
    Destination(
      id: 'shimla',
      name: 'Shimla',
      region: 'Himachal Pradesh',
      country: 'India',
      tagline: 'Colonial hill town with a toy train',
      description:
          'A hill station built by the British, with a pedestrian Mall Road, '
          'pine forests and the narrow-gauge Kalka–Shimla railway.',
      categories: ['Nature', 'Culture'],
      highlights: ['The Mall Road', 'Jakhoo Temple', 'Kalka–Shimla toy train', 'Christ Church'],
      bestTime: 'March to June; December to February for snow',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/02/Bird_eye_View_of_Mall_Road_%2C_Shimla.jpg/960px-Bird_eye_View_of_Mall_Road_%2C_Shimla.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Navneet Sharma · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['himachal'],
    ),
    Destination(
      id: 'amritsar',
      name: 'Amritsar',
      region: 'Punjab',
      country: 'India',
      tagline: 'The Golden Temple and the Wagah border ceremony',
      description:
          'The spiritual heart of Sikhism, with the Golden Temple, the '
          'historic Jallianwala Bagh and the flag ceremony at Wagah.',
      categories: ['Culture', 'Shopping'],
      highlights: ['Golden Temple', 'Jallianwala Bagh', 'Wagah Border ceremony', 'Durgiana Temple'],
      bestTime: 'October to March',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c4/Akal_Takht_and_Harmandir_Sahib%2C_Amritsar%2C_Punjab%2C_India.jpg/960px-Akal_Takht_and_Harmandir_Sahib%2C_Amritsar%2C_Punjab%2C_India.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Jasleen Kaur · Wikimedia Commons · CC BY-SA 2.0',
      aliases: ['golden temple'],
    ),
    Destination(
      id: 'jodhpur',
      name: 'Jodhpur',
      region: 'Rajasthan',
      country: 'India',
      tagline: 'The blue city under a hill fort',
      description:
          'Known as the blue city for its painted houses, with the massive '
          'Mehrangarh Fort above the old town and busy spice markets.',
      categories: ['Culture', 'Shopping'],
      highlights: ['Mehrangarh Fort', 'Umaid Bhawan Palace', 'Jaswant Thada', 'Clock Tower market'],
      bestTime: 'October to March',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dd/20191210_Brama_Twierdzy_Mehrangarh_1055_7868.jpg/960px-20191210_Brama_Twierdzy_Mehrangarh_1055_7868.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Jakub Hałun · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['blue city'],
    ),
    Destination(
      id: 'jaisalmer',
      name: 'Jaisalmer',
      region: 'Rajasthan',
      country: 'India',
      tagline: 'Golden sandstone fort and desert camps',
      description:
          'A desert city built from yellow sandstone, with a living fort, '
          'havelis carved in stone and camel safaris into the Thar.',
      categories: ['Adventure', 'Culture'],
      highlights: ['Jaisalmer Fort', 'Sam Sand Dunes', 'Patwon Ki Haveli', 'Gadisar Lake'],
      bestTime: 'November to February',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1e/Corner_Battlements_Jaisalmer_Fort_Dec14_DSC_6282.jpg/960px-Corner_Battlements_Jaisalmer_Fort_Dec14_DSC_6282.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Timothy A. Gonsalves · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['thar desert', 'golden city'],
    ),
    Destination(
      id: 'mysuru',
      name: 'Mysuru',
      region: 'Karnataka',
      country: 'India',
      tagline: 'Royal palace city and the Dasara festival',
      description:
          'A former royal capital known for its illuminated palace, '
          'sandalwood crafts and the grand Dasara celebrations each autumn.',
      categories: ['Culture', 'Shopping'],
      highlights: ['Mysore Palace', 'Chamundi Hill', 'Brindavan Gardens', 'St. Philomena\'s Church'],
      bestTime: 'September to March',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/d1/Amba_Vilas_palace.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail_unscaled',
      imageCredit: 'Darakshanehaluddin · Wikimedia Commons · CC0',
      aliases: ['mysore'],
    ),
    Destination(
      id: 'ooty',
      name: 'Ooty',
      region: 'Tamil Nadu',
      country: 'India',
      tagline: 'Tea gardens and cool hill air',
      description:
          'A hill station in the Nilgiris, known for tea estates, a famous '
          'botanical garden and the mountain train.',
      categories: ['Nature', 'Adventure'],
      highlights: ['Government Botanical Garden', 'Doddabetta Peak', 'Ooty Lake', 'Nilgiri Mountain Railway'],
      bestTime: 'April to June; September to November',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5d/A_pavilion%2C_Botanical_Garden%2C_Ooty.jpg/960px-A_pavilion%2C_Botanical_Garden%2C_Ooty.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Rangan Datta Wiki · Wikimedia Commons · CC BY-SA 4.0',
      aliases: ['udhagamandalam', 'nilgiris'],
    ),
    Destination(
      id: 'shillong',
      name: 'Shillong',
      region: 'Meghalaya',
      country: 'India',
      tagline: 'Waterfalls, pine hills and live music',
      description:
          'The capital of Meghalaya, set among pine-covered hills, with '
          'waterfalls nearby and a strong live-music scene.',
      categories: ['Nature', 'Adventure'],
      highlights: ['Elephant Falls', 'Umiam Lake', 'Shillong Peak', 'Nohkalikai Falls (Cherrapunji)'],
      bestTime: 'October to June',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/59/Elephant_Fall_of_Shillong.JPG/960px-Elephant_Fall_of_Shillong.JPG?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Simbu123 · Wikimedia Commons · CC BY-SA 3.0',
      aliases: ['meghalaya', 'cherrapunji'],
    ),
    Destination(
      id: 'gangtok',
      name: 'Gangtok',
      region: 'Sikkim',
      country: 'India',
      tagline: 'Mountain views and hilltop monasteries',
      description:
          'The capital of Sikkim, with a pedestrian market street, Buddhist '
          'monasteries and views of the Kanchenjunga range on clear days.',
      categories: ['Nature', 'Culture'],
      highlights: ['Rumtek Monastery', 'MG Marg', 'Tsomgo Lake', 'Enchey Monastery'],
      bestTime: 'March to June; September to December',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Rumtek_Monastery_alias_Dharma_Chakra_Centre_near_Gangtok%2C_East_Sikkim_01.jpg/960px-Rumtek_Monastery_alias_Dharma_Chakra_Centre_near_Gangtok%2C_East_Sikkim_01.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Anjan Kumar Kundu · Wikimedia Commons · CC BY 4.0',
      aliases: ['sikkim'],
    ),
    Destination(
      id: 'puducherry',
      name: 'Puducherry',
      region: 'Puducherry',
      country: 'India',
      tagline: 'French colonial streets by the sea',
      description:
          'A seaside town with French-style streets, cafés near the promenade '
          'and the nearby Auroville community.',
      categories: ['Beach', 'Culture'],
      highlights: ['Promenade Beach', 'French Quarter', 'Paradise Beach', 'Auroville (visitor rules apply)'],
      bestTime: 'October to March',
      imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b1/French_Quarter%2C_Pondicherry_%281%29_%2823662163628%29.jpg/960px-French_Quarter%2C_Pondicherry_%281%29_%2823662163628%29.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=thumbnail',
      imageCredit: 'Richard Mortel from Riyadh, Saudi Arabia · Wikimedia Commons · CC BY 2.0',
      aliases: ['pondicherry'],
    ),
  ];

  static List<Destination> get featured =>
      all.where((destination) => destination.featured).toList();

  static Destination? byId(String id) {
    for (final destination in all) {
      if (destination.id == id) return destination;
    }
    return null;
  }

  /// Finds the catalogue entry that free text (for example a saved trip's
  /// destination) refers to, or null if none matches.
  static Destination? matchName(String text) {
    for (final destination in all) {
      if (destination.isNamedBy(text)) return destination;
    }
    return null;
  }

  /// Applies the Discovery search box and category filter together.
  static List<Destination> search({String query = '', String? category}) {
    return all
        .where((d) => d.hasCategory(category) && d.matches(query))
        .toList();
  }
}
