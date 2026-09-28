import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/weight_record_model.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';

/// Suivi du poids : graphique d'évolution + ajout de points.
class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  Future<void> _addRecord(BuildContext context) async {
    final app = context.read<AppProvider>();
    final controller =
        TextEditingController(text: app.currentWeight.toStringAsFixed(1));
    final kg = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Nouveau poids'),
          content: Form(
            key: formKey,
            child: AppTextField(
              controller: controller,
              label: 'Poids (kg)',
              icon: Icons.speed,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.weight,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler')),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext,
                      double.parse(controller.text.trim()));
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
    if (kg != null) await app.addWeight(kg);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final history = app.weightHistory.reversed.toList();
    final user = app.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi du poids')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRecord(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                      label: 'Actuel',
                      value: Formatters.kg(app.currentWeight)),
                ),
                Expanded(
                  child: _Stat(
                      label: 'Objectif',
                      value: Formatters.kg(user?.targetWeightKg ?? 0)),
                ),
                Expanded(
                  child: _Stat(
                    label: 'IMC',
                    value: app.currentBmi.toStringAsFixed(1),
                    sub: NutritionCalculator.bmiCategory(app.currentBmi),
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
                Text('Évolution',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimensions.paddingMd),
                SizedBox(
                  height: 200,
                  child: history.length < 2
                      ? const Center(
                          child: Text(
                              'Ajoutez au moins 2 mesures pour voir la courbe.'))
                      : LineChart(LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                  show: true, color: AppColors.chartFill),
                              spots: List.generate(history.length, (i) {
                                return FlSpot(
                                  i.toDouble(),
                                  history[i].weightKg,
                                );
                              }),
                            ),
                          ],
                        )),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text('Historique',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.paddingSm),
          ...history.reversed.map((WeightRecordModel w) => Card(
                child: ListTile(
                  leading: const Icon(Icons.scale_outlined),
                  title: Text(Formatters.kg(w.weightKg)),
                  subtitle: Text(DateUtils.dateLabel(w.date)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.textHint),
                    onPressed: () => app.deleteWeight(w.id),
                  ),
                ),
              )),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
              child: Text('Aucune mesure enregistrée.'),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _Stat({required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        if (sub != null)
          Text(sub!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
