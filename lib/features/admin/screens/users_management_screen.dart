import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../data/models/nutritionist_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/nutritionist_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../core/services/supabase_sync_service.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';

/// Gestion des comptes : onglets Utilisateurs et Nutritionnistes.
class UsersManagementScreen extends StatelessWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des comptes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Nutritionnistes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(),
            _NutritionistsTab(),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _query = '';

  List<UserModel> get _users {
    final q = _query.trim().toLowerCase();
    return UserRepository.instance.allUsers().where((u) {
      return q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = _users;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.primarySoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? const Center(child: Text('Aucun utilisateur trouvé.'))
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _AccountTile(
                    title: users[i].fullName,
                    subtitle: users[i].email,
                    initial: users[i].fullName.isNotEmpty
                        ? users[i].fullName[0].toUpperCase()
                        : '?',
                    trailing: users[i].emailVerified
                        ? const Icon(Icons.verified,
                            size: 18, color: AppColors.primary)
                        : null,
                    onTap: () => _showUserSheet(users[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showUserSheet(UserModel user) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(user.fullName),
              subtitle: Text(
                  '${user.age} ans • ${user.heightCm.round()} cm • '
                  'Objectif ${user.calorieGoal.round()} kcal'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Réinitialiser le mot de passe'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _resetPassword(user.id, user.email);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.error),
              title:
                  const Text('Supprimer le compte', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _deleteUser(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword(String accountId, String email) async {
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _PasswordDialog(email: email),
    );
    if (password == null || password.isEmpty) return;
    await AuthRepository.instance.changePassword(accountId, password);
    await _log('reset_password', email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mot de passe réinitialisé pour $email.')));
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce compte ?'),
        content: Text(
            'Le compte de ${user.fullName} (${user.email}) sera définitivement supprimé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthRepository.instance.deleteAccount(user.id);
    await _log('delete_user', user.email);
    if (mounted) setState(() {});
  }

  Future<void> _log(String action, String target) {
    final admin = context.read<AuthProvider>().currentAdmin;
    return AdminRepository.instance.log(
      actorId: admin?.id ?? 'admin',
      actorRole: 'admin',
      action: action,
      target: target,
    );
  }
}

class _NutritionistsTab extends StatefulWidget {
  const _NutritionistsTab();

  @override
  State<_NutritionistsTab> createState() => _NutritionistsTabState();
}

class _NutritionistsTabState extends State<_NutritionistsTab> {
  List<NutritionistModel> get _nutritionists =>
      NutritionistRepository.instance.all();

  Color _statusColor(NutritionistModel n) =>
      n.verificationStatus == VerificationStatus.verified
          ? AppColors.success
          : n.verificationStatus == VerificationStatus.rejected
              ? AppColors.error
              : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final list = _nutritionists;
    if (list.isEmpty) {
      return const Center(child: Text('Aucun nutritionniste inscrit.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMd),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final n = list[i];
        final color = _statusColor(n);
        return ListTile(
          onTap: () => _showDetails(n),
          leading: ProfileAvatar(name: n.fullName, photoUrl: n.photoUrl),
          title: Text(n.fullName),
          subtitle: Text('${n.email}\n'
              '${n.specialization} • ${n.patientIds.length} patient(s)'),
          isThreeLine: true,
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(n.verificationStatus.label,
                    style: TextStyle(
                        fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDetails(NutritionistModel n) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(name: n.fullName, photoUrl: n.photoUrl, radius: 26),
                  const SizedBox(width: AppDimensions.paddingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.fullName,
                            style: Theme.of(sheetContext).textTheme.titleLarge),
                        Text(n.email,
                            style: Theme.of(sheetContext).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              _DetailLine('Spécialisation', n.specialization),
              _DetailLine("N° d'agrément",
                  n.licenseNumber.isEmpty ? '—' : n.licenseNumber),
              _DetailLine('Téléphone', n.phone.isEmpty ? '—' : n.phone),
              _DetailLine('Ville', n.city.isEmpty ? '—' : n.city),
              _DetailLine("Années d'expérience", '${n.experienceYears}'),
              if (n.bio.isNotEmpty) _DetailLine('Présentation', n.bio),
              const SizedBox(height: AppDimensions.paddingSm),
              Text('Diplômes & attestations',
                  style: Theme.of(sheetContext).textTheme.titleSmall),
              const SizedBox(height: AppDimensions.paddingSm),
              if (n.diplomaUrls.isEmpty)
                const Text('Aucun document fourni.')
              else
                Wrap(
                  spacing: AppDimensions.paddingSm,
                  runSpacing: AppDimensions.paddingSm,
                  children: [
                    for (final u in n.diplomaUrls)
                      FoodThumb(imageUrl: u, emoji: '📄', size: 84),
                  ],
                ),
              const SizedBox(height: AppDimensions.paddingLg),
              if (!n.isVerified) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success),
                        icon: const Icon(Icons.check),
                        label: const Text('Valider'),
                        onPressed: () =>
                            Navigator.pop(sheetContext, 'verify'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSm),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error),
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                        onPressed: () =>
                            Navigator.pop(sheetContext, 'reject'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingSm),
              ] else
                OutlinedButton.icon(
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Retirer la vérification'),
                  onPressed: () => Navigator.pop(sheetContext, 'unverify'),
                ),
              const SizedBox(height: AppDimensions.paddingMd),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer le compte'),
                  onPressed: () => Navigator.pop(sheetContext, 'delete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case 'verify':
        await _setStatus(n, VerificationStatus.verified, null);
      case 'reject':
        await _reject(n);
      case 'unverify':
        await _setStatus(n, VerificationStatus.pending, null);
      case 'delete':
        await _deleteNutritionist(n);
    }
  }

  Future<void> _reject(NutritionistModel n) async {
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RejectDialog(),
    );
    if (note == null) return;
    await _setStatus(n, VerificationStatus.rejected, note);
  }

  Future<void> _setStatus(NutritionistModel n, VerificationStatus status,
      String? note) async {
    final admin = context.read<AuthProvider>().currentAdmin;
    n.verificationStatus = status;
    n.isVerified = status == VerificationStatus.verified;
    n.verificationNote = note;
    await NutritionistRepository.instance.save(n);
    await AdminRepository.instance.log(
      actorId: admin?.id ?? 'admin',
      actorRole: 'admin',
      action: 'review_nutritionist_${status.key}',
      target: n.email,
    );
    // Relit les profils distants : confirme que la validation est bien
    // partie vers Supabase et rafraîchit l'affichage avec la source réelle.
    try {
      await SupabaseSyncService.instance
          .pullForCurrentAccount(role: 'admin');
    } catch (_) {/* hors-ligne : le cache local reste la source affichée */}
    if (mounted) setState(() {});
  }

  Future<void> _deleteNutritionist(NutritionistModel n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce nutritionniste ?'),
        content: Text('${n.fullName} (${n.email}) sera définitivement supprimé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final admin = context.read<AuthProvider>().currentAdmin;
    await AuthRepository.instance.deleteAccount(n.id);
    await AdminRepository.instance.log(
      actorId: admin?.id ?? 'admin',
      actorRole: 'admin',
      action: 'delete_nutritionist',
      target: n.email,
    );
    if (mounted) setState(() {});
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motif du refus'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
            hintText: 'Ex. Diplôme illisible, merci de le renvoyer.'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        TextButton(
            onPressed: () =>
                Navigator.pop(context, _controller.text.trim()),
            child: const Text('Confirmer')),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String initial;
  final Widget? trailing;
  final VoidCallback onTap;

  const _AccountTile({
    required this.title,
    required this.subtitle,
    required this.initial,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        child: Text(initial,
            style: const TextStyle(color: AppColors.primaryDark)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  final String email;
  const _PasswordDialog({required this.email});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau mot de passe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pour ${widget.email}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppDimensions.paddingSm),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        TextButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Valider')),
      ],
    );
  }
}
