import 'food_model.dart';

/// Un aliment consommé dans un repas, avec sa quantité.
class MealItemModel {
  final String id;
  final String foodId;
  String foodName;
  double quantityG;
  NutritionFacts per100g;

  MealItemModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    this.quantityG = 100,
    required this.per100g,
  });

  NutritionFacts get totals => per100g.forQuantity(quantityG);

  factory MealItemModel.fromFood(FoodModel food, {double? quantityG}) =>
      MealItemModel(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}_${food.id}',
        foodId: food.id,
        foodName: food.name,
        quantityG: quantityG ?? food.defaultPortionG,
        per100g: food.per100g,
      );

  factory MealItemModel.fromMap(Map<String, dynamic> map) => MealItemModel(
        id: map['id'] as String,
        foodId: map['foodId'] as String,
        foodName: map['foodName'] as String? ?? '',
        quantityG: (map['quantityG'] as num?)?.toDouble() ?? 100,
        per100g: NutritionFacts.fromMap(
            (map['per100g'] as Map?)?.cast<String, dynamic>()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'foodId': foodId,
        'foodName': foodName,
        'quantityG': quantityG,
        'per100g': per100g.toMap(),
      };
}
