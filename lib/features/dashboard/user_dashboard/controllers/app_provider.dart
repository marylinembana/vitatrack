import 'package:flutter/foundation.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/food_model.dart';
import '../../../../data/models/meal_item_model.dart';
import '../../../../data/models/meal_model.dart';
import '../../../../data/models/nutrition_goal_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/weight_record_model.dart';
import '../../../../data/repositories/food_repository.dart';
import '../../../../data/repositories/goal_repository.dart';
import '../../../../data/repositories/meal_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/repositories/weight_repository.dart';

/// Provider principal du domaine utilisateur : aliments, journal, poids,
/// objectif. Les écrans passeront par ici ; les rôles nutritionniste et admin
/// utilisent directement les repositories.
class AppProvider extends ChangeNotifier {
  AppProvider();

  final FoodRepository _foods = FoodRepository.instance;
  final MealRepository _meals = MealRepository.instance;
  final WeightRepository _weights = WeightRepository.instance;
  final GoalRepository _goals = GoalRepository.instance;
  final UserRepository _users = UserRepository.instance;

  String? _userId;
  UserModel? _user;

  List<FoodModel> _allFoods = [];
  List<CategoryModel> _categories = [];
  List<MealModel> _todayMeals = [];
  NutritionGoalModel? _goal;
  List<WeightRecordModel> _weightHistory = [];
  bool _ready = false;

  bool get ready => _ready;
  UserModel? get user => _user;
  List<CategoryModel> get categories => _categories;
  List<MealModel> get todayMeals => _todayMeals;
  NutritionGoalModel? get goal => _goal;
  List<WeightRecordModel> get weightHistory => _weightHistory;

  String get _uid => _userId ?? '';

  /// Charge le contexte utilisateur (après connexion / changement de session).
  Future<void> bindUser(UserModel? user) async {
    _user = user;
    _userId = user?.id;
    if (user == null) {
      _ready = false;
      notifyListeners();
      return;
    }
    await _loadStatic();
    await refresh();
  }

  Future<void> _loadStatic() async {
    _allFoods = await _foods.all();
    _categories = await _foods.categories();
  }

  /// Recharge les données dépendantes de l'utilisateur.
  Future<void> refresh() async {
    if (_userId == null) return;
    _todayMeals = _meals.forDay(_uid, DateTime.now());
    _goal = _goals.active(_uid);
    _weightHistory = _weights.history(_uid);
    _ready = true;
    notifyListeners();
  }

  /// Relit le cache local (statique + personnel) après un rafraîchissement
  /// réseau en arrière-plan. Les lectures sont synchrones : quasi instantané.
  Future<void> reload() async {
    if (_userId == null) return;
    await _loadStatic();
    await refresh();
  }

  // ---------- Aliments ----------

  List<CategoryModel> categoriesWithCounts() => _categories;

  CategoryModel? categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<FoodModel> foodsInCategory(String categoryId) =>
      _allFoods.where((f) => f.categoryId == categoryId).toList();

  Future<List<FoodModel>> search(String query, {String? categoryId}) =>
      _foods.search(query, categoryId: categoryId);

  FoodModel? foodById(String id) {
    for (final f in _allFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<FoodModel> get favorites {
    final ids = _user?.favoriteFoodIds ?? [];
    return _allFoods.where((f) => ids.contains(f.id)).toList();
  }

  bool isFavorite(String foodId) =>
      _user?.favoriteFoodIds.contains(foodId) ?? false;

  Future<void> toggleFavorite(String foodId) async {
    if (_user == null) return;
    await _users.toggleFavorite(_uid, foodId);
    _user = _users.byId(_uid);
    notifyListeners();
  }

  // ---------- Journal / repas ----------

  NutritionFacts get todayTotals => _meals.totalsForDay(_uid, DateTime.now());

  List<MealModel> mealsForDay(DateTime day) => _meals.forDay(_uid, day);

  /// Total calories par jour sur les 7 derniers jours (pour graphique).
  List<({DateTime day, double calories})> weeklyCalories() {
    return DateUtils.last7Days().map((day) {
      final t = _meals.totalsForDay(_uid, day);
      return (day: day, calories: t.calories);
    }).toList();
  }

  Future<MealModel> createMeal(String type, {DateTime? date}) async {
    final meal = await _meals.addMeal(
        userId: _uid, type: type, date: date);
    await refresh();
    return meal;
  }

  Future<void> addFoodToMeal(
      String mealId, FoodModel food, double quantityG) async {
    await _meals.addItem(
        mealId, MealItemModel.fromFood(food, quantityG: quantityG));
    await refresh();
  }

  Future<void> updateItemQuantity(
      String mealId, String itemId, double quantityG) async {
    await _meals.updateItemQuantity(mealId, itemId, quantityG);
    await refresh();
  }

  Future<void> removeItem(String mealId, String itemId) async {
    await _meals.removeItem(mealId, itemId);
    await refresh();
  }

  Future<void> deleteMeal(String mealId) async {
    await _meals.deleteMeal(mealId);
    await refresh();
  }

  MealModel? mealById(String mealId) => _meals.byId(mealId);

  // ---------- Objectif ----------

  /// Calcule l'objectif calorique recommandé selon le profil.
  double recommendedCalories() {
    final u = _user;
    if (u == null) return AppConstants.defaultCalorieGoalMaintain;
    final lastWeight =
        _weightHistory.isEmpty ? u.targetWeightKg : _weightHistory.first.weightKg;
    final bmr = NutritionCalculator.bmr(
      weightKg: lastWeight,
      heightCm: u.heightCm,
      age: u.age,
      isMale: u.isMale,
    );
    final tdee =
        NutritionCalculator.tdee(bmrValue: bmr, activityFactor: u.activityFactor);
    return NutritionCalculator.calorieGoal(tdeeValue: tdee, goal: u.goalType);
  }

  Future<void> saveGoal(GoalType type, double calories) async {
    if (_user == null) return;
    _user!.goalType = type;
    _user!.calorieGoal = calories;
    await _users.saveUser(_user!);
    _goal = await _goals.upsert(userId: _uid, type: type, calorieTarget: calories);
    notifyListeners();
  }

  // ---------- Poids ----------

  double get currentWeight =>
      _weightHistory.isEmpty ? (_user?.targetWeightKg ?? 70) : _weightHistory.first.weightKg;

  double get currentBmi => NutritionCalculator.bmi(currentWeight, _user?.heightCm ?? 170);

  Future<void> addWeight(double kg, {DateTime? date, String? note}) async {
    await _weights.add(userId: _uid, weightKg: kg, date: date, note: note);
    _weightHistory = _weights.history(_uid);
    notifyListeners();
  }

  Future<void> deleteWeight(String id) async {
    await _weights.delete(id);
    _weightHistory = _weights.history(_uid);
    notifyListeners();
  }
}
