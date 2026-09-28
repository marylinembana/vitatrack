import '../../core/services/local_store.dart';
import '../../core/utils/date_utils.dart';
import '../models/food_model.dart';
import '../models/meal_item_model.dart';
import '../models/meal_model.dart';

/// Repository des repas (journal alimentaire).
class MealRepository {
  MealRepository._();
  static final MealRepository instance = MealRepository._();

  final LocalStore _store = LocalStore.instance;

  int _seq = 0;
  String get _newId =>
      'meal_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  List<MealModel> _load() =>
      _store.readList(StoreKeys.meals).map(MealModel.fromMap).toList();

  Future<void> _save(List<MealModel> meals) => _store.writeList(
        StoreKeys.meals,
        meals.map((m) => m.toMap()).toList(),
      );

  /// Tous les repas d'un utilisateur pour un jour donné.
  List<MealModel> forDay(String userId, DateTime day) {
    return _load()
        .where((m) =>
            m.userId == userId && DateUtils.isSameDay(m.date, day))
        .toList();
  }

  /// Total nutritionnel pour un jour donné.
  NutritionFacts totalsForDay(String userId, DateTime day) {
    return forDay(userId, day).fold(
      NutritionFacts.zero,
      (sum, m) => sum + m.totals,
    );
  }

  /// Repas d'un utilisateur triés du plus récent au plus ancien.
  List<MealModel> allForUser(String userId) {
    final list = _load().where((m) => m.userId == userId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Tous les repas enregistrés (statistiques administrateur).
  List<MealModel> allMeals() {
    final list = _load();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<MealModel> addMeal({
    required String userId,
    required String type,
    DateTime? date,
  }) async {
    final meals = _load();
    final meal = MealModel(
      id: _newId,
      userId: userId,
      type: type,
      date: date,
    );
    meals.add(meal);
    await _save(meals);
    return meal;
  }

  Future<void> addItem(String mealId, MealItemModel item) async {
    final meals = _load();
    final meal = meals.firstWhere((m) => m.id == mealId);
    meal.items.add(item);
    await _save(meals);
  }

  Future<void> updateItemQuantity(
      String mealId, String itemId, double quantityG) async {
    final meals = _load();
    final meal = meals.firstWhere((m) => m.id == mealId);
    final item = meal.items.firstWhere((i) => i.id == itemId);
    item.quantityG = quantityG;
    await _save(meals);
  }

  Future<void> removeItem(String mealId, String itemId) async {
    final meals = _load();
    final meal = meals.firstWhere((m) => m.id == mealId);
    meal.items.removeWhere((i) => i.id == itemId);
    await _save(meals);
  }

  Future<void> deleteMeal(String mealId) async {
    final meals = _load()..removeWhere((m) => m.id == mealId);
    await _save(meals);
  }

  MealModel? byId(String mealId) {
    final list = _load().where((m) => m.id == mealId);
    return list.isEmpty ? null : list.first;
  }

  /// Nombre total de repas enregistrés (tous utilisateurs).
  int totalMeals() => _load().length;
}
