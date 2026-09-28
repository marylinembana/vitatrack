import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide DateUtils;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/meal_model.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../data/repositories/meal_repository.dart';

/// Statistiques globales de la plateforme (admin).
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<({int totalUsers, int totalNutritionists, int totalFoods,
      int totalCategories, int mealsLogged, int activeToday})> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminRepository.instance.statistics();
  }

  @override
  Widget build(BuildContext context) {
    final meals = MealRepository.instance.allMeals();
    final weekly = _mealsPerDay(meals);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: FutureBuilder(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vue d\'ensemble',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppDimensions.paddingSm),
                    _StatLine(label: 'Utilisateurs inscrits',
                        value: '${stats.totalUsers}'),
                    _StatLine(label: 'Nutritionnistes',
                        value: '${stats.totalNutritionists}'),
                    _StatLine(label: 'Aliments au catalogue',
                        value: '${stats.totalFoods}'),
                    _StatLine(label: 'Catégories',
                        value: '${stats.totalCategories}'),
                    _StatLine(label: 'Repas enregistrés',
                        value: '${stats.mealsLogged}'),
                    _StatLine(label: 'Comptes utilisateurs actifs',
                        value: '${stats.activeToday}'),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repas des 7 derniers jours',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppDimensions.paddingMd),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final days =
                                      DateUtils.last7Days();
                                  final i = value.toInt();
                                  if (i < 0 || i >= days.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
                                    child: Text(
                                      DateUtils.shortDayLabel(
                                          days[i]),
                                      style: const TextStyle(
                                          fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0; i < weekly.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: weekly[i].toDouble(),
                                    width: 18,
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Répartition des comptes',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppDimensions.paddingSm),
                    _ShareBar(
                      label: 'Utilisateurs',
                      value: stats.totalUsers,
                      total:
                          stats.totalUsers + stats.totalNutritionists + 1,
                      color: AppColors.primary,
                    ),
                    _ShareBar(
                      label: 'Nutritionnistes',
                      value: stats.totalNutritionists,
                      total:
                          stats.totalUsers + stats.totalNutritionists + 1,
                      color: AppColors.carbs,
                    ),
                    _ShareBar(
                      label: 'Administrateurs',
                      value: 1,
                      total:
                          stats.totalUsers + stats.totalNutritionists + 1,
                      color: AppColors.proteins,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _statsFuture = AdminRepository.instance.statistics();
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Nombre de repas enregistrés pour chacun des 7 derniers jours.
  List<int> _mealsPerDay(List<MealModel> meals) {
    final days = DateUtils.last7Days();
    return [
      for (final day in days)
        meals
            .where((m) => DateUtils.isSameDay(m.date, day))
            .length,
    ];
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ShareBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ShareBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label ($value)',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('${(ratio * 100).round()} %',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
