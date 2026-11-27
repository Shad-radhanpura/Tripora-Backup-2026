import '../models/tourist_attraction.dart';

/// Curated tourist attractions for Destination Explorer, keyed by the
/// destination ID used in [DestinationCatalog].
///
/// To add a destination: add its attractions here with a photo that has been
/// checked to show that place, and record the photo's author and licence.
/// Leave imageUrl null if no checked photo exists; the app then shows a
/// placeholder instead of an unrelated picture.
class AttractionCatalog {
  AttractionCatalog._();

  static const String _commons = 'https://thumb.wikimedia.org/wikipedia/commons/thumb';

  static const Map<String, List<TouristAttraction>> _byDestination = {
    'ahmedabad': [
      TouristAttraction(
        name: 'Sabarmati Ashram',
        location: 'Ahmedabad, Gujarat',
        description:
            'Mahatma Gandhi lived here from 1917 to 1930, and the ashram was '
            'the base of his movement for independence.',
        imageUrl: '$_commons/3/32/Sabarmati_Ashram_-_Ahmedabad_-_Gujarat_-_DSC001.jpg/960px-Sabarmati_Ashram_-_Ahmedabad_-_Gujarat_-_DSC001.jpg',
        imageCredit: 'Snehrashmi · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Adalaj Stepwell',
        location: 'Adalaj, near Ahmedabad',
        description:
            '15th-century stepwell with carved pillars and several levels of '
            'steps, built to store water and shelter travellers.',
        imageUrl: '$_commons/1/13/Stepwell_of_adalaj.jpg/960px-Stepwell_of_adalaj.jpg',
        imageCredit: 'Rahilarious · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Kankaria Lake',
        location: 'Maninagar, Ahmedabad',
        description:
            'A 15th-century lake with a garden island, a toy train ride and '
            'lakeside stalls in the evening.',
        imageUrl: '$_commons/e/ef/Toy_train_at_Kankaria_Lake%2C_Ahmedabad%2C_Gujarat%2C_India.jpg/960px-Toy_train_at_Kankaria_Lake%2C_Ahmedabad%2C_Gujarat%2C_India.jpg',
        imageCredit: 'Gannu03 · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Sabarmati Riverfront',
        location: 'Ahmedabad',
        description:
            'A landscaped riverside promenade with walkways, gardens and the '
            'Atal Pedestrian Bridge.',
        imageUrl: '$_commons/a/af/Sabarmati_riverfront_and_Atal_Pedestrian_Bridge_11.jpg/960px-Sabarmati_riverfront_and_Atal_Pedestrian_Bridge_11.jpg',
        imageCredit: 'Pravega · Wikimedia Commons · CC0',
      ),
    ],
    'goa': [
      TouristAttraction(
        name: 'Basilica of Bom Jesus',
        location: 'Old Goa',
        description:
            '16th-century church that holds the tomb of St Francis Xavier. '
            'It is part of the UNESCO World Heritage churches of Goa.',
        imageUrl: '$_commons/9/9e/Front_Elevation_of_Basilica_of_Bom_Jesus.jpg/960px-Front_Elevation_of_Basilica_of_Bom_Jesus.jpg',
        imageCredit: 'iMahesh · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Fort Aguada',
        location: 'Candolim, North Goa',
        description:
            '17th-century Portuguese fort above the sea, with a lighthouse '
            'and views over the coast.',
        imageUrl: '$_commons/f/f8/Fort_Aguada_Goa.JPG/960px-Fort_Aguada_Goa.JPG',
        imageCredit: 'Drmarathe · Wikimedia Commons · CC BY-SA 3.0',
      ),
      TouristAttraction(
        name: 'Palolem Beach',
        location: 'Canacona, South Goa',
        description:
            'A calm, crescent-shaped beach with palm shade and beach shacks, '
            'quieter than the north coast.',
        imageUrl: '$_commons/e/ed/Palolem_beach.jpg/960px-Palolem_beach.jpg',
        imageCredit: 'Satyajit Nayak · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Dudhsagar Falls',
        location: 'Mollem, South Goa',
        description:
            'A tall, multi-tiered waterfall reached by jeep safari or a short '
            'trek through the forest.',
        imageUrl: '$_commons/d/d3/Dudhsagar_Falls%2CGoa.jpg/960px-Dudhsagar_Falls%2CGoa.jpg',
        imageCredit: 'Naren2910 · Wikimedia Commons · CC BY-SA 3.0',
      ),
    ],
    'jaipur': [
      TouristAttraction(
        name: 'Hawa Mahal',
        location: 'Badi Chaupar, Jaipur',
        description:
            'A pink sandstone palace with 953 small windows, built in 1799 so '
            'royal women could watch the street unseen.',
        imageUrl: '$_commons/a/a8/20191218%2C_Hawa_Mahal_%28The_Palace_of_Winds%29_in_Jaipur%2C_1128_9119.jpg/960px-20191218%2C_Hawa_Mahal_%28The_Palace_of_Winds%29_in_Jaipur%2C_1128_9119.jpg',
        imageCredit: 'Jakub Hałun · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Amber Fort',
        location: 'Amer, about 11 km from Jaipur',
        description:
            'A hilltop fort-palace of the Kachhwaha rulers, known for its '
            'mirror-work halls and lake views.',
        imageUrl: '$_commons/b/b1/Amber_Fort%2C_Jaipur%2C_20191219_1012_9512.jpg/960px-Amber_Fort%2C_Jaipur%2C_20191219_1012_9512.jpg',
        imageCredit: 'Jakub Hałun · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Jantar Mantar',
        location: 'Near City Palace, Jaipur',
        description:
            '18th-century open-air observatory with giant stone sundials and '
            'instruments for measuring the sky.',
        imageUrl: '$_commons/c/c9/20191218_Jantar_Mantar%2C_Jaipur_0906_8983_DxO.jpg/960px-20191218_Jantar_Mantar%2C_Jaipur_0906_8983_DxO.jpg',
        imageCredit: 'Jakub Hałun · Wikimedia Commons · CC BY-SA 4.0',
      ),
    ],
    'udaipur': [
      TouristAttraction(
        name: 'City Palace',
        location: 'Udaipur, on Lake Pichola',
        description:
            'Palace complex of the Mewar rulers, begun in the 16th century, '
            'with courtyards, museums and lake views.',
        imageUrl: '$_commons/8/82/City_Palace_Udaipur_Rajasthan_India.JPG/960px-City_Palace_Udaipur_Rajasthan_India.JPG',
        imageCredit: 'Hirumon · Wikimedia Commons · CC BY 3.0',
      ),
      TouristAttraction(
        name: 'Lake Pichola',
        location: 'Udaipur',
        description:
            'An artificial lake ringed by palaces and ghats, known for boat '
            'rides and sunset views.',
        imageUrl: '$_commons/d/dd/Lake_Pichola_at_sunset%2C_Udaipur%2C_Rajasthan%2C_India.jpg/960px-Lake_Pichola_at_sunset%2C_Udaipur%2C_Rajasthan%2C_India.jpg',
        imageCredit: 'UnpetitproleX · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Jagdish Temple',
        location: 'Near City Palace, Udaipur',
        description:
            '17th-century Hindu temple dedicated to Lord Jagannath, with '
            'richly carved stone walls.',
        imageUrl: '$_commons/e/ed/Jagdish_Temple_Udaipur.jpg/960px-Jagdish_Temple_Udaipur.jpg',
        imageCredit: 'Ingo Mehling · Wikimedia Commons · CC BY-SA 3.0',
      ),
    ],
    'manali': [
      TouristAttraction(
        name: 'Solang Valley',
        location: 'Near Manali',
        description:
            'High valley known for snow play, skiing and paragliding in winter.',
        imageUrl: '$_commons/b/b5/Solang_Valley%2C_Manali.jpg/960px-Solang_Valley%2C_Manali.jpg',
        imageCredit: 'Vikas Choudhary · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Hadimba Devi Temple',
        location: 'Dhungri, Manali',
        description:
            'Wooden temple set among cedar trees, dedicated to Goddess '
            'Hadimba, with a pagoda-style roof.',
        imageUrl: '$_commons/2/28/Hadimba_Devi_Temple_Manali.jpg/960px-Hadimba_Devi_Temple_Manali.jpg',
        imageCredit: 'Itsarti · Wikimedia Commons · CC BY-SA 4.0',
      ),
    ],
    'varanasi': [
      TouristAttraction(
        name: 'Dashashwamedh Ghat',
        location: 'Old city, Varanasi',
        description:
            'The main riverside ghat on the Ganga, famous for the evening '
            'Ganga Aarti ceremony.',
        imageUrl: '$_commons/3/34/Dashashwamedh_Ghat_Varanasi.jpg/960px-Dashashwamedh_Ghat_Varanasi.jpg',
        imageCredit: 'Kasyap · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Kashi Vishwanath Temple',
        location: 'Vishwanath Gali, Varanasi',
        description:
            'One of the most sacred Shiva temples in India, on the western '
            'bank of the Ganga.',
        imageUrl: '$_commons/e/ec/Shri_Kashi_Vishwanath_Temple_2.jpg/960px-Shri_Kashi_Vishwanath_Temple_2.jpg',
        imageCredit: 'Gannu03 · Wikimedia Commons · CC BY-SA 4.0',
      ),
    ],
    'mumbai': [
      TouristAttraction(
        name: 'Gateway of India',
        location: 'Apollo Bunder, Colaba',
        description:
            'Basalt arch on the waterfront, built in 1924 and overlooking the '
            'harbour.',
        imageUrl: '$_commons/d/df/Panoramic_view_of_Taj_Palace_Hotel_and_Taj_Tower_with_the_iconic_Gateway_of_India_in_the_background.jpg/960px-Panoramic_view_of_Taj_Palace_Hotel_and_Taj_Tower_with_the_iconic_Gateway_of_India_in_the_background.jpg',
        imageCredit: 'iMahesh · Wikimedia Commons · CC BY-SA 4.0',
      ),
      TouristAttraction(
        name: 'Chhatrapati Shivaji Maharaj Terminus',
        location: 'Fort area, Mumbai',
        description:
            'Victorian Gothic railway station and UNESCO World Heritage Site, '
            'busy with suburban trains.',
        imageUrl: '$_commons/c/c5/Chhatrapati_Shivaji_Terminus_%28Victoria_Terminus%29.jpg/960px-Chhatrapati_Shivaji_Terminus_%28Victoria_Terminus%29.jpg',
        imageCredit: 'Joe Ravi · Wikimedia Commons · CC BY-SA 3.0',
      ),
      TouristAttraction(
        name: 'Marine Drive',
        location: 'Nariman Point to Chowpatty',
        description:
            'Curved sea-facing promenade of about 3.6 km, lit up at night as '
            'the "Queen\'s Necklace".',
        imageUrl: '$_commons/0/0e/Mumbai_03-2016_46_evening_at_Marine_Drive.jpg/960px-Mumbai_03-2016_46_evening_at_Marine_Drive.jpg',
        imageCredit: 'A.Savin · Wikimedia Commons · FAL',
      ),
      TouristAttraction(
        name: 'Elephanta Caves',
        location: 'Elephanta Island, reached by ferry',
        description:
            'Rock-cut Shiva caves carved between the 5th and 8th centuries, on '
            'an island in Mumbai Harbour.',
        imageUrl: '$_commons/4/41/Elephanta_Caves%2C_India.jpg/960px-Elephanta_Caves%2C_India.jpg',
        imageCredit: 'Vyacheslav Argenberg · Wikimedia Commons · CC BY 4.0',
      ),
    ],
    'delhi': [
      TouristAttraction(
        name: 'Red Fort',
        location: 'Old Delhi',
        description:
            'Red sandstone Mughal fort built by Shah Jahan in the 17th century. '
            'It is a UNESCO World Heritage Site.',
        imageUrl: '$_commons/0/0d/Red_Fort_in_Delhi_03-2016_img3.jpg/960px-Red_Fort_in_Delhi_03-2016_img3.jpg',
        imageCredit: 'A.Savin · Wikimedia Commons · FAL',
      ),
      TouristAttraction(
        name: 'India Gate',
        location: 'Rajpath, New Delhi',
        description:
            '42-metre war memorial arch dedicated to Indian soldiers who died '
            'in the First World War.',
        imageUrl: '$_commons/8/86/India_Gate_1_%28New_Delhi%29.jpg/960px-India_Gate_1_%28New_Delhi%29.jpg',
        imageCredit: 'Subeesh Balan · Wikimedia Commons · CC BY-SA 3.0',
      ),
      TouristAttraction(
        name: 'Qutub Minar',
        location: 'Mehrauli, South Delhi',
        description:
            'Red sandstone minaret of about 73 metres, begun in 1193. It is a '
            'UNESCO World Heritage Site.',
        imageUrl: '$_commons/5/57/Qutub_Minar_in_Delhi_03-2016.jpg/960px-Qutub_Minar_in_Delhi_03-2016.jpg',
        imageCredit: 'A.Savin · Wikimedia Commons · FAL',
      ),
      TouristAttraction(
        name: "Humayun's Tomb",
        location: 'Nizamuddin, Delhi',
        description:
            'Red sandstone Mughal tomb set in a formal garden, widely seen as a '
            'forerunner of the Taj Mahal.',
        imageUrl: '$_commons/d/d4/Humayun%27s_Tomb%2C_Delhi_1.jpg/960px-Humayun%27s_Tomb%2C_Delhi_1.jpg',
        imageCredit: 'Naveen R Gowda · Wikimedia Commons · CC BY-SA 4.0',
      ),
    ],
  };

  /// Attractions for [destinationId], or an empty list when none are added.
  static List<TouristAttraction> forDestination(String destinationId) =>
      _byDestination[destinationId] ?? const [];

  /// Destination IDs that have at least one attraction.
  static Iterable<String> get destinationIds => _byDestination.keys;
}
