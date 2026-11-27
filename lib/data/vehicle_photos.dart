/// Vehicle photos bundled with the app for the cab, bus, train and flight
/// booking screens.
///
/// These are illustrative photos of a vehicle of the same type. They are not
/// photos of the operator's own vehicle, so every screen that shows one says
/// so. Sources and licences are listed in [VehiclePhotos.credits] and in
/// `assets/vehicles/credits.json`. All photos come from Wikimedia Commons.
class VehiclePhotoCredit {
  final String artist;
  final String licence;
  final String sourceUrl;

  const VehiclePhotoCredit({
    required this.artist,
    required this.licence,
    required this.sourceUrl,
  });

  /// Short credit line, for example "Photo: Ethan Llamas, CC BY-SA 4.0".
  String get line => 'Photo: $artist, $licence';
}

class VehiclePhotos {
  VehiclePhotos._();

  static const cabHatchback = 'assets/vehicles/cab-hatchback.jpg';
  static const cabSedan = 'assets/vehicles/cab-sedan.jpg';
  static const cabSuv = 'assets/vehicles/cab-suv.jpg';
  static const cabPremium = 'assets/vehicles/cab-premium.jpg';
  static const busAcSleeper = 'assets/vehicles/bus-ac-sleeper.jpg';
  static const busVolvoSeater = 'assets/vehicles/bus-volvo-seater.jpg';
  static const busNonAc = 'assets/vehicles/bus-non-ac.jpg';
  static const trainChairCar = 'assets/vehicles/train-chair-car.jpg';
  static const trainAcCoach = 'assets/vehicles/train-ac-coach.jpg';
  static const flight = 'assets/vehicles/flight-wing.jpg';

  static const Map<String, VehiclePhotoCredit> credits = {
    cabHatchback: VehiclePhotoCredit(
      artist: 'RichardSummersault',
      licence: 'CC0',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Suzuki_Karimun_Wagon_R_(Front),_Jakarta,_Indonesia.jpg',
    ),
    cabSedan: VehiclePhotoCredit(
      artist: 'Ethan Llamas',
      licence: 'CC BY-SA 4.0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Suzuki_Dzire_1.2_GL%2B_2024.jpg',
    ),
    cabSuv: VehiclePhotoCredit(
      artist: 'Akashpbrahmavar',
      licence: 'CC0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Maruti_Suzuki_Ertiga(1).jpg',
    ),
    cabPremium: VehiclePhotoCredit(
      artist: 'Premnath Kudva',
      licence: 'CC BY-SA 4.0',
      sourceUrl:
          'https://commons.wikimedia.org/wiki/File:Toyota_Innova_Crysta_2.4_Z_front_right.jpg',
    ),
    busAcSleeper: VehiclePhotoCredit(
      artist: 'KeralianEditor',
      licence: 'CC0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Volvo_9400_B11R_Airavat_Club_Class.jpg',
    ),
    busVolvoSeater: VehiclePhotoCredit(
      artist: 'Karthikprincenellore',
      licence: 'CC BY-SA 4.0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:TSRTC_GARUDA_Plus_VOLVO_B9R.JPG',
    ),
    busNonAc: VehiclePhotoCredit(
      artist: 'Nikhilb239',
      licence: 'CC BY 3.0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:APSRTC_Bus_07122014.jpg',
    ),
    trainChairCar: VehiclePhotoCredit(
      artist: 'Ravi Dwivedi',
      licence: 'CC BY-SA 4.0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Vande_Bharat_Express_train.jpg',
    ),
    trainAcCoach: VehiclePhotoCredit(
      artist: 'Ravi Dwivedi',
      licence: 'CC BY-SA 4.0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Dibrugarh_Rajdhani_Express_in_New_Delhi.jpg',
    ),
    flight: VehiclePhotoCredit(
      artist: 'Daniel Case',
      licence: 'CC BY-SA 4.0',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Airliner_wing_and_clouds_over_South_Pacific.jpg',
    ),
  };

  /// The bundled photo for one search result, or null when the service has
  /// no photo (hotels) or the option is not recognised.
  ///
  /// [category] is the bus type. [details] holds the cab model ("Car") and the
  /// train class ("Class").
  static String? forService({
    required String service,
    String category = '',
    Map<String, String> details = const {},
  }) {
    return switch (service) {
      'Cabs' => _cab(details['Car'] ?? ''),
      'Buses' => _bus(category),
      'Trains' => _train(details['Class'] ?? ''),
      'Flights' => flight,
      _ => null,
    };
  }

  static String? _cab(String car) {
    if (car.startsWith('Hatchback')) return cabHatchback;
    if (car.startsWith('Sedan')) return cabSedan;
    if (car.startsWith('SUV')) return cabSuv;
    if (car.startsWith('Premium')) return cabPremium;
    return null;
  }

  static String? _bus(String type) => switch (type) {
        'AC Sleeper (2+1)' => busAcSleeper,
        'Volvo AC Seater (2+2)' => busVolvoSeater,
        'Non-AC Sleeper' => busNonAc,
        _ => null,
      };

  static String? _train(String travelClass) {
    if (travelClass.isEmpty) return null;
    return travelClass == 'AC Chair Car (CC)' ? trainChairCar : trainAcCoach;
  }
}
