import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitatrack/app/constants/app_constants.dart';
import 'package:vitatrack/core/services/local_store.dart';
import 'package:vitatrack/core/utils/nutrition_calculator.dart';
import 'package:vitatrack/data/models/user_model.dart';
import 'package:vitatrack/data/repositories/auth_repository.dart';
import 'package:vitatrack/features/dashboard/user_dashboard/controllers/app_provider.dart';

/// Parcours fonctionnel complet du domaine utilisateur, en mode hors-ligne
/// (Repositories -> LocalStore). Couvre : aliments, journal, poids, objectif,
/// favoris et agrégats du tableau de bord.
///
/// NB : LocalStore et les repositories sont des singletons ; le stockage est
/// initialisé une seule fois. Chaque test travaille sur un utilisateur unique,
/// ce qui isole les données (repas/poids/objectif/favoris sont scopés par id).
void main() {
  int counter = 0;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.instance.init();
  });

  /// Crée un nouveau compte, le lie à un AppProvider flambant neuf et le retourne.
  Future<AppProvider> newBoundProvider() async {
    final tag = 'appuser${counter++}';
    final email = '$tag@vitatrack.app';
    final account = await AuthRepository.instance.register(
      email: email,
      password: 'pass1234',
      fullName: 'App User',
      profile: UserModel(
        id: '',
        email: email,
        fullName: 'App User',
        gender: Gender.male,
        heightCm: 175,
        activityFactor: 1.375,
        goalType: GoalType.maintain,
      ).toMap(),
    );
    final app = AppProvider();
    await app.bindUser(UserModel.fromMap(account.profile));
    return app;
  }

  group('Aliments & catégories', () {
    test('les aliments de référence sont semés et accessibles', () async {
      final app = await newBoundProvider();
      final foods = await app.search('');
      expect(foods, isNotEmpty);
      final first = foods.first;
      expect(app.foodById(first.id)?.id, first.id);
    });

    test('la recherche filtre par mot-clé (insensible à la casse)', () async {
      final app = await newBoundProvider();
      final all = await app.search('');
      final query = all.first.name.substring(0, 3);
      final results = await app.search(query);
      expect(results, isNotEmpty);
      expect(
        results.every((f) => f.name.toLowerCase().contains(query.toLowerCase())),
        isTrue,
      );
    });

    test('les catégories contiennent des aliments', () async {
      final app = await newBoundProvider();
      expect(app.categories, isNotEmpty);
      final cat = app.categories.first;
      expect(app.categoryById(cat.id)?.id, cat.id);
    });
  });

  group('Journal alimentaire', () {
    test('créer un repas et y ajouter un aliment met à jour les totaux du jour', () async {
      final app = await newBoundProvider();
      final food = (await app.search('')).first;
      final meal = await app.createMeal(MealType.breakfast);
      await app.addFoodToMeal(meal.id, food, 100);

      expect(app.todayMeals.any((m) => m.id == meal.id), isTrue);
      // 100 g -> exactement les valeurs per100g de l'aliment
      expect(app.todayTotals.calories, closeTo(food.per100g.calories, 0.001));
    });

    test('modifier la quantité recalcule les totaux', () async {
      final app = await newBoundProvider();
      final food = (await app.search('')).first;
      final meal = await app.createMeal(MealType.lunch);
      await app.addFoodToMeal(meal.id, food, 100);
      final item = app.mealById(meal.id)!.items.first;
      await app.updateItemQuantity(meal.id, item.id, 200);
      expect(app.todayTotals.calories, closeTo(food.per100g.calories * 2, 0.001));
    });

    test('supprimer un aliment retire ses calories', () async {
      final app = await newBoundProvider();
      final food = (await app.search('')).first;
      final meal = await app.createMeal(MealType.dinner);
      await app.addFoodToMeal(meal.id, food, 100);
      final item = app.mealById(meal.id)!.items.first;
      await app.removeItem(meal.id, item.id);
      expect(app.todayTotals.calories, 0);
    });

    test('supprimer un repas le retire du journal', () async {
      final app = await newBoundProvider();
      final food = (await app.search('')).first;
      final meal = await app.createMeal(MealType.snack);
      await app.addFoodToMeal(meal.id, food, 50);
      await app.deleteMeal(meal.id);
      expect(app.todayMeals.any((m) => m.id == meal.id), isFalse);
    });

    test('weeklyCalories retourne 7 points', () async {
      final app = await newBoundProvider();
      final weekly = app.weeklyCalories();
      expect(weekly.length, 7);
    });
  });

  group('Suivi du poids', () {
    test('ajouter un point met à jour poids actuel, historique et IMC', () async {
      final app = await newBoundProvider();
      await app.addWeight(70, date: DateTime.now());
      expect(app.currentWeight, 70);
      expect(app.weightHistory.length, 1);
      expect(app.currentBmi, closeTo(NutritionCalculator.bmi(70, 175), 0.001));
    });

    test('supprimer un point le retire de l\'historique', () async {
      final app = await newBoundProvider();
      await app.addWeight(72, date: DateTime.now());
      final id = app.weightHistory.first.id;
      await app.deleteWeight(id);
      expect(app.weightHistory.any((w) => w.id == id), isFalse);
    });
  });

  group('Objectif nutritionnel', () {
    test('saveGoal active un objectif et reflète les calories cibles', () async {
      final app = await newBoundProvider();
      await app.saveGoal(GoalType.loss, 1800);
      expect(app.goal, isNotNull);
      expect(app.goal!.calorieTarget, 1800);
      expect(app.goal!.type, GoalType.loss);
      expect(app.user?.calorieGoal, 1800);
    });

    test('un nouvel objectif remplace le précédent comme actif', () async {
      final app = await newBoundProvider();
      await app.saveGoal(GoalType.loss, 1800);
      await app.saveGoal(GoalType.gain, 2600);
      expect(app.goal?.calorieTarget, 2600);
    });

    test('recommendedCalories renvoie une valeur positive', () async {
      final app = await newBoundProvider();
      expect(app.recommendedCalories(), greaterThan(0));
    });
  });

  group('Favoris', () {
    test('toggleFavorite ajoute puis retire un aliment favori', () async {
      final app = await newBoundProvider();
      final food = (await app.search('')).first;
      await app.toggleFavorite(food.id);
      expect(app.isFavorite(food.id), isTrue);
      expect(app.favorites.map((f) => f.id), contains(food.id));

      await app.toggleFavorite(food.id);
      expect(app.isFavorite(food.id), isFalse);
    });
  });

  group('Comportement sans utilisateur', () {
    test('bindUser(null) réinitialise le provider', () async {
      final app = await newBoundProvider();
      await app.bindUser(null);
      expect(app.user, isNull);
      expect(app.ready, isFalse);
      expect(app.todayTotals.calories, 0);
    });
  });
}
