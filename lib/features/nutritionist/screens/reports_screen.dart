import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/weight_record_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/repositories/weight_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';

/// Rapports de suivi hebdomadaires des patients du nutritionniste.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedPatientId;

  List<UserModel> get _patients {
    final nutritionist = context.read<AuthProvider>().currentNutritionist;
    if (nutritionist == null) return [];
    return nutritionist.patientIds
        .map((id) => UserRepository.instance.byId(id))
        .whereType<UserModel>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final patients = _patients;
    if (patients.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Rapports de suivi')),
        body: const EmptyState(
          icon: Icons.insert_chart_outlined,
          title: 'Aucun rapport',
          message: 'Ajoutez des patients pour générer des rapports.',
        ),
      );
    }

    final patient = patients.firstWhere(
      (p) => p.id == _selectedPatientId,
      orElse: () => patients.first,
    );
    final analysis = NutritionRepository.weeklyAnalysis(patient.id);
    final dailyCalories = NutritionRepository.weeklyCaloriesByDay(patient.id);
    final weights = WeightRepository.instance.history(patient.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rapports de suivi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppDimensions.paddingMd,
            AppDimensions.paddingSm, AppDimensions.paddingMd,
            AppDimensions.paddingXl),
        children: [
          _PatientSelector(
            patients: patients,
            selected: patient,
            onSelect: (id) => setState(() => _selectedPatientId = id),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          _PatientHeroCard(
            patient: patient,
            loggedDays: analysis.loggedDays,
            avgCalories: analysis.avgCalories,
          ),
          const SectionHeader(
              title: 'Adhésion à l\'objectif',
              padding: EdgeInsets.only(
                  top: AppDimensions.paddingLg,
                  bottom: AppDimensions.paddingSm)),
          AppCard(
            child: _AdherenceBar(
                avgCalories: analysis.avgCalories,
                goalCalories: patient.calorieGoal),
          ),
          const SectionHeader(
              title: 'Répartition des macros (moyenne / jour)',
              padding: EdgeInsets.only(
                  top: AppDimensions.paddingLg,
                  bottom: AppDimensions.paddingSm)),
          AppCard(
            child: _MacroDonut(
              proteins: analysis.avgProteins,
              carbs: analysis.avgCarbs,
              fats: analysis.avgFats,
            ),
          ),
          const SectionHeader(
              title: 'Calories des 7 derniers jours',
              padding: EdgeInsets.only(
                  top: AppDimensions.paddingLg,
                  bottom: AppDimensions.paddingSm)),
          AppCard(
            child: _CaloriesBarChart(daily: dailyCalories, goal: patient.calorieGoal),
          ),
          const SectionHeader(
              title: 'Évolution du poids',
              padding: EdgeInsets.only(
                  top: AppDimensions.paddingLg,
                  bottom: AppDimensions.paddingSm)),
          AppCard(
            child: weights.length < 2
                ? const _SmallHint(
                    'Pas assez de pesées pour afficher une courbe.')
                : _WeightLineChart(weights: weights),
          ),
          if (weights.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.paddingSm),
              child: Text(
                'Variation : ${Formatters.kg(_weightDelta(weights))} '
                'sur ${weights.length} pesées',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppDimensions.paddingLg),
          _DetailsCard(analysis: analysis, patient: patient),
        ],
      ),
    );
  }

  double _weightDelta(List<WeightRecordModel> weights) {
    final chronological = weights.reversed.toList();
    return chronological.last.weightKg - chronological.first.weightKg;
  }
}

/// Sélecteur de patient horizontal (puces) pour un accès rapide.
class _PatientSelector extends StatelessWidget {
  final List<UserModel> patients;
  final UserModel selected;
  final ValueChanged<String> onSelect;

