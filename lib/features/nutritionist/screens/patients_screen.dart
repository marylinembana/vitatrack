import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import 'patient_details_screen.dart';

/// Liste complète des patients suivis par le nutritionniste.
class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nutritionist = auth.currentNutritionist;
    final patients = <UserModel>[];
    if (nutritionist != null) {
      for (final id in nutritionist.patientIds) {
        final u = UserRepository.instance.byId(id);
        if (u != null) patients.add(u);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes patients')),
      body: patients.isEmpty
          ? const EmptyState(
              icon: Icons.groups,
              title: 'Aucun patient',
              message: 'Les utilisateurs que vous suivez apparaîtront ici.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: patients.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSm),
              itemBuilder: (context, i) {
                final p = patients[i];
                return AppCard(
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
                            Text(
                              '${p.goalType.label} • cible ${p.targetWeightKg.round()} kg',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
