import '../../core/services/local_store.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../models/nutrition_goal_model.dart';

/// Repository des objectifs nutritionnels.
class GoalRepository {
  GoalRepository._();
  static final GoalRepository instance = GoalRepository._();

  final LocalStore _store = LocalStore.instance;

  List<NutritionGoalModel> _load() => _store
      .readList(StoreKeys.goals)
      .map(NutritionGoalModel.fromMap)
      .toList();

  Future<void> _save(List<NutritionGoalModel> list) =>
      _store.writeList(StoreKeys.goals, list.map((g) => g.toMap()).toList());

  NutritionGoalModel? active(String userId) {
    final list = _load()
        .where((g) => g.userId == userId && g.isActive)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return list.isEmpty ? null : list.first;
  }

  /// Crée ou met à jour l'objectif actif à partir des besoins calculés.
  Future<NutritionGoalModel> upsert({
    required String userId,
    required GoalType type,
    required double calorieTarget,
  }) async {
    final list = _load();
    final macros = NutritionCalculator.macroGoals(calorieTarget);
    final existing = list
        .where((g) => g.userId == userId && g.isActive)
        .toList();
    for (final g in existing) {
      g.isActive = false;
    }
    final goal = NutritionGoalModel(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      calorieTarget: calorieTarget,
      proteinTargetG: macros.proteins,
      carbTargetG: macros.carbs,
      fatTargetG: macros.fats,
    );
    list.add(goal);
    await _save(list);
    return goal;
  }
}
