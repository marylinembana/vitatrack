import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../data/models/food_model.dart';
import 'app_card.dart';
import 'app_image.dart';

/// Carte d'un aliment dans les listes de recherche.
class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.onAdd,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.paddingSm + 4),
      child: Row(
        children: [
          FoodThumb(imageUrl: food.imageUrl, emoji: food.emoji, size: 56),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${food.per100g.calories.round()} kcal / 100 g • '
                  'P ${food.per100g.proteins.round()} g • '
                  'G ${food.per100g.carbs.round()} g • '
                  'L ${food.per100g.fats.round()} g',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onToggleFavorite != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.error : AppColors.textHint,
                size: AppDimensions.iconSm + 2,
              ),
              onPressed: onToggleFavorite,
            ),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}
