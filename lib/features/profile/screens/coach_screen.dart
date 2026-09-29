import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/services/supabase_bootstrap.dart';
import '../../../../core/services/supabase_sync_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../data/models/nutritionist_model.dart';
import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/nutritionist_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import '../../messaging/screens/chat_screen.dart';

/// « Mon coach » : le patient voit le nutritionniste qu'il a choisi et peut
/// discuter avec lui. Sans coach, il est invité à en choisir un parmi les
/// nutritionnistes **vérifiés**.
class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  Future<void> _openChat(BuildContext context, String nutritionistId) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.account?.id;
    if (uid == null) return;
    final conv = await MessageRepository.instance.openConversation(
      userId: uid,
      nutritionistId: nutritionistId,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conv)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final coachId = auth.account?.profile['nutritionistId'] as String?;
    final coach = coachId == null
        ? null
        : NutritionistRepository.instance.byIdOrNull(coachId);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon coach')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          if (coach == null)
            EmptyState(
              icon: Icons.person_search_outlined,
              title: 'Aucun coach choisi',
              message:
                  'Choisissez un nutritionniste vérifié pour recevoir des '
                  'conseils personnalisés et discuter avec lui.',
              actionLabel: 'Choisir un coach',
              onAction: () =>
                  Navigator.of(context).pushNamed('/coach/choose'),
            )
          else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProfileAvatar(
                          name: coach.fullName,
                          photoUrl: coach.photoUrl,
                          radius: 30),
                      const SizedBox(width: AppDimensions.paddingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(coach.fullName.isEmpty
                                ? 'Coach'
                                : coach.fullName),
                            Text(
                              coach.specialization,
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const _VerifiedBadge(),
                    ],
                  ),
                  if (coach.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.paddingMd),
                    Text(coach.bio,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: AppDimensions.paddingSm),
                  _CoachMeta(coach: coach),
                  const SizedBox(height: AppDimensions.paddingMd),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Discuter',
                          icon: Icons.chat_bubble_outline,
                          onPressed: () =>
                              _openChat(context, coach.id),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingSm),
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Changer de coach',
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed('/coach/choose'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMd),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/messaging'),
                icon: const Icon(Icons.forum_outlined, size: 18),
                label: const Text('Voir toutes mes conversations'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Liste des nutritionnistes vérifiés ; le patient en choisit un comme coach,
/// puis accède directement à la discussion.
class NutritionistPickerScreen extends StatefulWidget {
  const NutritionistPickerScreen({super.key});

  @override
  State<NutritionistPickerScreen> createState() =>
      _NutritionistPickerScreenState();
}

class _NutritionistPickerScreenState extends State<NutritionistPickerScreen> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    // Le patient n'a pas forcément les nutritionnistes en cache : on relance
    // un pull (parallèle, rapide) pour rafraîchir la liste après le RLS.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!SupabaseBootstrap.ready) return;
    final role = context.read<AuthProvider>().role;
    setState(() => _refreshing = true);
    await SupabaseSyncService.instance.pullForCurrentAccount(role: role);
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _choose(NutritionistModel n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir ce coach ?'),
        content: Text(
            'Vous serez mis en relation avec ${n.fullName} et pourrez '
            'discuter avec lui.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Choisir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final uid = auth.account?.id;
    if (uid == null) return;
    await auth.assignNutritionist(n.id);
    final conv = await MessageRepository.instance.openConversation(
        userId: uid, nutritionistId: n.id);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentId = auth.account?.profile['nutritionistId'] as String?;
    final coaches = NutritionistRepository.instance.verified()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un coach'),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: coaches.isEmpty
          ? const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Aucun nutritionniste disponible',
              message:
                  'Aucun compte nutritionniste vérifié pour le moment. '
                  'Réessayez plus tard.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              itemCount: coaches.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.paddingSm),
              itemBuilder: (context, i) {
                final n = coaches[i];
                final isCurrent = n.id == currentId;
                return AppCard(
                  onTap: () => _choose(n),
                  child: Row(
                    children: [
                      ProfileAvatar(
                          name: n.fullName, photoUrl: n.photoUrl, radius: 28),
                      const SizedBox(width: AppDimensions.paddingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.fullName.isEmpty ? 'Coach' : n.fullName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              [
                                n.specialization,
                                if (n.city.trim().isNotEmpty) n.city,
                              ].join(' • '),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            if (n.experienceYears > 0)
                              Text(
                                '${n.experienceYears} ans d\'expérience',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrent)
                        const Text('Actuel',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))
                      else
                        const Icon(Icons.chevron_right,
                            color: AppColors.textHint),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Badgée « Vérifié » affichée à côté du nom d'un nutritionniste validé.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: AppColors.primaryDark),
          SizedBox(width: 4),
          Text('Vérifié',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CoachMeta extends StatelessWidget {
  final NutritionistModel coach;
  const _CoachMeta({required this.coach});

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      if (coach.city.trim().isNotEmpty) coach.city,
      if (coach.experienceYears > 0) '${coach.experienceYears} ans d\'expérience',
      if (coach.phone.trim().isNotEmpty) coach.phone,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items
          .map((t) => Text(t,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)))
          .toList(),
    );
  }
}
