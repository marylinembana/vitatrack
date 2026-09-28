import 'package:flutter/material.dart' hide DateUtils;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../data/models/admin_model.dart';
import '../../../../data/repositories/admin_repository.dart';

/// Journal des activités de la plateforme (admin).
class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  List<ActivityLogModel> _logs = AdminRepository.instance.logs();

  static const _labels = <String, String>{
    'create_user': 'Création d\'un compte',
    'delete_user': 'Suppression d\'un compte',
    'reset_password': 'Réinitialisation de mot de passe',
    'verify_nutritionist': 'Vérification d\'un nutritionniste',
    'unverify_nutritionist': 'Retrait de vérification',
    'delete_nutritionist': 'Suppression d\'un nutritionniste',
    'create_food': 'Ajout d\'un aliment',
    'update_food': 'Modification d\'un aliment',
    'delete_food': 'Suppression d\'un aliment',
    'activate_food': 'Activation d\'un aliment',
    'deactivate_food': 'Désactivation d\'un aliment',
    'create_category': 'Ajout d\'une catégorie',
    'update_category': 'Modification d\'une catégorie',
    'delete_category': 'Suppression d\'une catégorie',
  };

  IconData _iconFor(String action) {
    if (action.contains('delete')) return Icons.delete_outline;
    if (action.contains('create')) return Icons.add_circle_outline;
    if (action.contains('update')) return Icons.edit_outlined;
    if (action.contains('password')) return Icons.lock_reset;
    if (action.contains('verify')) return Icons.verified_outlined;
    if (action.contains('activate')) return Icons.toggle_on;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal des activités'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(
                () => _logs = AdminRepository.instance.logs()),
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'Aucune activité',
              message:
                  'Les actions administratives apparaîtront ici.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: _logs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSm),
              itemBuilder: (context, i) {
                final log = _logs[i];
                return AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(_iconFor(log.action),
                          size: 20, color: AppColors.primary),
                    ),
                    title: Text(_labels[log.action] ?? log.action),
                    subtitle: Text(
                        '${log.target.isEmpty ? '—' : log.target}\n'
                        '${DateUtils.dateLabel(log.createdAt)} '
                        'à ${DateUtils.timeLabel(log.createdAt)}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
