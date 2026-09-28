import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/food_model.dart';
import '../../../../data/models/meal_model.dart';
import '../../../dashboard/user_dashboard/controllers/app_provider.dart';
import 'add_meal_screen.dart';
import 'meal_details_screen.dart';

/// Journal alimentaire : sélecteur de jours horizontal + repas groupés.
class FoodJournalScreen extends StatefulWidget {
  const FoodJournalScreen({super.key});

  @override
  State<FoodJournalScreen> createState() => _FoodJournalScreenState();
}

class _FoodJournalScreenState extends State<FoodJournalScreen> {
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  void _selectDay(DateTime day) => setState(() => _day = DateUtils.dateOnly(day));

  /// Les 7 jours de la semaine contenant [_day] (lundi → dimanche).
  List<DateTime> _weekDays() {
    final monday = _day.subtract(Duration(days: _day.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) _selectDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.user;
    final meals = app.mealsForDay(_day);
    final totals = meals.fold<NutritionFacts>(
        NutritionFacts.zero, (sum, m) => sum + m.totals);
    final goalCalories = app.goal?.calorieTarget ?? user?.calorieGoal ?? 2200;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journal alimentaire'),
        actions: [
          IconButton(
            tooltip: 'Choisir une date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'journal_add',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddMealScreen(initialDate: _day)),
          );
          app.refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          _WeekStrip(
            days: _weekDays(),
            selected: _day,
            onSelect: _selectDay,
          ),
          _DaySummary(
            date: _day,
            totals: totals,
            goalCalories: goalCalories,
          ),
          Expanded(
            child: meals.isEmpty
                ? _EmptyDay(date: _day, onAdd: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => AddMealScreen(initialDate: _day)),
                    );
                  })
                : _GroupedMeals(
                    day: _day,
                    meals: meals,
                    app: app,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Barre horizontale des 7 jours de la semaine.
class _WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingSm,
          horizontal: AppDimensions.paddingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final d in days)
            Expanded(
              child: _DayChip(
                date: d,
                selected: DateUtils.isSameDay(d, selected),
                isToday: DateUtils.isToday(d),
                onTap: () => onSelect(d),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayChip({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isToday && !selected
                ? AppColors.primaryLight
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(DateUtils.shortDayLabel(date)[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color)),
            const SizedBox(height: 4),
            Text('${date.day}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

/// Résumé du jour sélectionné (calories + macros).
class _DaySummary extends StatelessWidget {
  final DateTime date;
  final NutritionFacts totals;
  final double goalCalories;

  const _DaySummary({
    required this.date,
    required this.totals,
    required this.goalCalories,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (goalCalories - totals.calories).round();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppDimensions.paddingMd,
          AppDimensions.paddingSm, AppDimensions.paddingMd, 0),
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateUtils.dayLabel(date),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${totals.calories.round()}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ ${goalCalories.round()} kcal',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85))),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  remaining >= 0 ? '$remaining restantes' : '${-remaining} en trop',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Row(
            children: [
              _MacroPill('Protéines', totals.proteins, AppColors.proteins),
              _MacroPill('Glucides', totals.carbs, AppColors.carbs),
              _MacroPill('Lipides', totals.fats, AppColors.fats),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MacroPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Column(
          children: [
            Text('${value.round()} g',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Repas du jour groupés par moment (petit-déj, déjeuner…).
class _GroupedMeals extends StatelessWidget {
  final DateTime day;
  final List<MealModel> meals;
  final AppProvider app;

  const _GroupedMeals({
    required this.day,
    required this.meals,
    required this.app,
  });

  IconData _icon(String type) => switch (type) {
        MealType.breakfast => Icons.wb_sunny_outlined,
        MealType.lunch => Icons.wb_twilight_outlined,
        MealType.dinner => Icons.nightlight_outlined,
        _ => Icons.cookie_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppDimensions.paddingMd,
          AppDimensions.paddingMd, AppDimensions.paddingMd, 96),
      children: [
        for (final type in MealType.all)
          if (meals.where((m) => m.type == type).isNotEmpty)
            _buildSection(context, type),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String type) {
    final group = meals.where((m) => m.type == type).toList();
    final sub = group.fold<NutritionFacts>(
        NutritionFacts.zero, (sum, m) => sum + m.totals);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.paddingSm),
            child: Row(
              children: [
                Icon(_icon(type), color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(type,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${sub.calories.round()} kcal',
                    style: const TextStyle(
                        color: AppColors.calories,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          for (final meal in group) _MealTile(meal: meal, app: app),
        ],
      ),
    );
  }
}

/// Carte d'un repas : liste des aliments avec image, quantité et calories.
class _MealTile extends StatelessWidget {
  final MealModel meal;
  final AppProvider app;
  const _MealTile({required this.meal, required this.app});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MealDetailsScreen(mealId: meal.id)),
        );
        app.refresh();
      },
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Column(
        children: [
          for (var i = 0; i < meal.items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 64, endIndent: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  FoodThumb(
                    imageUrl: app.foodById(meal.items[i].foodId)?.imageUrl,
                    emoji: app.foodById(meal.items[i].foodId)?.emoji,
                    size: 44,
                  ),
                  const SizedBox(width: AppDimensions.paddingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.items[i].foodName,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${meal.items[i].quantityG.round()} g • '
                          'P ${meal.items[i].totals.proteins.round()} • '
                          'G ${meal.items[i].totals.carbs.round()} • '
                          'L ${meal.items[i].totals.fats.round()} g',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.number(meal.items[i].totals.calories.round()),
                    style: const TextStyle(
                        color: AppColors.calories,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textHint),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// État vide d'une journée sans repas.
class _EmptyDay extends StatelessWidget {
  final DateTime date;
  final VoidCallback onAdd;
  const _EmptyDay({required this.date, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Aucun repas enregistré',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              DateUtils.isToday(date)
                  ? 'Ajoutez votre premier repas de la journée.'
                  : 'Aucun repas pour le ${DateUtils.dateLabel(date)}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un repas'),
            ),
          ],
        ),
      ),
    );
  }
}
