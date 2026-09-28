import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../data/models/food_model.dart';
import '../../data/models/meal_model.dart';
import 'app_card.dart';

/// Carte récapitulative d'un repas dans le journal.
class MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
  });

  IconData get _icon => switch (meal.type) {
        'Petit-déjeuner' => Icons.breakfast_dining,
        'Déjeuner' => Icons.lunch_dining,
        'Dîner' => Icons.dinner_dining,
        _ => Icons.cookie_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final NutritionFacts t = meal.totals;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: AppColors.primary, size: AppDimensions.iconMd),
              const SizedBox(width: AppDimensions.paddingSm),
              Text(meal.type,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${t.calories.round()} kcal',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.calories),
              ),
              if (onDelete != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.textHint, size: AppDimensions.iconSm + 2),
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          if (meal.items.isEmpty)
            Text('Aucun aliment enregistré',
                style: Theme.of(context).textTheme.bodySmall)
          else
            Text(
              meal.items
                  .map((i) => '${i.foodName} (${i.quantityG.round()} g)')
                  .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppDimensions.paddingSm),
          Row(
            children: [
              _MacroDot(color: AppColors.proteins, label: 'Protéines', value: t.proteins),
              const SizedBox(width: 14),
              _MacroDot(color: AppColors.carbs, label: 'Glucides', value: t.carbs),
              const SizedBox(width: 14),
              _MacroDot(color: AppColors.fats, label: 'Lipides', value: t.fats),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroDot extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _MacroDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 8,
          width: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label ${value.round()} g',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
