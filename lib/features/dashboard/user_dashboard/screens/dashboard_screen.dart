import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/nutrition_card.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/models/food_model.dart';
import '../controllers/app_provider.dart';

/// Tableau de bord utilisateur : progression du jour, graphique hebdo, poids.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.user;
    final goal = app.goal;
    final totals = app.todayTotals;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Chargement...')));
    }

    final firstName =
        user.fullName.trim().split(RegExp(r'\s+')).firstWhere((e) => e.isNotEmpty, orElse: () => user.fullName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingMd, AppDimensions.paddingSm,
                AppDimensions.paddingMd, AppDimensions.paddingXl),
            children: [
              _HeroHeader(
                  name: firstName,
                  photoUrl: user.photoUrl,
                  remaining:
                      ((goal?.calorieTarget ?? user.calorieGoal) - totals.calories)
                          .round()),
              const SizedBox(height: AppDimensions.paddingMd),
              NutritionCard(
                consumed: totals,
                calorieGoal: goal?.calorieTarget ?? user.calorieGoal,
                proteinGoal: goal?.proteinTargetG ?? 0,
                carbGoal: goal?.carbTargetG ?? 0,
                fatGoal: goal?.fatTargetG ?? 0,
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              const _QuickActions(),
              const SizedBox(height: AppDimensions.paddingLg),
              const SectionHeader(title: 'Calories des 7 derniers jours'),
              _WeeklyChart(calories: app.weeklyCalories()),
              const SizedBox(height: AppDimensions.paddingLg),
              _WeightSummary(
                currentWeight: app.currentWeight,
                target: user.targetWeightKg,
                bmi: app.currentBmi,
                onTap: () => Navigator.of(context).pushNamed('/weight'),
              ),
              if (app.favorites.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.paddingLg),
                SectionHeader(
                  title: 'Mes favoris',
                  actionLabel: 'Voir',
                  onAction: () => Navigator.of(context).pushNamed('/foods'),
                ),
                _FavoritesStrip(foods: app.favorites),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau d'accueil en dégradé avec salutation, date et avatar.
class _HeroHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int remaining;
  const _HeroHeader({
    required this.name,
    required this.photoUrl,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, $name 👋',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(DateUtils.dayLabel(DateTime.now()),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              ProfileAvatar(
                name: name,
                photoUrl: photoUrl,
                radius: 24,
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white,
              ),
              const SizedBox(width: AppDimensions.paddingSm),
              _IconButton(
                icon: Icons.notifications_none,
                onTap: () =>
                    Navigator.of(context).pushNamed('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  remaining >= 0
                      ? Icons.local_fire_department_outlined
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: AppDimensions.paddingSm),
                Expanded(
                  child: Text(
                    remaining >= 0
                        ? 'Il vous reste $remaining kcal aujourd\'hui'
                        : 'Vous avez dépassé votre objectif de ${-remaining} kcal',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white24,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Action(
          icon: Icons.add_circle_outline,
          label: 'Ajouter\nun repas',
          color: AppColors.primary,
          route: '/meals/add',
        ),
        _Action(
          icon: Icons.speed,
          label: 'Peser\nmon poids',
          color: AppColors.info,
          route: '/weight',
        ),
        _Action(
          icon: Icons.psychology_outlined,
          label: 'Mes\nconseils',
          color: AppColors.accent,
          route: '/recommendations',
        ),
        _Action(
          icon: Icons.chat_bubble_outline,
          label: 'Mon\ncoach',
          color: AppColors.proteins,
          route: '/messaging',
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Histogramme soigné des calories sur 7 jours.
class _WeeklyChart extends StatelessWidget {
  final List<({DateTime day, double calories})> calories;
  const _WeeklyChart({required this.calories});

  @override
  Widget build(BuildContext context) {
    final maxCal =
        calories.map((e) => e.calories).fold<double>(1, (a, b) => a > b ? a : b);
    return AppCard(
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxCal * 1.25).clamp(1000, 5000),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  '${rod.toY.round()} kcal',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= calories.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateUtils.shortDayLabel(calories[i].day)[0],
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(calories.length, (i) {
              final isToday = i == calories.length - 1;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: calories[i].calories,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.primaryLight,
                        isToday ? AppColors.accent : AppColors.primary,
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Résumé du poids avec progression vers l'objectif.
class _WeightSummary extends StatelessWidget {
  final double currentWeight;
  final double target;
  final double bmi;
  final VoidCallback onTap;

  const _WeightSummary({
    required this.currentWeight,
    required this.target,
    required this.bmi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined,
                  color: AppColors.primary),
              const SizedBox(width: AppDimensions.paddingSm),
              Text('Mon poids',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Row(
            children: [
              Expanded(
                child: _Metric(
                    label: 'Actuel',
                    value: Formatters.kg(currentWeight),
                    color: AppColors.primary),
              ),
              Expanded(
                child: _Metric(
                    label: 'Objectif',
                    value: Formatters.kg(target),
                    color: AppColors.accent),
              ),
              Expanded(
                child: _Metric(
                    label: 'IMC',
                    value: bmi.toStringAsFixed(1),
                    color: AppColors.info),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Bandeau horizontal des aliments favoris avec leur image.
class _FavoritesStrip extends StatelessWidget {
  final List<FoodModel> foods;
  const _FavoritesStrip({required this.foods});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: foods.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.paddingSm),
        itemBuilder: (context, i) {
          final f = foods[i];
          return SizedBox(
            width: 108,
            child: AppCard(
              padding: const EdgeInsets.all(AppDimensions.paddingSm),
              onTap: () =>
                  Navigator.of(context).pushNamed('/foods/detail', arguments: f.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FoodThumb(imageUrl: f.imageUrl, emoji: f.emoji, size: 56),
                  const Spacer(),
                  Text(f.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
