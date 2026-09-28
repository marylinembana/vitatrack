import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../data/models/admin_model.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';

/// Gestion des administrateurs — réservée au super administrateur :
/// création, promotion/rétrogradation et suppression de comptes admin.
class AdminsManagementScreen extends StatefulWidget {
  const AdminsManagementScreen({super.key});

  @override
  State<AdminsManagementScreen> createState() =>
      _AdminsManagementScreenState();
}

class _AdminsManagementScreenState extends State<AdminsManagementScreen> {
  final _repo = AdminRepository.instance;

  void _reload() => setState(() {});

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateSheet() async {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passwordC = TextEditingController();
    var role = 'admin';
    final formKey = GlobalKey<FormState>();
    final actorId = context.read<AuthProvider>().account?.id ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
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
                Text('Nouvel administrateur',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: AppDimensions.paddingMd),
                AppTextField(
                  controller: nameC,
                  label: 'Nom complet',
                  icon: Icons.person_outline,
                  validator: (v) => Validators.required(v, field: 'Le nom'),
                ),
                AppTextField(
                  controller: emailC,
                  label: 'E-mail',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                AppTextField(
                  controller: passwordC,
                  label: 'Mot de passe provisoire',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => Validators.password(v),
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                Row(
                  children: [
                    Expanded(
                      child: _RoleChip(
                        label: 'Administrateur',
                        selected: role == 'admin',
                        onTap: () => setSheet(() => role = 'admin'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleChip(
                        label: 'Super administrateur',
                        selected: role == 'super_admin',
                        onTap: () =>
                            setSheet(() => role = 'super_admin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final error = await _repo.createAdmin(
                      fullName: nameC.text,
                      email: emailC.text,
                      password: passwordC.text,
                      role: role,
                      actorId: actorId,
                    );
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    if (!mounted) return;
                    if (error != null) {
                      _toast(error);
                    } else {
                      _toast('Compte administrateur créé.');
                      _reload();
                    }
                  },
                  child: const Text('Créer le compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleRole(AdminModel admin) async {
    final current = context.read<AuthProvider>();
    final newRole = admin.isSuperAdmin ? 'admin' : 'super_admin';
    final error = await _repo.setAdminRole(
      targetId: admin.id,
      newRole: newRole,
      actorId: current.account?.id ?? '',
      actorIsSuperAdmin: current.currentAdmin?.isSuperAdmin ?? false,
    );
    if (!mounted) return;
    if (error != null) {
      _toast(error);
    } else {
      _toast('${admin.fullName} est désormais ${newRole == 'super_admin' ? 'super administrateur' : 'administrateur'}.');
      _reload();
    }
  }

  Future<void> _confirmDelete(AdminModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce compte ?'),
        content: Text(
            'Le compte « ${admin.fullName} » (${admin.email}) sera définitivement supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final current = context.read<AuthProvider>();
    final error = await _repo.deleteAdmin(
      targetId: admin.id,
      actorId: current.account?.id ?? '',
    );
    if (!mounted) return;
    if (error != null) {
      _toast(error);
    } else {
      _toast('Compte supprimé.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.currentAdmin;
    if (me == null || !me.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administrateurs')),
        body: EmptyState(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Accès restreint',
          message:
              'Seul le super administrateur peut gérer les comptes '
              'd\'administrateurs.',
        ),
      );
    }
    final admins = _repo.admins();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Ajouter un administrateur',
            onPressed: _openCreateSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nouvel admin'),
      ),
      body: admins.isEmpty
          ? const EmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Aucun administrateur',
              message: 'Créez un premier compte administrateur.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              children: [
                Text(
                  'Le super administrateur peut promouvoir ou rétrograder '
                  'des comptes, et ne peut jamais supprimer le dernier '
                  'super administrateur.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                for (final admin in admins)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.paddingSm),
                    child: _AdminCard(
                      admin: admin,
                      isMe: admin.id == me.id,
                      onToggleRole: () => _toggleRole(admin),
                      onDelete: () => _confirmDelete(admin),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final AdminModel admin;
  final bool isMe;
  final VoidCallback onToggleRole;
  final VoidCallback onDelete;

  const _AdminCard({
    required this.admin,
    required this.isMe,
    required this.onToggleRole,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          ProfileAvatar(
            name: admin.fullName,
            photoUrl: admin.photoUrl,
            radius: 24,
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${admin.fullName}${isMe ? ' (vous)' : ''}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(admin.email,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: admin.isSuperAdmin
                        ? AppColors.accentSoft
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    admin.roleLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: admin.isSuperAdmin
                          ? AppColors.textPrimary
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: admin.isSuperAdmin
                ? 'Rétrograder en administrateur'
                : 'Promouvoir super administrateur',
            icon: Icon(
              admin.isSuperAdmin
                  ? Icons.shield_outlined
                  : Icons.shield,
              color: AppColors.primary,
            ),
            onPressed: isMe ? null : onToggleRole,
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: isMe ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
