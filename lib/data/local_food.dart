import 'food_catalogue_more.dart';

/// A dish from a destination's local cuisine, shown in the Food Explorer.
///
/// These are general descriptions of well-known dishes. They are not
/// restaurant listings, so no opening hours, availability or prices are given.
class LocalDish {
  final String name;

  /// Kind of dish, for example "Street food" or "Main meal".
  final String category;

  /// True when the dish is normally vegetarian (no meat, fish or eggs).
  final bool vegetarian;
  final String description;

  /// Asset path of the dish photo, for example assets/food/dhokla.jpg.
  /// Null when no verified photo is bundled yet; the app then shows a labelled
  /// placeholder.
  final String? image;

  /// Who took the photo and under which licence. Null when [image] is null.
  final FoodPhotoCredit? credit;

  const LocalDish({
    required this.name,
    required this.category,
    required this.vegetarian,
    required this.description,
    this.image,
    this.credit,
  });

  /// True when a verified photo and its credit are bundled with the dish.
  bool get hasPhoto => image != null && credit != null;
}

/// Photo credit, shown under each dish photo as the licence requires.
class FoodPhotoCredit {
  final String author;
  final String licence;

  /// Wikimedia Commons page for the photo.
  final String source;

  const FoodPhotoCredit({
    required this.author,
    required this.licence,
    required this.source,
  });
}

/// Curated local dishes per destination, keyed by destination ID.
class FoodCatalog {
  FoodCatalog._();

