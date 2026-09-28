import '../../data/models/category_model.dart';
import '../../data/models/food_model.dart';

/// Jeu de données initial d'aliments et catégories (valeurs pour 100 g).
///
/// Inclut des aliments courants d'Afrique de l'Ouest. Ces données servent de
/// référence hors-ligne et seront remplacées par l'API backend / Firestore.
class FoodSeedData {
  FoodSeedData._();

  static final List<CategoryModel> categories = <CategoryModel>[
    CategoryModel(id: 'cat_cereales', name: 'Céréales & Tubercules', emoji: '🌾'),
    CategoryModel(id: 'cat_proteines', name: 'Protéines', emoji: '🍗'),
    CategoryModel(id: 'cat_fruits', name: 'Fruits', emoji: '🍎'),
    CategoryModel(id: 'cat_legumes', name: 'Légumes', emoji: '🥬'),
    CategoryModel(id: 'cat_produits_laitiers', name: 'Produits laitiers', emoji: '🥛'),
    CategoryModel(id: 'cat_matieres_grasses', name: 'Matières grasses', emoji: '🫒'),
    CategoryModel(id: 'cat_boissons', name: 'Boissons', emoji: '🥤'),
    CategoryModel(id: 'cat_plats', name: 'Plats préparés', emoji: '🍲'),
  ];

