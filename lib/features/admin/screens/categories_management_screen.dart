import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/food_model.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../data/repositories/food_repository.dart';

/// Gestion administrative des catégories d'aliments.
class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends State<CategoriesManagementScreen> {
  final _repo = FoodRepository.instance;
  late Future<List<CategoryModel>> _categoriesFuture = _repo.categories();
  late Future<List<FoodModel>> _foodsFuture =
      _repo.all(includeInactive: true);

  void _refresh() {
    setState(() {
      _categoriesFuture = _repo.categories();
      _foodsFuture = _repo.all(includeInactive: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          return FutureBuilder<List<FoodModel>>(
            future: _foodsFuture,
            builder: (context, foodsSnapshot) {
              final foods = foodsSnapshot.data ?? const <FoodModel>[];
              return ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final category = categories[i];
                  final count = foods
                      .where((f) => f.categoryId == category.id)
                      .length;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Text(category.emoji),
                    ),
                    title: Text(category.name),
                    subtitle: Text('$count aliment(s)'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => v == 'edit'
                          ? _openForm(category: category)
                          : _delete(category),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Modifier')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Supprimer')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm({CategoryModel? category}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryForm(repo: _repo, category: category),
    );
    if (saved == true) {
      await AdminRepository.instance.log(
        actorId: 'admin',
        actorRole: 'admin',
        action: category == null ? 'create_category' : 'update_category',
        target: category?.name ?? 'nouvelle catégorie',
      );
      _refresh();
    }
  }

  Future<void> _delete(CategoryModel category) async {
    final foods = await _repo.all(includeInactive: true);
    if (!mounted) return;
    final count =
        foods.where((f) => f.categoryId == category.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette catégorie ?'),
        content: Text(count > 0
            ? '« ${category.name} » contient $count aliment(s). '
                'Ils resteront au catalogue mais sans catégorie visible.'
            : '« ${category.name} » sera supprimée.'),
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
    await _repo.deleteCategory(category.id);
    await AdminRepository.instance.log(
      actorId: 'admin',
      actorRole: 'admin',
      action: 'delete_category',
      target: category.name,
    );
    _refresh();
  }
}

class _CategoryForm extends StatefulWidget {
  final FoodRepository repo;
  final CategoryModel? category;

  const _CategoryForm({required this.repo, this.category});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.category?.name ?? '');
  late final TextEditingController _emoji =
      TextEditingController(text: widget.category?.emoji ?? '');

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    super.dispose();
  }

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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                widget.category == null
                    ? 'Nouvelle catégorie'
                    : 'Modifier catégorie',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppDimensions.paddingMd),
            AppTextField(
              controller: _name,
              label: 'Nom',
              icon: Icons.category_outlined,
              validator: Validators.required,
            ),
            AppTextField(
              controller: _emoji,
              label: 'Emoji',
              hint: '🥗',
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            ElevatedButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                final category = CategoryModel(
                  id: widget.category?.id ??
                      'cat_${DateTime.now().millisecondsSinceEpoch}',
                  name: _name.text.trim(),
                  emoji:
                      _emoji.text.trim().isEmpty ? '🍽️' : _emoji.text.trim(),
                );
                final navigator = Navigator.of(context);
                await widget.repo.saveCategory(category);
                navigator.pop(true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