  const _PatientSelector({
    required this.patients,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: patients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = patients[i];
          final isSel = p.id == selected.id;
          return ChoiceChip(
            selected: isSel,
            onSelected: (_) => onSelect(p.id),
            showCheckmark: false,
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            side: BorderSide(
                color: isSel ? AppColors.primary : AppColors.divider),
            label: Text(
              p.fullName.split(RegExp(r'\s+')).first,
              style: TextStyle(
                  color: isSel ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}

/// Bandeau résumant le patient et sa régularité cette semaine.
class _PatientHeroCard extends StatelessWidget {
  final UserModel patient;
  final int loggedDays;
  final double avgCalories;

  const _PatientHeroCard({
    required this.patient,
    required this.loggedDays,
    required this.avgCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            photoUrl: patient.photoUrl,
            name: patient.fullName,
            radius: 28,
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text('Semaine du ${DateUtils.dateLabel(_weekStart())}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$loggedDays / 7 j',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text('journalisés',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _weekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }
}

/// Barre d'adhésion à l'objectif calorique avec pourcentage.
class _AdherenceBar extends StatelessWidget {
  final double avgCalories;
  final double goalCalories;

  const _AdherenceBar({
    required this.avgCalories,
    required this.goalCalories,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = goalCalories <= 0
        ? 0.0
        : (avgCalories / goalCalories).clamp(0.0, 1.5).toDouble();
    final percent = (ratio * 100).round();
    final isGood = avgCalories <= goalCalories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isGood ? Icons.trending_down : Icons.trending_up,
              color: isGood ? AppColors.success : AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${Formatters.kcal(avgCalories)} / ${Formatters.kcal(goalCalories)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text('$percent %',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isGood ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(
                isGood ? AppColors.success : AppColors.warning),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isGood
              ? 'Moyenne sous l\'objectif — bonne adhésion.'
              : 'Moyenne au-dessus de l\'objectif — à surveiller.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SmallHint extends StatelessWidget {
  final String text;
  const _SmallHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMd),
      child: Text(text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

/// Donut de répartition des macros (en kcal issues de chaque macro).
class _MacroDonut extends StatelessWidget {
  final double proteins;
  final double carbs;
  final double fats;

  const _MacroDonut({
    required this.proteins,
    required this.carbs,
    required this.fats,
  });

  @override
  Widget build(BuildContext context) {
    final pKcal = proteins * 4;
    final cKcal = carbs * 4;
    final fKcal = fats * 9;
    final total = pKcal + cKcal + fKcal;

    if (total <= 0) {
      return const _SmallHint('Aucune donnée cette semaine.');
    }

    return Row(
      children: [
        SizedBox(
          height: 150,
          width: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 38,
              startDegreeOffset: -90,
              sections: [
                _section(pKcal, AppColors.proteins),
                _section(cKcal, AppColors.carbs),
                _section(fKcal, AppColors.fats),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend(
                  color: AppColors.proteins,
                  label: 'Protéines',
                  grams: proteins,
                  percent: pKcal / total),
              _Legend(
                  color: AppColors.carbs,
                  label: 'Glucides',
                  grams: carbs,
                  percent: cKcal / total),
              _Legend(
                  color: AppColors.fats,
                  label: 'Lipides',
                  grams: fats,
                  percent: fKcal / total),
            ],
          ),
        ),
      ],
    );
  }

  PieChartSectionData _section(double value, Color color) {
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 26,
      showTitle: false,
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final double grams;
  final double percent;

  const _Legend({
    required this.color,
    required this.label,
    required this.grams,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text('${(percent * 100).round()} %',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(Formatters.grams(grams),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Histogramme des calories par jour avec repère d'objectif.
class _CaloriesBarChart extends StatelessWidget {
  final List<({DateTime day, double calories})> daily;
  final double goal;

  const _CaloriesBarChart({required this.daily, required this.goal});

  @override
  Widget build(BuildContext context) {
    final maxCal =
        daily.map((e) => e.calories).fold<double>(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (math.max(maxCal, goal) * 1.25).clamp(1000, 5000),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goal,
                color: AppColors.textHint,
                strokeWidth: 1,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                  labelResolver: (_) => 'Objectif',
                ),
              ),
            ],
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${DateUtils.shortDayLabel(daily[group.x].day)}\n'
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
                  if (i < 0 || i >= daily.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateUtils.shortDayLabel(daily[i].day)[0],
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(daily.length, (i) {
            final isToday = i == daily.length - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: daily[i].calories,
                  width: 20,
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
    );
  }
}

/// Courbe d'évolution du poids (axe des jours, points espacés).
class _WeightLineChart extends StatelessWidget {
  final List<WeightRecordModel> weights;
  const _WeightLineChart({required this.weights});

  @override
  Widget build(BuildContext context) {
    final chronological = weights.reversed.toList();
    final first = chronological.first.date;
    final spots = [
      for (final w in chronological)
        FlSpot(w.date.difference(first).inDays.toDouble(), w.weightKg),
    ];
    final minY =
        chronological.map((w) => w.weightKg).reduce(math.min) - 1;
    final maxY =
        chronological.map((w) => w.weightKg).reduce(math.max) + 1;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: spots.length > 1
                    ? (spots.last.x - spots.first.x) / 3
                    : 1,
                getTitlesWidget: (value, _) {
                  final day = first.add(Duration(days: value.round()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateUtils.shortDayLabel(day),
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spot) => [
                for (final s in spot)
                  LineTooltipItem(
                    '${s.y.toStringAsFixed(1)} kg',
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Récapitulatif chiffré sous les graphiques.
class _DetailsCard extends StatelessWidget {
  final ({
    double avgCalories,
    double avgProteins,
    double avgCarbs,
    double avgFats,
    int loggedDays,
  }) analysis;
  final UserModel patient;

  const _DetailsCard({required this.analysis, required this.patient});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _Row(label: 'Calories moyennes / jour',
              value: Formatters.kcal(analysis.avgCalories),
              color: AppColors.calories),
          _Row(label: 'Protéines moyennes',
              value: Formatters.grams(analysis.avgProteins),
              color: AppColors.proteins),
          _Row(label: 'Glucides moyens',
              value: Formatters.grams(analysis.avgCarbs),
              color: AppColors.carbs),
          _Row(label: 'Lipides moyens',
              value: Formatters.grams(analysis.avgFats),
              color: AppColors.fats),
          _Row(label: 'Objectif calorique',
              value: Formatters.kcal(patient.calorieGoal),
              color: AppColors.primary,
              isLast: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _Row({
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppDimensions.paddingSm),
              Expanded(child: Text(label)),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