  static final List<FoodModel> foods = <FoodModel>[
    // Céréales & tubercules
    _f('food_riz_blanc', 'Riz blanc cuit', 'cat_cereales', '🍚',
        NutritionFacts(calories: 130, proteins: 2.7, carbs: 28, fats: 0.3), 150),
    _f('food_igname', 'Igname cuite', 'cat_cereales', '🍠',
        NutritionFacts(calories: 118, proteins: 1.5, carbs: 27, fats: 0.2), 150),
    _f('food_plantain', 'Banane plantain frite', 'cat_cereales', '🍌',
        NutritionFacts(calories: 333, proteins: 1.5, carbs: 50, fats: 15), 120),
    _f('food_foufou', 'Foufou (igname pilée)', 'cat_cereales', '🥣',
        NutritionFacts(calories: 137, proteins: 1, carbs: 31, fats: 0.6), 200),
    _f('food_gari', 'Gari', 'cat_cereales', '🌾',
        NutritionFacts(calories: 360, proteins: 2, carbs: 85, fats: 0.2), 80),
    _f('food_pain', 'Pain blanc', 'cat_cereales', '🍞',
        NutritionFacts(calories: 265, proteins: 9, carbs: 49, fats: 3.2), 40),
    _f('food_avoine', 'Flocons d\'avoine cuits', 'cat_cereales', '🥣',
        NutritionFacts(calories: 71, proteins: 2.5, carbs: 12, fats: 1.5), 200),

    // Protéines
    _f('food_poulet', 'Poulet cuit (sans peau)', 'cat_proteines', '🍗',
        NutritionFacts(calories: 165, proteins: 31, carbs: 0, fats: 3.6), 120),
    _f('food_poisson', 'Poisson grillé (tilapia)', 'cat_proteines', '🐟',
        NutritionFacts(calories: 128, proteins: 26, carbs: 0, fats: 2.7), 150),
    _f('food_boeuf', 'Bœuf cuit', 'cat_proteines', '🥩',
        NutritionFacts(calories: 250, proteins: 26, carbs: 0, fats: 15), 120),
    _f('food_oeuf', 'Œuf cuit', 'cat_proteines', '🥚',
        NutritionFacts(calories: 155, proteins: 13, carbs: 1.1, fats: 11), 60),
    _f('food_arachide', 'Arachides grillées', 'cat_proteines', '🥜',
        NutritionFacts(calories: 567, proteins: 25, carbs: 16, fats: 49), 30),
    _f('food_niebe', 'Niébé (haricots) cuit', 'cat_proteines', '🫘',
        NutritionFacts(calories: 116, proteins: 8, carbs: 21, fats: 0.5), 150),
    _f('food_tofu', 'Tofu', 'cat_proteines', '⬜',
        NutritionFacts(calories: 76, proteins: 8, carbs: 1.9, fats: 4.8), 100),

    // Fruits
    _f('food_banane', 'Banane douce', 'cat_fruits', '🍌',
        NutritionFacts(calories: 89, proteins: 1.1, carbs: 23, fats: 0.3), 120),
    _f('food_orange', 'Orange', 'cat_fruits', '🍊',
        NutritionFacts(calories: 47, proteins: 0.9, carbs: 12, fats: 0.1), 150),
    _f('food_mangue', 'Mangue', 'cat_fruits', '🥭',
        NutritionFacts(calories: 60, proteins: 0.8, carbs: 15, fats: 0.4), 165),
    _f('food_papaye', 'Papaye', 'cat_fruits', '🫒',
        NutritionFacts(calories: 43, proteins: 0.5, carbs: 11, fats: 0.3), 150),
    _f('food_ananas', 'Ananas', 'cat_fruits', '🍍',
        NutritionFacts(calories: 50, proteins: 0.5, carbs: 13, fats: 0.1), 150),
    _f('food_avocat', 'Avocat', 'cat_fruits', '🥑',
        NutritionFacts(calories: 160, proteins: 2, carbs: 9, fats: 15), 100),

    // Légumes
    _f('food_tomate', 'Tomate', 'cat_legumes', '🍅',
        NutritionFacts(calories: 18, proteins: 0.9, carbs: 3.9, fats: 0.2), 100),
    _f('food_oignon', 'Oignon', 'cat_legumes', '🧅',
        NutritionFacts(calories: 40, proteins: 1.1, carbs: 9, fats: 0.1), 80),
    _f('food_chou', 'Chou vert cuit', 'cat_legumes', '🥬',
        NutritionFacts(calories: 32, proteins: 2.2, carbs: 6, fats: 0.3), 120),
    _f('food_carotte', 'Carotte cuite', 'cat_legumes', '🥕',
        NutritionFacts(calories: 35, proteins: 0.8, carbs: 8, fats: 0.2), 100),
    _f('food_epinard', 'Épinards cuits', 'cat_legumes', '🥬',
        NutritionFacts(calories: 23, proteins: 3, carbs: 3.6, fats: 0.4), 120),
    _f('food_gombo', 'Gombo cuit', 'cat_legumes', '🌿',
        NutritionFacts(calories: 33, proteins: 1.9, carbs: 7, fats: 0.2), 100),

    // Produits laitiers
    _f('food_lait', 'Lait entier', 'cat_produits_laitiers', '🥛',
        NutritionFacts(calories: 61, proteins: 3.2, carbs: 4.8, fats: 3.3), 200),
    _f('food_yaourt', 'Yaourt nature', 'cat_produits_laitiers', '🍦',
        NutritionFacts(calories: 59, proteins: 10, carbs: 3.6, fats: 0.4), 150),
    _f('food_fromage', 'Fromage', 'cat_produits_laitiers', '🧀',
        NutritionFacts(calories: 350, proteins: 24, carbs: 1.3, fats: 28), 40),

    // Matières grasses
    _f('food_huile_palme', 'Huile de palme', 'cat_matieres_grasses', '🫗',
        NutritionFacts(calories: 884, proteins: 0, carbs: 0, fats: 100), 15),
    _f('food_beurre', 'Beurre', 'cat_matieres_grasses', '🧈',
        NutritionFacts(calories: 717, proteins: 0.9, carbs: 0.1, fats: 81), 15),
    _f('food_huile_olive', 'Huile d\'olive', 'cat_matieres_grasses', '🫒',
        NutritionFacts(calories: 884, proteins: 0, carbs: 0, fats: 100), 15),

    // Boissons
    _f('food_jus_orange', 'Jus d\'orange', 'cat_boissons', '🧃',
        NutritionFacts(calories: 45, proteins: 0.7, carbs: 10, fats: 0.2), 250),
    _f('food_bissap', 'Bissap (jus d\'hibiscus) sucré', 'cat_boissons', '🌺',
        NutritionFacts(calories: 44, proteins: 0, carbs: 11, fats: 0), 250),
    _f('food_gnamakoudji', 'Gnamakoudji (jus de gingembre)', 'cat_boissons', '🫚',
        NutritionFacts(calories: 39, proteins: 0.3, carbs: 9, fats: 0), 250),
    _f('food_cafe', 'Café sans sucre', 'cat_boissons', '☕',
        NutritionFacts(calories: 2, proteins: 0.1, carbs: 0, fats: 0), 150),
    _f('food_eau', 'Eau', 'cat_boissons', '💧',
        NutritionFacts(calories: 0, proteins: 0, carbs: 0, fats: 0), 250),

    // Plats préparés
    _f('food_tchep', 'Tchep (riz à la tomate)', 'cat_plats', '🍲',
        NutritionFacts(calories: 175, proteins: 5, carbs: 30, fats: 4), 250),
    _f('food_dg', 'Poulet DG', 'cat_plats', '🍛',
        NutritionFacts(calories: 210, proteins: 15, carbs: 18, fats: 9), 250),
    _f('food_ateke', 'Atrékè / Akoumé', 'cat_plats', '🥣',
        NutritionFacts(calories: 132, proteins: 1, carbs: 30, fats: 0.3), 200),
    _f('food_sauce_gombo', 'Sauce gombo au poisson', 'cat_plats', '🍲',
        NutritionFacts(calories: 95, proteins: 8, carbs: 7, fats: 4), 200),
  ];

