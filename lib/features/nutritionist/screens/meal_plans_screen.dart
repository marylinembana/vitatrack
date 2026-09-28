import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/food_card.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../data/models/food_model.dart';
import '../../../../data/models/meal_plan_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/food_repository.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';

/// Gestion des plans alimentaires du nutritionniste (liste + création).
class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({super.key});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  final _repo = NutritionRepository.instance;
  final Map<String, FoodModel> _foodById = {};
  bool _foodsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final foods = await FoodRepository.instance.all();
    for (final f in foods) {
      _foodById[f.id] = f;
    }
    if (mounted) setState(() => _foodsLoaded = true);
  }

  FoodModel? _food(String id) => _foodById[id];

  /// Total nutritionnel d'une entrée de plan (ratio quantité / 100 g).
  NutritionFacts _entryTotals(MealPlanEntry e) {
    final food = _food(e.foodId);
    if (food == null) return NutritionFacts.zero;
    return food.per100g.forQuantity(e.quantityG);
  }

  NutritionFacts _planTotals(MealPlanModel plan) => plan.entries.fold(
      NutritionFacts.zero, (sum, e) => sum + _entryTotals(e));

  List<MealPlanModel> get _plans {
    final auth = context.read<AuthProvider>();
    final id = auth.currentNutritionist?.id;
    if (id == null) return [];
    return _repo.byNutritionist(id);
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Plans alimentaires')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'plans_new',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _createPlan,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: !_foodsLoaded
          ? const Center(child: CircularProgressIndicator())
          : plans.isEmpty
              ? EmptyState(
                  icon: Icons.restaurant_menu,
                  title: 'Aucun plan',
                  message: 'Créez un plan alimentaire pour vos patients.',
                  actionLabel: 'Nouveau plan',
                  onAction: _createPlan,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.paddingMd,
                      AppDimensions.paddingMd, AppDimensions.paddingMd, 96),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.paddingMd),
                  itemBuilder: (context, i) => _PlanCard(
                    plan: plans[i],
                    patient: UserRepository.instance.byId(plans[i].patientId),
                    foodFor: _food,
                    totals: _planTotals(plans[i]),
                    onDelete: () => _deletePlan(plans[i]),
                  ),
                ),
    );
  }

  Future<void> _deletePlan(MealPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce plan ?'),
        content: Text('« ${plan.title} » sera définitivement supprimé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.delete(plan.id);
    if (mounted) setState(() {});
  }

  Future<void> _createPlan() async {
    final auth = context.read<AuthProvider>();
    final nutritionist = auth.currentNutritionist;
    if (nutritionist == null) return;
    final patients = nutritionist.patientIds
        .map((id) => UserRepository.instance.byId(id))
        .whereType<UserModel>()
        .toList();
    if (patients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajoutez d\'abord un patient.')));
      }
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    String patientId = patients.first.id;
    int days = 7;
    final entries = <MealPlanEntry>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.paddingMd,
            right: AppDimensions.paddingMd,
            top: AppDimensions.paddingMd,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                AppDimensions.paddingMd,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nouveau plan',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppDimensions.paddingMd),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Titre du plan'),
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Description (optionnel)'),
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                DropdownButtonFormField<String>(
                  value: patientId,
                  decoration: const InputDecoration(labelText: 'Patient'),
                  items: patients
                      .map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.fullName)))
                      .toList(),
                  onChanged: (v) => setSheet(() => patientId = v!),
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                DropdownButtonFormField<int>(
                  value: days,
                  decoration: const InputDecoration(labelText: 'Durée (jours)'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 jour')),
                    DropdownMenuItem(value: 3, child: Text('3 jours')),
                    DropdownMenuItem(value: 7, child: Text('7 jours')),
                    DropdownMenuItem(value: 14, child: Text('14 jours')),
                    DropdownMenuItem(value: 30, child: Text('30 jours')),
                  ],
                  onChanged: (v) => setSheet(() => days = v ?? days),
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                _EntriesEditor(
                  entries: entries,
                  foodFor: _food,
                  onChanged: () => setSheet(() {}),
                  onAdd: () => _addEntry(entries, setSheet),
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        entries.isEmpty) {
                      return;
                    }
                    final plan = MealPlanModel(
                      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
                      nutritionistId: nutritionist.id,
                      patientId: patientId,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      days: days,
                      entries: entries,
                    );
                    await _repo.save(plan);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  child: const Text('Créer le plan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addEntry(
      List<MealPlanEntry> entries, StateSetter setSheet) async {
    final mealType = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Moment du repas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MealType.all
              .map((t) => ListTile(
                    leading: Icon(_mealIcon(t), color: AppColors.primary),
                    title: Text(t),
                    onTap: () => Navigator.pop(dialogContext, t),
                  ))
              .toList(),
        ),
      ),
    );
    if (mealType == null) return;
    if (!mounted) return;
    final food = await showModalBottomSheet<FoodModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _PlanFoodPicker(),
    );
    if (food == null) return;
    setSheet(() {
      entries.add(MealPlanEntry(
        mealType: mealType,
        foodId: food.id,
        foodName: food.name,
        quantityG: food.defaultPortionG,
      ));
    });
  }
}

