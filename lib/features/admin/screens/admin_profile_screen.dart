import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../../data/models/admin_model.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import 'admins_management_screen.dart';

/// Profil de l'administrateur et déconnexion.
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = auth.currentAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil administrateur')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          AppCard(
            child: Column(
              children: [
                PhotoPickerAvatar(
                  name: admin?.fullName.isNotEmpty == true
                      ? admin!.fullName
                      : auth.displayName,
                  photoUrl: admin?.photoUrl,
                  radius: 36,
                  onChanged: (value) => _savePhoto(context, admin, value),
                ),
                const SizedBox(height: 8),
                photoHintLabel(context),
                const SizedBox(height: AppDimensions.paddingSm),
                Text(admin?.fullName ?? auth.displayName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(admin?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppDimensions.paddingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    admin?.roleLabel ?? 'Administrateur',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          if (admin?.isSuperAdmin ?? false)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: AppDimensions.paddingSm),
              child: AppCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AdminsManagementScreen())),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.shield,
                        color: AppColors.primary),
                  ),
                  title: Text('Gestion des administrateurs'),
                  subtitle:
                      Text('Créer, promouvoir ou supprimer des comptes admin'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ),
          AppCard(
            onTap: () => _openPasswordSheet(context),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Icon(Icons.lock_outline, color: AppColors.primary),
              ),
              title: Text('Changer mon mot de passe'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          AppSecondaryButton(
            label: 'Se déconnecter',
            icon: Icons.logout,
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _savePhoto(
      BuildContext context, AdminModel? admin, String? value) async {
    if (admin == null || value == null) return;
    final updated = AdminModel(
      id: admin.id,
      email: admin.email,
      fullName: admin.fullName,
      role: admin.role,
      photoUrl: value.isEmpty ? null : value,
      createdAt: admin.createdAt,
    );
    await context.read<AuthProvider>().updateAdminProfile(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(value.isEmpty
                ? 'Photo supprimée'
                : 'Photo mise à jour')),
      );
    }
  }

  Future<void> _openPasswordSheet(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.paddingMd,
          right: AppDimensions.paddingMd,
          top: AppDimensions.paddingMd,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
              AppDimensions.paddingMd,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Changer le mot de passe',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.paddingMd),
              AppTextField(
                controller: currentController,
                label: 'Mot de passe actuel',
                obscureText: true,
                validator: Validators.required,
              ),
              AppTextField(
                controller: newController,
                label: 'Nouveau mot de passe',
                obscureText: true,
                validator: (v) => Validators.password(v),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              ElevatedButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final error = await context
                      .read<AuthProvider>()
                      .changePassword(currentController.text,
                          newController.text);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                    if (error != null) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text(error)));
                    } else {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Mot de passe mis à jour.')));
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
