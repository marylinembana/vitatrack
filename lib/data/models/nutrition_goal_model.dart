import '../../core/utils/nutrition_calculator.dart';

/// Objectif nutritionnel de l'utilisateur.
class NutritionGoalModel {
  final String id;
  final String userId;
  GoalType type;
  double calorieTarget;
  double proteinTargetG;
  double carbTargetG;
  double fatTargetG;
  DateTime startDate;
  bool isActive;

  NutritionGoalModel({
    required this.id,
    required this.userId,
    this.type = GoalType.maintain,
    this.calorieTarget = 2200,
    this.proteinTargetG = 120,
    this.carbTargetG = 250,
    this.fatTargetG = 65,
    DateTime? startDate,
    this.isActive = true,
  }) : startDate = startDate ?? DateTime.now();

  factory NutritionGoalModel.fromMap(Map<String, dynamic> map) =>
      NutritionGoalModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        type: GoalTypeX.fromKey(map['type'] as String? ?? 'maintain'),
        calorieTarget:
            (map['calorieTarget'] as num?)?.toDouble() ?? 2200,
        proteinTargetG: (map['proteinTargetG'] as num?)?.toDouble() ?? 120,
        carbTargetG: (map['carbTargetG'] as num?)?.toDouble() ?? 250,
        fatTargetG: (map['fatTargetG'] as num?)?.toDouble() ?? 65,
        startDate:
            DateTime.tryParse(map['startDate'] as String? ?? '') ??
                DateTime.now(),
        isActive: map['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.key,
        'calorieTarget': calorieTarget,
        'proteinTargetG': proteinTargetG,
        'carbTargetG': carbTargetG,
        'fatTargetG': fatTargetG,
        'startDate': startDate.toIso8601String(),
        'isActive': isActive,
      };
}
