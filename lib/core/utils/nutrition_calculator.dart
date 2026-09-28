import '../../app/constants/app_constants.dart';

/// Types d'objectif de poids.
enum GoalType { loss, maintain, gain }

extension GoalTypeX on GoalType {
  String get label => switch (this) {
    GoalType.loss => 'Perte de poids',
    GoalType.maintain => 'Maintien',
    GoalType.gain => 'Prise de poids',
  };

  String get key => name;

  static GoalType fromKey(String key) =>
      GoalType.values.firstWhere((g) => g.name == key,
          orElse: () => GoalType.maintain);
}

/// Calculs nutritionnels : IMC, besoins caloriques (Mifflin-St Jeor),
/// répartition des macros.
class NutritionCalculator {
  NutritionCalculator._();

  /// IMC = poids (kg) / taille (m)².
  static double bmi(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  static String bmiCategory(double bmiValue) {
    if (bmiValue < 18.5) return 'Insuffisance pondérale';
    if (bmiValue < 25) return 'Corpulence normale';
    if (bmiValue < 30) return 'Surpoids';
    return 'Obésité';
  }

  /// Métabolisme de base (formule de Mifflin-St Jeor).
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    return 10 * weightKg + 6.25 * heightCm - 5 * age + (isMale ? 5 : -161);
  }

  /// Dépense énergétique journalière selon le niveau d'activité
  /// (facteur de 1.2 à 1.9).
  static double tdee({required double bmrValue, required double activityFactor}) {
    return bmrValue * activityFactor;
  }

  static const List<({String label, double factor})> activityLevels = [
    (label: 'Sédentaire', factor: 1.2),
    (label: 'Légèrement actif (1-3 j/sem.)', factor: 1.375),
    (label: 'Modérément actif (3-5 j/sem.)', factor: 1.55),
    (label: 'Très actif (6-7 j/sem.)', factor: 1.725),
    (label: 'Extrêmement actif', factor: 1.9),
  ];

  /// Besoin calorique quotidien selon l'objectif.
  /// Perte : -20 %, maintien : ±0, prise : +15 %.
  static double calorieGoal({
    required double tdeeValue,
    required GoalType goal,
  }) {
    final adjusted = switch (goal) {
      GoalType.loss => tdeeValue * 0.8,
      GoalType.maintain => tdeeValue,
      GoalType.gain => tdeeValue * 1.15,
    };
    return adjusted.roundToDouble();
  }

  /// Répartition des macros en grammes à partir des calories cibles.
  static ({double proteins, double carbs, double fats}) macroGoals(
    double calories,
  ) {
    return (
      proteins:
          calories * AppConstants.proteinRatio / 4, // 4 kcal/g
      carbs: calories * AppConstants.carbRatio / 4, // 4 kcal/g
      fats: calories * AppConstants.fatRatio / 9, // 9 kcal/g
    );
  }
}