IconData _mealIcon(String type) => switch (type) {
      MealType.breakfast => Icons.wb_sunny_outlined,
      MealType.lunch => Icons.wb_twilight_outlined,
      MealType.dinner => Icons.nightlight_outlined,
      _ => Icons.cookie_outlined,
    };

/// Aperçu compact des entrées ajoutées pendant la création d'un plan.
class _EntriesEditor extends StatelessWidget {
  final List<MealPlanEntry> entries;
  final FoodModel? Function(String id) foodFor;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  const _EntriesEditor({
    required this.entries,
    required this.foodFor,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Repas du plan (${entries.length})',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Text(
              'Aucun repas pour l\'instant. Ajoutez au moins un aliment.',
              style: TextStyle(color: AppColors.primaryDark, fontSize: 13),
            ),
          )
        else
          for (final e in entries.toList())
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  FoodThumb(
                      imageUrl: foodFor(e.foodId)?.imageUrl,
                      emoji: foodFor(e.foodId)?.emoji,
                      size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${e.mealType} • ${e.foodName} (${e.quantityG.round()} g)',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Retirer',
                    icon: const Icon(Icons.close, size: 16),
                    color: AppColors.textHint,
                    onPressed: () {
                      entries.remove(e);
                      onChanged();
                    },
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Carte riche d'un plan : en-tête, totaux, repas groupés dépliables.
class _PlanCard extends StatelessWidget {
  final MealPlanModel plan;
  final UserModel? patient;
  final FoodModel? Function(String id) foodFor;
  final NutritionFacts totals;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.patient,
    required this.foodFor,
    required this.totals,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final byType = <String, List<MealPlanEntry>>{};
    for (final e in plan.entries) {
      byType.putIfAbsent(e.mealType, () => []).add(e);
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLg)),
            ),
            child: Row(
              children: [
                ProfileAvatar(
                  photoUrl: patient?.photoUrl,
                  name: patient?.fullName ?? '?',
                  radius: 22,
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('Pour ${patient?.fullName ?? '—'} • ${plan.days} j',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${totals.calories.round()} kcal/j',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          if (plan.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.paddingMd,
                  AppDimensions.paddingSm, AppDimensions.paddingMd, 0),
              child: Text(plan.description,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.paddingMd,
                AppDimensions.paddingSm, AppDimensions.paddingMd,
                AppDimensions.paddingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final type in MealType.all)
                  if (byType[type] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_mealIcon(type),
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(type,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          for (final e in byType[type]!)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 4, bottom: 4),
                              child: Row(
                                children: [
                                  FoodThumb(
                                      imageUrl: foodFor(e.foodId)?.imageUrl,
                                      emoji: foodFor(e.foodId)?.emoji,
                                      size: 34),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${e.foodName} — ${e.quantityG.round()} g',
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${_entryCalories(e).round()} kcal',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.calories,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _entryCalories(MealPlanEntry e) {
    final food = foodFor(e.foodId);
    if (food == null) return 0;
    return food.per100g.forQuantity(e.quantityG).calories;
  }
}

class _PlanFoodPicker extends StatefulWidget {
  const _PlanFoodPicker();

  @override
  State<_PlanFoodPicker> createState() => _PlanFoodPickerState();
}

class _PlanFoodPickerState extends State<_PlanFoodPicker> {
  late final Future<List<FoodModel>> _foodsFuture =
      FoodRepository.instance.all();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: FutureBuilder<List<FoodModel>>(
        future: _foodsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final foods = snapshot.data!;
          return ListView.builder(
            itemCount: foods.length,
            itemBuilder: (context, i) => FoodCard(
              food: foods[i],
              onTap: () => Navigator.of(context).pop(foods[i]),
            ),
          );
        },
      ),
    );
  }
}
