import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/models/nutritionist_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/nutritionist_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import 'patient_details_screen.dart';

/// Tableau de bord du nutritionniste : résumé + activité récente.
class NutritionistDashboardScreen extends StatelessWidget {
  const NutritionistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nutritionist = auth.currentNutritionist;
    if (nutritionist == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }
    final patients = _patients(nutritionist);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          Text('Bonjour, ${nutritionist.fullName} 👋',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppDimensions.paddingLg),
          Row(
            children: [
              _StatCard(
                  label: 'Patients',
                  value: '${patients.length}',
                  icon: Icons.groups,
                  color: AppColors.primary),
              const SizedBox(width: AppDimensions.paddingSm),
              _StatCard(
                  label: 'Plans actifs',
                  value: '${patients.length}',
                  icon: Icons.restaurant_menu,
                  color: AppColors.accent),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Text('Mes patients',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.paddingSm),
          if (patients.isEmpty)
            const AppCard(
                child: Text('Aucun patient pour le moment.'))
          else
            ...patients.map((p) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDimensions.paddingSm),
                  child: AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => PatientDetailsScreen(user: p)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            p.fullName.isNotEmpty ? p.fullName[0] : '?',
                            style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.fullName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(p.email,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  List<UserModel> _patients(NutritionistModel nutritionist) {
    final repo = UserRepository.instance;
    final nutRepo = NutritionistRepository.instance;
    final fresh = nutRepo.byIdOrNull(nutritionist.id);
    final ids = fresh?.patientIds ?? nutritionist.patientIds;
    return ids
        .map((id) => repo.byId(id))
        .whereType<UserModel>()
        .toList();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppDimensions.paddingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
