/// Valeurs nutritionnelles pour 100 g d'un aliment.
class NutritionFacts {
  final double calories; // kcal
  final double proteins; // g
  final double carbs; // g
  final double fats; // g
  final double fibers; // g

  const NutritionFacts({
    required this.calories,
    required this.proteins,
    required this.carbs,
    required this.fats,
    this.fibers = 0,
  });

  factory NutritionFacts.fromMap(Map<String, dynamic>? map) => NutritionFacts(
        calories: (map?['calories'] as num?)?.toDouble() ?? 0,
        proteins: (map?['proteins'] as num?)?.toDouble() ?? 0,
        carbs: (map?['carbs'] as num?)?.toDouble() ?? 0,
        fats: (map?['fats'] as num?)?.toDouble() ?? 0,
        fibers: (map?['fibers'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'proteins': proteins,
        'carbs': carbs,
        'fats': fats,
        'fibers': fibers,
      };

  /// Transpose ces valeurs (par 100 g) pour une quantité donnée.
  NutritionFacts forQuantity(double grams) {
    final f = grams / 100;
    return NutritionFacts(
      calories: calories * f,
      proteins: proteins * f,
      carbs: carbs * f,
      fats: fats * f,
      fibers: fibers * f,
    );
  }

  NutritionFacts operator +(NutritionFacts other) => NutritionFacts(
        calories: calories + other.calories,
        proteins: proteins + other.proteins,
        carbs: carbs + other.carbs,
        fats: fats + other.fats,
        fibers: fibers + other.fibers,
      );

  static const NutritionFacts zero =
      NutritionFacts(calories: 0, proteins: 0, carbs: 0, fats: 0);
}

/// Modèle aliment.
class FoodModel {
  final String id;
  String name;
  String categoryId;
  String? emoji; // illustration simple dans l'attente d'images
  String? imageUrl; // photo réelle (URL publique / Firebase Storage)
  String? brand;
  double defaultPortionG;
  NutritionFacts per100g;
  bool isActive;

  FoodModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.emoji,
    this.imageUrl,
    this.brand,
    this.defaultPortionG = 100,
    required this.per100g,
    this.isActive = true,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map) => FoodModel(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        categoryId: map['categoryId'] as String? ?? '',
        emoji: map['emoji'] as String?,
        imageUrl: map['imageUrl'] as String?,
        brand: map['brand'] as String?,
        defaultPortionG:
            (map['defaultPortionG'] as num?)?.toDouble() ?? 100,
        per100g: NutritionFacts.fromMap(
            (map['per100g'] as Map?)?.cast<String, dynamic>()),
        isActive: map['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'emoji': emoji,
        'imageUrl': imageUrl,
        'brand': brand,
        'defaultPortionG': defaultPortionG,
        'per100g': per100g.toMap(),
        'isActive': isActive,
      };
}
