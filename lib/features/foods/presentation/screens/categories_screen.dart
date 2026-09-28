import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../data/models/food_model.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';
import 'food_details_screen.dart';

/// Parcourir les aliments par catégorie (onglets).
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final cats = app.categories;
    final tabCount = cats.length + 1; // + "Tous"

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catégories'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Tous'),
              ...cats.map((c) => Tab(text: '${c.emoji} ${c.name}')),
            ],
          ),
        ),
        body: TabBarView(
          children: List.generate(tabCount, (i) {
            final List<FoodModel> list = i == 0
                ? cats.expand((c) => app.foodsInCategory(c.id)).toList()
                : app.foodsInCategory(cats[i - 1].id);
            if (list.isEmpty) {
              return const EmptyState(
                title: 'Catégorie vide',
                message: 'Aucun aliment dans cette catégorie.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSm),
              itemBuilder: (context, index) {
                final food = list[index];
                return FoodCard(
                  food: food,
                  isFavorite: app.isFavorite(food.id),
                  onToggleFavorite: () => app.toggleFavorite(food.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => FoodDetailsScreen(food: food)),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