  static FoodModel _f(
    String id,
    String name,
    String categoryId,
    String emoji,
    NutritionFacts facts,
    double portion,
  ) {
    return FoodModel(
      id: id,
      name: name,
      categoryId: categoryId,
      emoji: emoji,
      imageUrl: _photoUrls[id],
      per100g: facts,
      defaultPortionG: portion,
    );
  }

  /// Photos réelles et stables (Wikimedia Commons, vignettes ~330 px),
  /// vérifiées une par une via l'API REST de Wikipedia.
  ///
  /// Un aliment absent de cette carte (ou `null`) affiche son emoji de
  /// secours via FoodThumb/AppImage. Généré par backend/scripts/fetch_flutter_photos.js.
  static const Map<String, String?> _photoUrls = <String, String?>{
    'food_riz_blanc':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/20201102.Hengnan.Hybrid_rice_Sanyou-1.6.jpg/330px-20201102.Hengnan.Hybrid_rice_Sanyou-1.6.jpg',
    'food_igname':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Yam_at_monday_market_kaduna_state_01.jpg/330px-Yam_at_monday_market_kaduna_state_01.jpg',
    'food_plantain':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/86/Mega_racimos_de_guineos.jpg/330px-Mega_racimos_de_guineos.jpg',
    'food_foufou':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Wrapped_fufu.jpg/330px-Wrapped_fufu.jpg',
    'food_gari': null,
    'food_pain':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Korb_mit_Br%C3%B6tchen.JPG/330px-Korb_mit_Br%C3%B6tchen.JPG',
    'food_avoine':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Oatmeal.jpg/330px-Oatmeal.jpg',
    'food_poulet':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Chickens_in_market.jpg/330px-Chickens_in_market.jpg',
    'food_poisson':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Oreochromis-niloticus-Nairobi.JPG/330px-Oreochromis-niloticus-Nairobi.JPG',
    'food_boeuf':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Standing-rib-roast.jpg/330px-Standing-rib-roast.jpg',
    'food_oeuf':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/54/Adolphe_Millot_oeufs-fixed.jpg/330px-Adolphe_Millot_oeufs-fixed.jpg',
    'food_arachide':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Arachis_hypogaea_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-163.jpg/330px-Arachis_hypogaea_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-163.jpg',
    'food_niebe':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Lobia.jpg/330px-Lobia.jpg',
    'food_tofu':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/Japanese_SilkyTofu_%28Kinugoshi_Tofu%29.JPG/330px-Japanese_SilkyTofu_%28Kinugoshi_Tofu%29.JPG',
    'food_banane':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Bananavarieties.jpg/330px-Bananavarieties.jpg',
    'food_orange':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Oranges_-_whole-halved-segment.jpg/330px-Oranges_-_whole-halved-segment.jpg',
    'food_mangue':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Mangos_-_single_and_halved.jpg/330px-Mangos_-_single_and_halved.jpg',
    'food_papaye':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Carica_papaya_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-029.jpg/330px-Carica_papaya_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-029.jpg',
    'food_ananas':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/%E0%B4%95%E0%B5%88%E0%B4%A4%E0%B4%9A%E0%B5%8D%E0%B4%9A%E0%B4%95%E0%B5%8D%E0%B4%95.jpg/330px-%E0%B4%95%E0%B5%88%E0%B4%A4%E0%B4%9A%E0%B5%8D%E0%B4%9A%E0%B4%95%E0%B5%8D%E0%B4%95.jpg',
    'food_avocat':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Persea_americana_fruit_2.JPG/330px-Persea_americana_fruit_2.JPG',
    'food_tomate':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tomato_je.jpg/330px-Tomato_je.jpg',
    'food_oignon':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Mixed_onions.jpg/330px-Mixed_onions.jpg',
    'food_chou':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Cabbage_and_cross_section_on_white.jpg/330px-Cabbage_and_cross_section_on_white.jpg',
    'food_carotte':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Vegetable-Carrot-Bundle-wStalks.jpg/330px-Vegetable-Carrot-Bundle-wStalks.jpg',
    'food_epinard':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Spinacia_oleracea_Spinazie_bloeiend.jpg/330px-Spinacia_oleracea_Spinazie_bloeiend.jpg',
    'food_gombo':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Hong_Kong_Okra_Aug_25_2012.JPG/330px-Hong_Kong_Okra_Aug_25_2012.JPG',
    'food_lait':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Glass_of_Milk_%2833657535532%29.jpg/330px-Glass_of_Milk_%2833657535532%29.jpg',
    'food_yaourt':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Joghurt.jpg/330px-Joghurt.jpg',
    'food_fromage':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Cheese_platter.jpg/330px-Cheese_platter.jpg',
    'food_huile_palme':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Palm_oil.jpg/330px-Palm_oil.jpg',
    'food_beurre':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/%C5%A0v%C3%A9dsk%C3%BD_kol%C3%A1%C4%8D_naruby_904_%28cropped%29.JPG/330px-%C5%A0v%C3%A9dsk%C3%BD_kol%C3%A1%C4%8D_naruby_904_%28cropped%29.JPG',
    'food_huile_olive':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Oliven_V1.jpg/330px-Oliven_V1.jpg',
    'food_jus_orange':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Orangejuice.jpg/330px-Orangejuice.jpg',
    'food_bissap':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Roselle%2C_Hibiscus_sabdariffa%2C_2014_01.JPG/330px-Roselle%2C_Hibiscus_sabdariffa%2C_2014_01.JPG',
    'food_gnamakoudji':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Koeh-146-no_text.jpg/330px-Koeh-146-no_text.jpg',
    'food_cafe':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Latte_and_dark_coffee.jpg/330px-Latte_and_dark_coffee.jpg',
    'food_eau': null,
    'food_tchep':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/Jollof_Rice_with_Stew.jpg/330px-Jollof_Rice_with_Stew.jpg',
    'food_dg':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Chicken_mull.jpg/330px-Chicken_mull.jpg',
    'food_ateke':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Manihot_esculenta_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-090.jpg/330px-Manihot_esculenta_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-090.jpg',
    'food_sauce_gombo':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Sayur_oyong.JPG/330px-Sayur_oyong.JPG',
  };
}
