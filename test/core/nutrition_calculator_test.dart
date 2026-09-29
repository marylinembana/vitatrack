import 'package:flutter_test/flutter_test.dart';
import 'package:vitatrack/core/utils/nutrition_calculator.dart';

void main() {
  group('NutritionCalculator.bmi', () {
    test('calcule l\'IMC poids/taille²', () {
      // 70 kg / (1.75 m)² ≈ 22.86
      expect(NutritionCalculator.bmi(70, 175), closeTo(22.857, 0.001));
    });

    test('retourne 0 si la taille est invalide', () {
      expect(NutritionCalculator.bmi(70, 0), 0);
      expect(NutritionCalculator.bmi(70, -10), 0);
    });
  });

  group('NutritionCalculator.bmiCategory', () {
    test('classe chaque seuil d\'IMC', () {
      expect(NutritionCalculator.bmiCategory(17), 'Insuffisance pondérale');
      expect(NutritionCalculator.bmiCategory(22), 'Corpulence normale');
      expect(NutritionCalculator.bmiCategory(27), 'Surpoids');
      expect(NutritionCalculator.bmiCategory(31), 'Obésité');
    });
  });

  group('NutritionCalculator.bmr (Mifflin-St Jeor)', () {
    test('formule homme', () {
      // 10*70 + 6.25*175 - 5*30 + 5 = 1648.75
      final value = NutritionCalculator.bmr(
          weightKg: 70, heightCm: 175, age: 30, isMale: true);
      expect(value, closeTo(1648.75, 0.001));
    });

    test('formule femme (constante -161)', () {
      // 10*60 + 6.25*165 - 5*28 - 161 = 1330.25
      final value = NutritionCalculator.bmr(
          weightKg: 60, heightCm: 165, age: 28, isMale: false);
      expect(value, closeTo(1330.25, 0.001));
    });
  });

  group('NutritionCalculator.tdee', () {
    test('multiplie le BMR par le facteur d\'activité', () {
      expect(
        NutritionCalculator.tdee(bmrValue: 2000, activityFactor: 1.375),
        closeTo(2750, 0.001),
      );
    });
  });

  group('NutritionCalculator.calorieGoal', () {
    test('perte : -20 %', () {
      expect(
        NutritionCalculator.calorieGoal(tdeeValue: 2000, goal: GoalType.loss),
        1600,
      );
    });

    test('maintien : inchangé', () {
      expect(
        NutritionCalculator.calorieGoal(
            tdeeValue: 2000, goal: GoalType.maintain),
        2000,
      );
    });

    test('prise : +15 % arrondi', () {
      expect(
        NutritionCalculator.calorieGoal(tdeeValue: 2000, goal: GoalType.gain),
        2300,
      );
    });
  });

  group('NutritionCalculator.macroGoals', () {
    test('répartit les macros selon les ratios (protides 30 %, glucides 45 %, lipides 25 %)', () {
      final m = NutritionCalculator.macroGoals(2000);
      // protides : 2000*0.30/4 = 150 g
      expect(m.proteins, closeTo(150, 0.001));
      // glucides : 2000*0.45/4 = 225 g
      expect(m.carbs, closeTo(225, 0.001));
      // lipides : 2000*0.25/9 ≈ 55.56 g
      expect(m.fats, closeTo(55.555, 0.01));
    });
  });

  group('GoalTypeX', () {
    test('label de chaque objectif', () {
      expect(GoalType.loss.label, 'Perte de poids');
      expect(GoalType.maintain.label, 'Maintien');
      expect(GoalType.gain.label, 'Prise de poids');
    });

    test('fromKey retombe sur maintien si clé inconnue', () {
      expect(GoalTypeX.fromKey('loss'), GoalType.loss);
      expect(GoalTypeX.fromKey('inconnu'), GoalType.maintain);
    });
  });
}