  static const Map<String, List<LocalDish>> _byDestination = {
    'ahmedabad': [
      LocalDish(
        name: 'Gujarati thali',
        category: 'Main meal',
        vegetarian: true,
        description: 'A plate of small vegetarian dishes with dal, rice, rotli and sweets, often served with refills.',
        image: 'assets/food/gujarati-thali.jpg',
        credit: FoodPhotoCredit(
          author: 'Amol Sinha',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Gujarati_Thali_1.jpg',
        ),
      ),
      LocalDish(
        name: 'Dhokla',
        category: 'Snack',
        vegetarian: true,
        description: 'Soft, steamed savoury cake made from fermented gram flour, served with green chutney.',
        image: 'assets/food/dhokla.jpg',
        credit: FoodPhotoCredit(
          author: 'Sumit Surai',
          licence: 'CC BY-SA 3.0',
          source: 'https://commons.wikimedia.org/wiki/File:Food-Dhokla.jpg',
        ),
      ),
      LocalDish(
        name: 'Fafda-jalebi',
        category: 'Breakfast',
        vegetarian: true,
        description: 'Crisp gram-flour strips eaten with warm, syrupy jalebi. A popular breakfast in Ahmedabad.',
        image: 'assets/food/fafda-jalebi.jpg',
        credit: FoodPhotoCredit(
          author: 'Sarika 1410',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Jalebi_Fafda.jpg',
        ),
      ),
      LocalDish(
        name: 'Khandvi',
        category: 'Snack',
        vegetarian: true,
        description: 'Thin, rolled gram-flour sheets seasoned with mustard seeds and coconut.',
        image: 'assets/food/khandvi.jpg',
        credit: FoodPhotoCredit(
          author: 'Shubhamj29',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Khandvi_with_Pudina_Chutney.JPG',
        ),
      ),
      LocalDish(
        name: 'Undhiyu',
        category: 'Main meal',
        vegetarian: true,
        description: 'A mixed vegetable dish slow-cooked in an earthen pot, traditionally eaten in winter.',
        image: 'assets/food/undhiyu.jpg',
        credit: FoodPhotoCredit(
          author: 'Jatan1992',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Undhiyu.jpg',
        ),
      ),
    ],
    'goa': [
      LocalDish(
        name: 'Goan fish curry',
        category: 'Main meal',
        vegetarian: false,
        description: 'Fish in a tangy coconut curry with kokum or tamarind, served with rice.',
        image: 'assets/food/goan-fish-curry.jpg',
        credit: FoodPhotoCredit(
          author: 'Fredericknoronha',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Goan_typical_meal_--_fish,_curry_and_rice.jpg',
        ),
      ),
      LocalDish(
        name: 'Prawn balchão',
        category: 'Main meal',
        vegetarian: false,
        description: 'Prawns cooked in a spicy, tangy vinegar and chilli masala.',
        image: 'assets/food/prawn-balchao.jpg',
        credit: FoodPhotoCredit(
          author: 'notpresleybutelvis',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Prawns_Balchao.jpg',
        ),
      ),
      LocalDish(
        name: 'Pork vindaloo',
        category: 'Main meal',
        vegetarian: false,
        description: 'A fiery, tangy curry with Portuguese roots, traditionally made with pork.',
        image: 'assets/food/pork-vindaloo.jpg',
        credit: FoodPhotoCredit(
          author: 'Indu72',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Pork_Vindaloo.jpg',
        ),
      ),
      LocalDish(
        name: 'Vegetable xacuti',
        category: 'Main meal',
        vegetarian: true,
        description: 'A coconut-based vegetable curry with roasted spices. A vegetarian take on the Goan xacuti.',
        image: 'assets/food/vegetable-xacuti.jpg',
        credit: FoodPhotoCredit(
          author: 'Kugelblintz',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Xacuti-2.jpg',
        ),
      ),
      LocalDish(
        name: 'Bebinca',
        category: 'Dessert',
        vegetarian: false,
        description: 'A rich layered dessert made with coconut milk and sugar. Traditional versions contain eggs.',
        image: 'assets/food/bebinca.jpg',
        credit: FoodPhotoCredit(
          author: 'Elingunnur',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Bebinca_com_9_folhas.JPG',
        ),
      ),
    ],
    'mumbai': [
      LocalDish(
        name: 'Vada pav',
        category: 'Street food',
        vegetarian: true,
        description: 'A spiced potato fritter in a soft bread roll with chutneys. Mumbai\'s everyday street snack.',
        image: 'assets/food/vada-pav.jpg',
        credit: FoodPhotoCredit(
          author: 'Jpatokal',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Aran_Vada_Pav_Mumbai.jpg',
        ),
      ),
      LocalDish(
        name: 'Pav bhaji',
        category: 'Street food',
        vegetarian: true,
        description: 'Spiced mashed vegetables served with buttered bread rolls.',
        image: 'assets/food/pav-bhaji.jpg',
        credit: FoodPhotoCredit(
          author: 'Dforest',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Pav_bhaji.jpg',
        ),
      ),
      LocalDish(
        name: 'Bhel puri',
        category: 'Snack',
        vegetarian: true,
        description: 'Puffed rice with onion, tomato, chutneys and sev, a favourite by the sea.',
        image: 'assets/food/bhel-puri.jpg',
        credit: FoodPhotoCredit(
          author: 'Rakesh Krishna Kumar',
          licence: 'CC BY-SA 2.0',
          source: 'https://commons.wikimedia.org/wiki/File:Bhel_Puri_at_Juhu_Beach.jpg',
        ),
      ),
      LocalDish(
        name: 'Bombil fry',
        category: 'Main meal',
        vegetarian: false,
        description: 'Bombay duck (a fish) coated in spices and shallow-fried. A coastal Mumbai staple.',
        image: 'assets/food/bombil-fry.jpg',
        credit: FoodPhotoCredit(
          author: 'Saakshi Salgaonker',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Fried_Bombil.jpg',
        ),
      ),
      LocalDish(
        name: 'Kulfi falooda',
        category: 'Dessert',
        vegetarian: true,
        description: 'Dense frozen milk dessert served with vermicelli and rose syrup.',
        image: 'assets/food/kulfi-falooda.jpg',
        credit: FoodPhotoCredit(
          author: 'Aashita Kawatra',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Falooda_kulfi_from_India.jpg',
        ),
      ),
    ],
    'jaipur': [
      LocalDish(
        name: 'Dal baati churma',
        category: 'Main meal',
        vegetarian: true,
        description: 'Baked wheat dumplings with lentil dal, plus a sweet, crumbled churma.',
        image: 'assets/food/dal-baati-churma.jpg',
        credit: FoodPhotoCredit(
          author: 'Rishabhbenganijain',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Dal-Batti-Churma.jpg',
        ),
      ),
      LocalDish(
        name: 'Ghewar',
        category: 'Dessert',
        vegetarian: true,
        description: 'A disc-shaped, honeycomb-textured sweet soaked in sugar syrup. A Rajasthani speciality.',
        image: 'assets/food/ghewar.jpg',
        credit: FoodPhotoCredit(
          author: 'Pradeep717',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Ghevar_with_Malai_Topping.jpg',
        ),
      ),
      LocalDish(
        name: 'Pyaaz kachori',
        category: 'Snack',
        vegetarian: true,
        description: 'Flaky pastry filled with spiced onion, often eaten with chutney.',
        image: 'assets/food/pyaaz-kachori.jpg',
        credit: FoodPhotoCredit(
          author: 'Harshitdenovo',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Pyaaz_ki_Kachori.jpg',
        ),
      ),
      LocalDish(
        name: 'Gatte ki sabzi',
        category: 'Main meal',
        vegetarian: true,
        description: 'Gram-flour dumplings cooked in a spiced yogurt-based gravy.',
        image: 'assets/food/gatte-ki-sabzi.jpg',
        credit: FoodPhotoCredit(
          author: 'Kanikatwl',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Gatte_ki_sabzi_served_with_aamras_and_garlic_chutney.jpg',
        ),
      ),
      LocalDish(
        name: 'Laal maas',
        category: 'Main meal',
        vegetarian: false,
        description: 'A fiery mutton curry made with red chillies, traditionally served with bajra roti.',
        image: 'assets/food/laal-maas.jpg',
        credit: FoodPhotoCredit(
          author: 'Aakash Singh Chauhan',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Lal_Maas.jpg',
        ),
      ),
    ],
    'delhi': [
      LocalDish(
        name: 'Chole bhature',
        category: 'Breakfast',
        vegetarian: true,
        description: 'Spiced chickpea curry served with deep-fried leavened bread.',
        image: 'assets/food/chole-bhature.jpg',
        credit: FoodPhotoCredit(
          author: 'Gaurav Dhwaj Khadka',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Chole_Bhature_1.jpg',
        ),
      ),
      LocalDish(
        name: 'Stuffed parathas',
        category: 'Breakfast',
        vegetarian: true,
        description: 'Flatbreads stuffed with spiced fillings, served with curd and pickle in Old Delhi\'s famous lanes.',
        image: 'assets/food/stuffed-parathas.jpg',
        credit: FoodPhotoCredit(
          author: 'Agasthya.rana',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Aloo_Paratha_with_Sabzi.jpg',
        ),
      ),
      LocalDish(
        name: 'Chaat',
        category: 'Street food',
        vegetarian: true,
        description: 'Tangy, spicy snacks such as papdi chaat and aloo tikki.',
        image: 'assets/food/chaat.jpg',
        credit: FoodPhotoCredit(
          author: 'erin from Evanston',
          licence: 'CC BY 2.0',
          source: 'https://commons.wikimedia.org/wiki/File:Delhi_Chaat_with_saunth_chutney.jpg',
        ),
      ),
      LocalDish(
        name: 'Nihari',
        category: 'Main meal',
        vegetarian: false,
        description: 'A slow-cooked meat stew, traditionally eaten in the morning in Old Delhi.',
        image: 'assets/food/nihari.jpg',
        credit: FoodPhotoCredit(
          author: 'Ferdous',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Nihari_and_roti.jpg',
        ),
      ),
      LocalDish(
        name: 'Seekh kebab',
        category: 'Street food',
        vegetarian: false,
        description: 'Minced meat grilled on skewers, popular in Old Delhi\'s kebab shops.',
        image: 'assets/food/seekh-kebab.jpg',
        credit: FoodPhotoCredit(
          author: 'Ishitadsa',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Indian_Chicken_Seekh_Kebab.jpg',
        ),
      ),
    ],
    'manali': [
      LocalDish(
        name: 'Siddu',
        category: 'Breakfast',
        vegetarian: true,
        description: 'Steamed wheat bread stuffed with poppy seeds or walnuts, served with ghee.',
        image: 'assets/food/siddu.jpg',
        credit: FoodPhotoCredit(
          author: 'Jagriti Zinta',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Siddu_and_ghee.jpg',
        ),
      ),
      LocalDish(
        name: 'Madra',
        category: 'Main meal',
        vegetarian: true,
        description: 'Chickpeas simmered in a yogurt-based gravy. A traditional Himachali dish.',
        image: 'assets/food/madra.jpg',
        credit: FoodPhotoCredit(
          author: 'Niyati Sharma 1505',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:White_Chana_Madra.jpg',
        ),
      ),
      LocalDish(
        name: 'Dham',
        category: 'Festive meal',
        vegetarian: true,
        description: 'A traditional festive meal from Himachal Pradesh, usually vegetarian: dal, rice, a sweet and several vegetable dishes.',
        image: 'assets/food/dham.jpg',
        credit: FoodPhotoCredit(
          author: 'Ravi Daj',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Himachal_Pradesh_cusine_-_Dham.jpg',
        ),
      ),
      LocalDish(
        name: 'Veg momos',
        category: 'Snack',
        vegetarian: true,
        description: 'Steamed dumplings with a vegetable filling, popular at food stalls in Manali.',
        image: 'assets/food/veg-momos.jpg',
        credit: FoodPhotoCredit(
          author: 'Gannu03',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Veg_Momos_5.jpg',
        ),
      ),
      LocalDish(
        name: 'River trout',
        category: 'Main meal',
        vegetarian: false,
        description: 'Trout from the mountain rivers, often grilled or fried. Found on many Manali menus.',
        image: 'assets/food/river-trout.jpg',
        credit: FoodPhotoCredit(
          author: 'Kaynatkazi',
          licence: 'CC BY-SA 4.0',
          source: 'https://commons.wikimedia.org/wiki/File:Indian_style_pan_fried_Trout_Fish_masala_from_Himalayas.jpg',
        ),
      ),
    ],
  };

  /// Dishes for [destinationId], or an empty list when none are added.
  static List<LocalDish> forDestination(String destinationId) => [
        ...?_byDestination[destinationId],
        ...?moreFoodByDestination[destinationId],
      ];

  /// True when the destination has a food guide.
  static bool hasFood(String destinationId) =>
      _byDestination.containsKey(destinationId) ||
      moreFoodByDestination.containsKey(destinationId);

  /// Destination IDs that have a food guide.
  static List<String> get destinationIds => {
        ..._byDestination.keys,
        ...moreFoodByDestination.keys,
      }.toList();

  /// Every dish in the catalogue.
  static List<LocalDish> get all =>
      destinationIds.expand(forDestination).toList();
}
