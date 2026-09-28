import '../../core/services/local_store.dart';
import '../models/meal_plan_model.dart';
import 'meal_repository.dart';

/// Repository des plans alimentaires et analyses nutritionnelles.
class NutritionRepository {
  NutritionRepository._();
  static final NutritionRepository instance = NutritionRepository._();

  final LocalStore _store = LocalStore.instance;

  List<MealPlanModel> _load() => _store
      .readList(StoreKeys.mealPlans)
      .map(MealPlanModel.fromMap)
      .toList();

  Future<void> _save(List<MealPlanModel> list) => _store.writeList(
        StoreKeys.mealPlans,
        list.map((p) => p.toMap()).toList(),
      );

  /// Plans créés par un nutritionniste.
  List<MealPlanModel> byNutritionist(String nutritionistId) => _load()
      .where((p) => p.nutritionistId == nutritionistId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Plans assignés à un patient.
  List<MealPlanModel> forPatient(String patientId) => _load()
      .where((p) => p.patientId == patientId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<MealPlanModel> save(MealPlanModel plan) async {
    final list = _load();
    final index = list.indexWhere((p) => p.id == plan.id);
    if (index == -1) {
      list.add(plan);
    } else {
      list[index] = plan;
    }
    await _save(list);
    return plan;
  }

  Future<void> delete(String planId) async {
    final list = _load()..removeWhere((p) => p.id == planId);
    await _save(list);
  }

  /// Analyse nutritionnelle hebdomadaire (moyennes journalières) d'un patient.
  /// Retourne : moyenne kcal, protéines, glucides, lipides + nombre de jours
  /// avec journal.
  static ({
    double avgCalories,
    double avgProteins,
    double avgCarbs,
    double avgFats,
    int loggedDays,
  }) weeklyAnalysis(String patientId) {
    final days = DateTime.now().subtract(const Duration(days: 6));
    double kcal = 0, p = 0, c = 0, f = 0;
    int logged = 0;
    for (var i = 0; i < 7; i++) {
      final day = days.add(Duration(days: i));
      final totals =
          MealRepository.instance.totalsForDay(patientId, day);
      if (totals.calories > 0) {
        logged++;
        kcal += totals.calories;
        p += totals.proteins;
        c += totals.carbs;
        f += totals.fats;
      }
    }
    final d = logged == 0 ? 1 : logged;
    return (
      avgCalories: kcal / d,
      avgProteins: p / d,
      avgCarbs: c / d,
      avgFats: f / d,
      loggedDays: logged,
    );
  }

  /// Calories par jour sur les 7 derniers jours (pour graphique).
  static List<({DateTime day, double calories})> weeklyCaloriesByDay(
      String patientId) {
    final start = DateTime.now().subtract(const Duration(days: 6));
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final totals = MealRepository.instance.totalsForDay(patientId, day);
      return (day: day, calories: totals.calories);
    });
  }
}
