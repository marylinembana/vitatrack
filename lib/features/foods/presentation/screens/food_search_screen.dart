import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../data/models/food_model.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';
import 'food_details_screen.dart';

/// Recherche d'aliments par nom et catégorie.
class FoodSearchScreen extends StatefulWidget {
  final String? initialCategory;
  const FoodSearchScreen({super.key, this.initialCategory});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _controller = TextEditingController();
  List<FoodModel> _results = [];
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategory;
    _runSearch('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final app = context.read<AppProvider>();
    final res = await app.search(query, categoryId: _categoryId);
    if (!mounted) return;
    setState(() => _results = res);
  }

  void _openFood(FoodModel food) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FoodDetailsScreen(food: food),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            child: TextField(
              controller: _controller,
              onChanged: _runSearch,
              decoration: InputDecoration(
                hintText: 'Nom de l\'aliment…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _runSearch('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
              children: [
                _chip(context, 'Tous', null),
                ...app.categories.map(
                  (c) => _chip(context, c.name, c.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          Expanded(
            child: _results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Aucun aliment',
                    message: 'Essayez un autre mot-clé ou une autre catégorie.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMd),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.paddingSm),
                    itemBuilder: (context, i) {
                      final food = _results[i];
                      return FoodCard(
                        food: food,
                        isFavorite: app.isFavorite(food.id),
                        onToggleFavorite: () =>
                            app.toggleFavorite(food.id),
                        onTap: () => _openFood(food),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String? id) {
    final selected = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.paddingSm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _categoryId = id);
          _runSearch(_controller.text);
        },
      ),
    );
  }
}
