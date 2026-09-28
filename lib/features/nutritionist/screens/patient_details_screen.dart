import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/recommendation_repository.dart';
import '../../../../data/repositories/weight_repository.dart';
import 'patient_journal_screen.dart';

/// Fiche d'un patient : profil, analyse, poids, actions.
class PatientDetailsScreen extends StatelessWidget {
  final UserModel user;

  const PatientDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final analysis = NutritionRepository.weeklyAnalysis(user.id);
    final weights = WeightRepository.instance.history(user.id);
    final latestWeight = weights.isEmpty ? null : weights.first;
    final bmi = latestWeight == null
        ? 0.0
        : NutritionCalculator.bmi(latestWeight.weightKg, user.heightCm);

    return Scaffold(
      appBar: AppBar(title: Text(user.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${user.email} • ${user.age} ans • '
                  '${user.heightCm.round()} cm • ${user.goalType.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(
                        label: 'Objectif : ${Formatters.kcal(user.calorieGoal)}'),
                    _Tag(label: 'Cible : ${Formatters.kg(user.targetWeightKg)}'),
                    if (latestWeight != null)
                      _Tag(
                          label:
                              'Poids : ${Formatters.kg(latestWeight.weightKg)}'),
                    if (bmi > 0)
                      _Tag(
                          label:
                              'IMC : ${bmi.toStringAsFixed(1)} (${NutritionCalculator.bmiCategory(bmi)})'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text('Analyse de la semaine',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.paddingSm),
          AppCard(
            child: Column(
              children: [
                _AnalysisRow(
                    label: 'Moyenne calorique',
                    value: Formatters.kcal(analysis.avgCalories),
                    color: AppColors.calories),
                _AnalysisRow(
                    label: 'Protéines',
                    value: Formatters.grams(analysis.avgProteins),
                    color: AppColors.proteins),
                _AnalysisRow(
                    label: 'Glucides',
                    value: Formatters.grams(analysis.avgCarbs),
                    color: AppColors.carbs),
                _AnalysisRow(
                    label: 'Lipides',
                    value: Formatters.grams(analysis.avgFats),
                    color: AppColors.fats),
                _AnalysisRow(
                    label: 'Jours journalisés',
                    value: '${analysis.loggedDays} / 7',
                    color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          AppButton(
            label: 'Consulter le journal',
            icon: Icons.menu_book_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => PatientJournalScreen(user: user)),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          AppSecondaryButton(
            label: 'Envoyer une recommandation',
            icon: Icons.send_outlined,
            onPressed: () => _sendRecommendation(context),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRecommendation(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle recommandation'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Conseil pour le patient'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      await RecommendationRepository.instance.add(
        userId: user.id,
        title: 'Conseil de votre nutritionniste',
        body: title,
        authorId: 'acc_demo_nutritionist',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recommandation envoyée')));
      }
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.primaryDark)),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AnalysisRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
    );
  }
}
