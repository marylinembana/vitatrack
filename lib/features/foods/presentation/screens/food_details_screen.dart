import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../data/models/food_model.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';

/// Fiche nutritionnelle d'un aliment (pour 100 g et par portion).
class FoodDetailsScreen extends StatefulWidget {
  final FoodModel food;
  const FoodDetailsScreen({super.key, required this.food});

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  late double _portion = widget.food.defaultPortionG;

  FoodModel get food => widget.food;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final facts = food.per100g.forQuantity(_portion);
    final cat = app.categoryById(food.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(food.name),
        actions: [
          IconButton(
            icon: Icon(
              app.isFavorite(food.id) ? Icons.favorite : Icons.favorite_border,
              color: app.isFavorite(food.id) ? AppColors.error : null,
            ),
            onPressed: () => app.toggleFavorite(food.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          Center(
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              clipBehavior: Clip.antiAlias,
              child: AppImage(
                url: food.imageUrl,
                width: 150,
                height: 150,
                fallback: Center(
                  child: Text(food.emoji ?? '🍽️',
                      style: const TextStyle(fontSize: 72)),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          Center(
            child: Text(
              cat?.name ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          AppCard(
            child: Column(
              children: [
                Text('Valeurs pour ${_portion.round()} g',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimensions.paddingSm),
                _CalorieHeader(kcal: facts.calories.round()),
                const SizedBox(height: AppDimensions.paddingMd),
                _MacroRow(
                  label: 'Protéines',
                  value: facts.proteins,
                  color: AppColors.proteins,
                ),
                _MacroRow(
                    label: 'Glucides', value: facts.carbs, color: AppColors.carbs),
                _MacroRow(
                    label: 'Lipides', value: facts.fats, color: AppColors.fats),
                _MacroRow(
                    label: 'Fibres', value: facts.fibers, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portion (grammes)',
                    style: Theme.of(context).textTheme.titleSmall),
                Slider(
                  value: _portion,
                  min: 10,
                  max: 500,
                  divisions: 49,
                  label: '${_portion.round()} g',
                  onChanged: (v) => setState(() => _portion = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          AppButton(
            label: 'Ajouter à un repas',
            icon: Icons.add,
            onPressed: () async {
              final added = await _showAddDialog(context, app, _portion);
              if (added == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _showAddDialog(
      BuildContext context, AppProvider app, double portion) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter au repas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MealTypeButtons(
              onSelected: (type) async {
                final meal = await app.createMeal(type);
                await app.addFoodToMeal(meal.id, food, portion);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Grille de boutons de types de repas (réutilisée dans l'ajout de repas).
class MealTypeButtons extends StatelessWidget {
  final void Function(String type) onSelected;
  const MealTypeButtons({super.key, required this.onSelected});

  static const _types = [
    ('Petit-déjeuner', Icons.breakfast_dining),
    ('Déjeuner', Icons.lunch_dining),
    ('Dîner', Icons.dinner_dining),
    ('Collation', Icons.cookie_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _types
          .map((t) => ListTile(
                leading: Icon(t.$2, color: AppColors.primary),
                title: Text(t.$1),
                onTap: () => onSelected(t.$1),
              ))
          .toList(),
    );
  }
}

class _CalorieHeader extends StatelessWidget {
  final int kcal;
  const _CalorieHeader({required this.kcal});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$kcal',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: AppColors.calories)),
        const SizedBox(width: 6),
        const Text('kcal'),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          Text('${value.toStringAsFixed(1)} g',
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
