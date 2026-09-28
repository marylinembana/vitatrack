import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../data/models/food_model.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';

/// Ajout d'un repas : choix du type puis ajout d'aliments avec quantités.
class AddMealScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialType;

  const AddMealScreen({super.key, this.initialDate, this.initialType});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  String? _type;
  final List<FoodModel> _items = [];
  final Map<String, double> _quantities = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  Future<void> _save() async {
    if (_type == null || _items.isEmpty) return;
    setState(() => _saving = true);
    final app = context.read<AppProvider>();
    final meal = await app.createMeal(_type!, date: widget.initialDate);
    for (final food in _items) {
      await app.addFoodToMeal(meal.id, food, _quantities[food.id] ?? 100);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau repas')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          Text('Type de repas',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDimensions.paddingSm),
          Wrap(
            spacing: 8,
            children: MealType.all.map((t) {
              final selected = _type == t;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Row(
            children: [
              Text('Aliments',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final food = await showModalBottomSheet<FoodModel>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const _FoodPickerSheet(),
                  );
                  if (food != null && mounted) {
                    setState(() {
                      _items.add(food);
                      _quantities.putIfAbsent(food.id,
                          () => food.defaultPortionG);
                    });
                  }
                },
                icon: const Icon(Icons.add, size: AppDimensions.iconSm),
                label: const Text('Ajouter un aliment'),
              ),
            ],
          ),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
              child: Text(
                'Aucun aliment ajouté. Touchez « Ajouter un aliment ».',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ..._items.map((food) {
            return Card(
              child: ListTile(
                leading: FoodThumb(
                    imageUrl: food.imageUrl, emoji: food.emoji, size: 44),
                title: Text(food.name),
                subtitle: Text(
                    '${(_quantities[food.id] ?? 100).round()} g • '
                    '${food.per100g.forQuantity(_quantities[food.id] ?? 100).calories.round()} kcal'),
                trailing: PopupMenuButton<int>(
                  onSelected: (v) {
                    if (v == 0) setState(() => _items.remove(food));
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 0, child: Text('Retirer')),
                  ],
                ),
              ),
            );
          }),
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMd),
              child: Column(
                children: _items.map((food) {
                  return StatefulBuilder(
                    builder: (context, setLocalState) {
                      final qty = _quantities[food.id] ?? 100;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${food.name} — ${qty.round()} g',
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                          Slider(
                            value: qty,
                            min: 10,
                            max: 500,
                            divisions: 49,
                            onChanged: (v) {
                              setState(() => _quantities[food.id] = v);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppDimensions.paddingMd),
          ElevatedButton.icon(
            onPressed:
                (_type == null || _items.isEmpty || _saving) ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer le repas'),
          ),
        ],
      ),
    );
  }
}

/// Feuille modale de sélection d'aliment (liste + recherche simple).
class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet();

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final results = _query.isEmpty
        ? app.categories
            .expand((c) => app.foodsInCategory(c.id))
            .take(50)
            .toList()
        : _filterFoods(_query, app);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final food = results[i];
                return FoodCard(
                  food: food,
                  onTap: () => Navigator.of(context).pop(food),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<FoodModel> _filterFoods(String query, AppProvider app) {
    // Recherche synchrone locale (les données sont déjà en mémoire).
    final q = query.toLowerCase();
    return app
        .categories
        .expand((c) => app.foodsInCategory(c.id))
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
  }
}
