import 'food_model.dart';
import 'meal_item_model.dart';

/// Un repas (petit-déjeuner, déjeuner…) pris un jour donné.
class MealModel {
  final String id;
  final String userId;
  String type; // Voir MealType (app_constants)
  DateTime date;
  final List<MealItemModel> items;

  MealModel({
    required this.id,
    required this.userId,
    required this.type,
    DateTime? date,
    List<MealItemModel>? items,
  })  : date = date ?? DateTime.now(),
        items = items ?? [];

  NutritionFacts get totals => items.fold(
        NutritionFacts.zero,
        (sum, item) => sum + item.totals,
      );

  factory MealModel.fromMap(Map<String, dynamic> map) => MealModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: map['type'] as String? ?? '',
        date: DateTime.tryParse(map['date'] as String? ?? '') ??
            DateTime.now(),
        items: (map['items'] as List?)
                ?.map((e) =>
                    MealItemModel.fromMap((e as Map).cast<String, dynamic>()))
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toMap()).toList(),
      };
}
