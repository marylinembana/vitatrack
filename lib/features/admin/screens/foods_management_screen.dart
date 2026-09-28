import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/food_model.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../data/repositories/food_repository.dart';

/// Gestion administrative du catalogue d'aliments.
class FoodsManagementScreen extends StatefulWidget {
  /// Callback optionnel invoqué après chaque modification du catalogue.
  final VoidCallback? onChanged;
  final bool includeInactive;

  const FoodsManagementScreen({
    super.key,
    this.onChanged,
    this.includeInactive = false,
  });

  @override
  State<FoodsManagementScreen> createState() => _FoodsManagementScreenState();
}

class _FoodsManagementScreenState extends State<FoodsManagementScreen> {
  final _repo = FoodRepository.instance;
  String _query = '';
  late Future<List<FoodModel>> _foodsFuture = _load();

  Future<List<FoodModel>> _load() =>
      _repo.all(includeInactive: widget.includeInactive);

  void _refresh() {
    setState(() => _foodsFuture = _load());
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des aliments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un aliment…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.primarySoft,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FoodModel>>(
              future: _foodsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final q = _query.trim().toLowerCase();
                final foods = snapshot.data!
                    .where((f) =>
                        q.isEmpty || f.name.toLowerCase().contains(q))
                    .toList();
                if (foods.isEmpty) {
                  return const Center(child: Text('Aucun aliment trouvé.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMd),
                  itemCount: foods.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final food = foods[i];
                    return ListTile(
                      leading: FoodThumb(
                          imageUrl: food.imageUrl, emoji: food.emoji),
                      title: Text(food.name),
                      subtitle: Text(
                          '${food.per100g.calories.round()} kcal • '
                          'P ${food.per100g.proteins.round()} g • '
                          'G ${food.per100g.carbs.round()} g • '
                          'L ${food.per100g.fats.round()} g / 100 g'
                          '${food.isActive ? '' : ' • désactivé'}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => switch (v) {
                          'edit' => _openForm(food: food),
                          'toggle' => _toggleActive(food),
                          _ => _delete(food),
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Modifier')),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(food.isActive
                                ? 'Désactiver'
                                : 'Réactiver'),
                          ),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Supprimer')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(FoodModel food) async {
    await _repo.setActive(food.id, !food.isActive);
    await _log(food.isActive ? 'activate_food' : 'deactivate_food', food.name);
    _refresh();
  }

  Future<void> _delete(FoodModel food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cet aliment ?'),
        content: Text('« ${food.name} » sera retiré du catalogue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child:
                  const Text('Supprimer', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.delete(food.id);
    await _log('delete_food', food.name);
    _refresh();
  }

  Future<void> _openForm({FoodModel? food}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FoodForm(food: food, repo: _repo),
    );
    if (saved == true) {
      await _log(food == null ? 'create_food' : 'update_food',
          food?.name ?? 'nouvel aliment');
      _refresh();
    }
  }

  Future<void> _log(String action, String target) =>
      AdminRepository.instance.log(
        actorId: 'admin',
        actorRole: 'admin',
        action: action,
        target: target,
      );
}

/// Formulaire d'ajout / modification d'un aliment.
class _FoodForm extends StatefulWidget {
  final FoodModel? food;
  final FoodRepository repo;

  const _FoodForm({required this.repo, this.food});

  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.food?.name ?? '');
  late final TextEditingController _emoji =
      TextEditingController(text: widget.food?.emoji ?? '');
  late final TextEditingController _imageUrl =
      TextEditingController(text: widget.food?.imageUrl ?? '');
  late final TextEditingController _brand =
      TextEditingController(text: widget.food?.brand ?? '');
  late final TextEditingController _portion = TextEditingController(
      text: (widget.food?.defaultPortionG ?? 100).toStringAsFixed(0));
  late final TextEditingController _calories = TextEditingController(
      text: (widget.food?.per100g.calories ?? 0).toStringAsFixed(0));
  late final TextEditingController _proteins = TextEditingController(
      text: (widget.food?.per100g.proteins ?? 0).toStringAsFixed(0));
  late final TextEditingController _carbs = TextEditingController(
      text: (widget.food?.per100g.carbs ?? 0).toStringAsFixed(0));
  late final TextEditingController _fats = TextEditingController(
      text: (widget.food?.per100g.fats ?? 0).toStringAsFixed(0));
  late final TextEditingController _fibers = TextEditingController(
      text: (widget.food?.per100g.fibers ?? 0).toStringAsFixed(0));
  late String? _categoryId = widget.food?.categoryId;
  late bool _active = widget.food?.isActive ?? true;
  List<CategoryEntry> _categories = [];

  @override
  void initState() {
    super.initState();
    _imageUrl.addListener(() => setState(() {}));
    widget.repo.categories().then((cats) {
      if (!mounted) return;
      setState(() {
        _categories = [
          for (final c in cats) CategoryEntry(c.id, c.name),
        ];
        _categoryId ??= cats.isEmpty ? null : cats.first.id;
      });
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name, _emoji, _imageUrl, _brand, _portion, _calories, _proteins, _carbs, _fats, _fibers
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingMd,
        right: AppDimensions.paddingMd,
        top: AppDimensions.paddingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            AppDimensions.paddingMd,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.food == null ? 'Nouvel aliment' : 'Modifier aliment',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.paddingMd),
              AppTextField(
                controller: _name,
                label: 'Nom',
                icon: Icons.eco_outlined,
                validator: Validators.required,
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _emoji,
                      label: 'Emoji',
                      hint: '🍚',
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Expanded(
                    child: AppTextField(
                      controller: _brand,
                      label: 'Marque (optionnel)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FoodThumb(imageUrl: _imageUrl.text.trim(), emoji: _emoji.text.trim().isEmpty ? '🍽️' : _emoji.text.trim(), size: 72),
                  const SizedBox(width: AppDimensions.paddingMd),
                  Expanded(
                    child: AppTextField(
                      controller: _imageUrl,
                      label: 'Image (URL) — optionnel',
                      icon: Icons.image_outlined,
                      hint: 'https://…/photo.jpg',
                    ),
                  ),
                ],
              ),
              if (_categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: _categories
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              const SizedBox(height: AppDimensions.paddingSm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _portion,
                      label: 'Portion (g)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Expanded(
                    child: AppTextField(
                      controller: _calories,
                      label: 'Calories / 100 g',
                      keyboardType: TextInputType.number,
                      validator: Validators.required,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _proteins,
                      label: 'Protéines (g)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Expanded(
                    child: AppTextField(
                      controller: _carbs,
                      label: 'Glucides (g)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Expanded(
                    child: AppTextField(
                      controller: _fats,
                      label: 'Lipides (g)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              AppTextField(
                controller: _fibers,
                label: 'Fibres (g)',
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Actif (visible des utilisateurs)'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) return;
    final food = FoodModel(
      id: widget.food?.id ??
          'food_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      categoryId: _categoryId!,
      emoji: _emoji.text.trim().isEmpty ? null : _emoji.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      defaultPortionG: _parse(_portion) <= 0 ? 100 : _parse(_portion),
      per100g: NutritionFacts(
        calories: _parse(_calories),
        proteins: _parse(_proteins),
        carbs: _parse(_carbs),
        fats: _parse(_fats),
        fibers: _parse(_fibers),
      ),
      isActive: _active,
    );
    await widget.repo.save(food);
    if (mounted) Navigator.of(context).pop(true);
  }
}

class CategoryEntry {
  final String id;
  final String name;
  const CategoryEntry(this.id, this.name);
}
