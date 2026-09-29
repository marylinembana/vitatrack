import 'package:flutter_test/flutter_test.dart';
import 'package:vitatrack/core/utils/nutrition_calculator.dart';
import 'package:vitatrack/data/models/food_model.dart';
import 'package:vitatrack/data/models/meal_item_model.dart';
import 'package:vitatrack/data/models/meal_model.dart';
import 'package:vitatrack/data/models/nutrition_goal_model.dart';
import 'package:vitatrack/data/models/user_model.dart';
import 'package:vitatrack/data/models/weight_record_model.dart';

void main() {
  group('NutritionFacts', () {
    test('forQuantity transpose les valeurs par 100 g', () {
      const f = NutritionFacts(calories: 100, proteins: 10, carbs: 20, fats: 5);
      final half = f.forQuantity(50);
      expect(half.calories, 50);
      expect(half.proteins, 5);
      final double_ = f.forQuantity(200);
      expect(double_.calories, 200);
      expect(double_.carbs, 40);
    });

    test('additionne deux profils nutritionnels', () {
      const a = NutritionFacts(calories: 100, proteins: 5, carbs: 10, fats: 2);
      const b = NutritionFacts(calories: 50, proteins: 3, carbs: 4, fats: 1);
      final sum = a + b;
      expect(sum.calories, 150);
      expect(sum.proteins, 8);
      expect(sum.fats, 3);
    });

    test('round-trip toMap/fromMap', () {
      const f = NutritionFacts(
          calories: 250, proteins: 12, carbs: 30, fats: 8, fibers: 3);
      final back = NutritionFacts.fromMap(f.toMap());
      expect(back.calories, 250);
      expect(back.fibers, 3);
    });
  });

  group('FoodModel', () {
    test('round-trip conserve les champs', () {
      final food = FoodModel(
        id: 'food_1',
        name: 'Banane plantain',
        categoryId: 'cat_fruits',
        emoji: '🍌',
        defaultPortionG: 120,
        per100g:
            const NutritionFacts(calories: 120, proteins: 1.2, carbs: 31, fats: 0.4),
      );
      final back = FoodModel.fromMap(food.toMap());
      expect(back.id, 'food_1');
      expect(back.name, 'Banane plantain');
      expect(back.categoryId, 'cat_fruits');
      expect(back.defaultPortionG, 120);
      expect(back.per100g.calories, 120);
      expect(back.isActive, isTrue);
    });
  });

  group('MealItemModel', () {
    test('fromFood reprend la portion par défaut et calcule les totaux', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Riz',
        categoryId: 'c',
        defaultPortionG: 150,
        per100g: const NutritionFacts(
            calories: 130, proteins: 2.7, carbs: 28, fats: 0.3),
      );
      final item = MealItemModel.fromFood(food);
      expect(item.foodId, 'f1');
      expect(item.quantityG, 150);
      // 130 * 1.5 = 195 kcal
      expect(item.totals.calories, closeTo(195, 0.001));
    });

    test('round-trip toMap/fromMap', () {
      final item = MealItemModel(
        id: 'i1',
        foodId: 'f1',
        foodName: 'Riz',
        quantityG: 80,
        per100g: const NutritionFacts(calories: 130, proteins: 3, carbs: 28, fats: 0),
      );
      final back = MealItemModel.fromMap(item.toMap());
      expect(back.id, 'i1');
      expect(back.quantityG, 80);
      expect(back.totals.calories, closeTo(104, 0.001));
    });
  });

  group('MealModel', () {
    test('les totaux agrégent tous les items', () {
      final meal = MealModel(id: 'm1', userId: 'u1', type: 'Déjeuner');
      meal.items.addAll([
        MealItemModel(
            id: 'a', foodId: 'f', foodName: 'x', quantityG: 100,
            per100g: const NutritionFacts(calories: 100, proteins: 5, carbs: 10, fats: 2)),
        MealItemModel(
            id: 'b', foodId: 'f', foodName: 'y', quantityG: 100,
            per100g: const NutritionFacts(calories: 200, proteins: 10, carbs: 20, fats: 4)),
      ]);
      expect(meal.totals.calories, 300);
      expect(meal.totals.proteins, 15);
    });

    test('round-trip toMap/fromMap conserve les items', () {
      final meal = MealModel(
        id: 'm2',
        userId: 'u1',
        type: 'Dîner',
        date: DateTime(2026, 9, 28, 20),
        items: [
          MealItemModel(
              id: 'a', foodId: 'f', foodName: 'x', quantityG: 100,
              per100g: const NutritionFacts(calories: 100, proteins: 5, carbs: 10, fats: 2)),
        ],
      );
      final back = MealModel.fromMap(meal.toMap());
      expect(back.id, 'm2');
      expect(back.type, 'Dîner');
      expect(back.items.length, 1);
      expect(back.date, DateTime(2026, 9, 28, 20));
      expect(back.totals.calories, 100);
    });
  });

  group('UserModel', () {
    test('round-trip toMap/fromMap', () {
      final user = UserModel(
        id: 'u1',
        email: 'user@vitatrack.app',
        fullName: 'Afiwa Mbarga',
        gender: Gender.female,
        birthDate: DateTime(1998, 5, 12),
        heightCm: 165,
        activityFactor: 1.375,
        goalType: GoalType.loss,
        targetWeightKg: 62,
        calorieGoal: 1650,
        isOnboarded: true,
        favoriteFoodIds: ['food_001', 'food_015'],
      );
      final back = UserModel.fromMap(user.toMap());
      expect(back.id, 'u1');
      expect(back.email, 'user@vitatrack.app');
      expect(back.gender, Gender.female);
      expect(back.goalType, GoalType.loss);
      expect(back.calorieGoal, 1650);
      expect(back.isOnboarded, isTrue);
      expect(back.favoriteFoodIds, ['food_001', 'food_015']);
    });

    test('l\'âge se déduit de la date de naissance', () {
      final now = DateTime.now();
      final user = UserModel(
        id: 'u',
        email: 'e@e.com',
        fullName: 'x',
        birthDate: DateTime(now.year - 30, now.month, now.day),
      );
      expect(user.age, 30);
    });

    test('valeurs par défaut si le map est incomplet', () {
      final user = UserModel.fromMap({'id': 'x', 'email': 'e@e.com'});
      // fromKey mappe toute valeur absente/inconnue vers `female`.
      expect(user.gender, Gender.female);
      expect(user.heightCm, 170);
      expect(user.activityFactor, 1.375);
      expect(user.goalType, GoalType.maintain);
    });
  });

  group('WeightRecordModel', () {
    test('round-trip toMap/fromMap', () {
      final w = WeightRecordModel(
          id: 'w1', userId: 'u1', weightKg: 68.5, date: DateTime(2026, 9, 1), note: 'matin');
      final back = WeightRecordModel.fromMap(w.toMap());
      expect(back.weightKg, 68.5);
      expect(back.note, 'matin');
      expect(back.date, DateTime(2026, 9, 1));
    });
  });

  group('NutritionGoalModel', () {
    test('round-trip toMap/fromMap', () {
      final g = NutritionGoalModel(
        id: 'g1',
        userId: 'u1',
        type: GoalType.gain,
        calorieTarget: 2600,
        proteinTargetG: 160,
        carbTargetG: 280,
        fatTargetG: 70,
      );
      final back = NutritionGoalModel.fromMap(g.toMap());
      expect(back.type, GoalType.gain);
      expect(back.calorieTarget, 2600);
      expect(back.isActive, isTrue);
    });
  });
}
