import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/meal_card.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';
import 'add_meal_screen.dart';

/// Détail d'un repas : ses aliments + ajout d'aliments supplémentaires.
class MealDetailsScreen extends StatefulWidget {
  final String mealId;
  const MealDetailsScreen({super.key, required this.mealId});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final meal = app.mealById(widget.mealId);

    if (meal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Repas')),
        body: const Center(child: Text('Repas introuvable.')),
      );
    }

    final totals = meal.totals;
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.type),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await app.deleteMeal(meal.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          Text(DateUtils.dateLabel(meal.date),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppDimensions.paddingSm),
          MealCard(meal: meal),
          const SizedBox(height: AppDimensions.paddingMd),
          Text('Détail des aliments',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.paddingSm),
          ...meal.items.map((item) {
            final t = item.totals;
            return Card(
              child: ListTile(
                title: Text(item.foodName),
                subtitle: Text('${item.quantityG.round()} g • '
                    '${t.calories.round()} kcal • '
                    'P ${t.proteins.round()} g • '
                    'G ${t.carbs.round()} g • '
                    'L ${t.fats.round()} g'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.error),
                  onPressed: () =>
                      app.removeItem(meal.id, item.id),
                ),
              ),
            );
          }),
          const SizedBox(height: AppDimensions.paddingLg),
          Text(
            'Total : ${totals.calories.round()} kcal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.calories,
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  AddMealScreen(initialType: meal.type)));
        },
        icon: const Icon(Icons.add),
        label: const Text('Autre repas'),
      ),
    );
  }
}
