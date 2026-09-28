import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../data/models/category_model.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';
import 'categories_screen.dart';
import 'food_search_screen.dart';

/// Onglet aliments : recherche + catégories + favoris.
class FoodsScreen extends StatelessWidget {
  const FoodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final favorites = app.favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('Aliments')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMd,
                  vertical: AppDimensions.paddingMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: const Color(0xFFDDE5DD)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary),
                  SizedBox(width: AppDimensions.paddingSm),
                  Text('Rechercher un aliment…',
                      style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Text('Catégories',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.paddingSm),
          _CategoriesGrid(categories: app.categories),
          if (favorites.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingLg),
            Row(
              children: [
                Text('Favoris',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const CategoriesScreen()),
                  ),
                  child: const Text('Tout voir'),
                ),
              ],
            ),
            ...favorites.take(4).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => Navigator.of(context)
                        .pushNamed('/foods/detail', arguments: f.id),
                    child: Row(
                      children: [
                        FoodThumb(imageUrl: f.imageUrl, emoji: f.emoji, size: 44),
                        const SizedBox(width: AppDimensions.paddingMd),
                        Expanded(
                          child: Text(f.name,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ),
                        const Icon(Icons.favorite,
                            size: 16, color: AppColors.error),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoriesGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.paddingSm,
      crossAxisSpacing: AppDimensions.paddingSm,
      childAspectRatio: 2.2,
      children: categories.map((c) {
        return AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    FoodSearchScreen(initialCategory: c.id)),
          ),
          child: Row(
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: AppDimensions.paddingSm),
              Expanded(
                child: Text(
                  c.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
