import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../data/models/food_model.dart';
import 'app_card.dart';

/// Carte de progression nutritionnelle du jour (calories + macros).
class NutritionCard extends StatelessWidget {
  final NutritionFacts consumed;
  final double calorieGoal;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;

  const NutritionCard({
    super.key,
    required this.consumed,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
  });

  double get _progress =>
      calorieGoal <= 0 ? 0 : (consumed.calories / calorieGoal).clamp(0, 1.5);

  Color get _progressColor {
    if (_progress >= 1.1) return AppColors.error;
    if (_progress >= 0.9) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (calorieGoal - consumed.calories).round();
    return AppCard(
      child: Row(
        children: [
          SizedBox(
            height: 96,
            width: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (_progress / 1.5).clamp(0, 1),
                    strokeWidth: 8,
                    backgroundColor: AppColors.primarySoft,
                    valueColor: AlwaysStoppedAnimation(_progressColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${consumed.calories.round()}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('kcal',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remaining > 0
                      ? '$remaining kcal restantes'
                      : '${-remaining} kcal de dépassement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                _MacroBar(
                    label: 'Protéines',
                    value: consumed.proteins,
                    goal: proteinGoal,
                    color: AppColors.proteins),
                _MacroBar(
                    label: 'Glucides',
                    value: consumed.carbs,
                    goal: carbGoal,
                    color: AppColors.carbs),
                _MacroBar(
                    label: 'Lipides',
                    value: consumed.fats,
                    goal: fatGoal,
                    color: AppColors.fats),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text('${value.round()} / ${goal.round()} g',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
