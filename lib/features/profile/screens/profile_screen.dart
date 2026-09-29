import 'package:flutter/material.dart' hide DateUtils;
import 'package:provider/provider.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/models/food_model.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import '../../dashboard/user_dashboard/controllers/app_provider.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

/// Profil utilisateur : en-tête, stats, accès rapides, favoris, déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    final bmi = app.currentBmi;
    final bmiLabel = NutritionCalculator.bmiCategory(bmi);
    final favorites = app.favorites;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Mon profil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _HeaderCard(
                name: user.fullName,
                email: user.email,
                photoUrl: user.photoUrl,
                goalLabel: user.goalType.label,
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingMd, 0, AppDimensions.paddingMd, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsRow(
                      bmi: bmi,
                      bmiLabel: bmiLabel,
                      weightKg: app.currentWeight,
                      calorieGoal: user.calorieGoal,
                      age: user.age,
                    ),
                    const SizedBox(height: AppDimensions.paddingLg),
                    const SectionHeader(title: 'Mes informations'),
                    AppCard(
                      child: Column(
                        children: [
                          _InfoRow(
                              icon: Icons.straighten,
                              label: 'Taille',
                              value:
                                  '${user.heightCm.toStringAsFixed(0)} cm'),
                          _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Âge',
                              value: '${user.age} ans'),
                          _InfoRow(
                              icon: Icons.flag_outlined,
                              label: 'Objectif',
                              value: user.goalType.label),
                          _InfoRow(
                              icon: Icons.speed,
                              label: 'Poids cible',
                              value: Formatters.kg(user.targetWeightKg)),
                          _InfoRow(
                              icon: Icons.local_fire_department_outlined,
                              label: 'Objectif calorique',
                              value: Formatters.kcal(user.calorieGoal),
                              isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    const SectionHeader(title: 'Accès rapides'),
                    _QuickActionTile(
                      icon: Icons.flag,
                      color: AppColors.primary,
                      title: 'Mon objectif nutritionnel',
                      subtitle: 'Ajuster calories & macros',
                      onTap: () => Navigator.of(context).pushNamed('/goals'),
                    ),
                    _QuickActionTile(
                      icon: Icons.monitor_weight_outlined,
                      color: AppColors.proteins,
                      title: 'Suivi du poids',
                      subtitle: 'Historique et évolution',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/weight'),
                    ),
                    _QuickActionTile(
                      icon: Icons.co_present_outlined,
                      color: AppColors.carbs,
                      title: 'Mon coach',
                      subtitle: 'Choisir un nutritionniste et discuter',
                      onTap: () => Navigator.of(context).pushNamed('/coach'),
                    ),
                    _QuickActionTile(
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.primary,
                      title: 'Mes messages',
                      subtitle: 'Historique des conversations',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/messaging'),
                    ),
                    _QuickActionTile(
                      icon: Icons.notifications_none,
                      color: AppColors.fats,
                      title: 'Notifications & rappels',
                      subtitle: 'Ne rien manquer de mon suivi',
                      onTap: () => Navigator.of(context)
                          .pushNamed('/notifications'),
                    ),
                    if (favorites.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.paddingLg),
                      SectionHeader(
                        title: 'Mes aliments favoris',
                        actionLabel: 'Voir tout',
                        onAction: () =>
                            Navigator.of(context).pushNamed('/foods'),
                      ),
                      SizedBox(
                        height: 128,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: favorites.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) =>
                              _FavoriteChip(food: favorites[i]),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.paddingLg),
                    _QuickActionTile(
                      icon: Icons.logout,
                      color: AppColors.error,
                      title: 'Se déconnecter',
                      subtitle: null,
                      onTap: () => _logout(context),
                    ),
                    const SizedBox(height: AppDimensions.paddingMd),
                    Center(
                      child: Text(
                        '${AppConstants.appName} v1.0.0 — mode démo local',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXl),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// En-tête avec avatar, nom, e-mail, objectif et bouton "Modifier".
class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final String goalLabel;
  final VoidCallback onEdit;

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.goalLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppDimensions.paddingMd, AppDimensions.paddingMd,
          AppDimensions.paddingMd, 0),
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
          ProfileAvatar(photoUrl: photoUrl, name: name, radius: 34),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Profil' : name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold)),
                Text(email,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(goalLabel,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Modifier',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// 4 indicateurs clés sous l'en-tête.
class _StatsRow extends StatelessWidget {
  final double bmi;
  final String bmiLabel;
  final double weightKg;
  final double calorieGoal;
  final int age;

  const _StatsRow({
    required this.bmi,
    required this.bmiLabel,
    required this.weightKg,
    required this.calorieGoal,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _Stat(
                icon: Icons.speed,
                value: bmi.toStringAsFixed(1),
                caption: bmiLabel,
                color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child: _Stat(
                icon: Icons.monitor_weight_outlined,
                value: '${weightKg.toStringAsFixed(0)} kg',
                caption: 'Poids actuel',
                color: AppColors.proteins)),
        const SizedBox(width: 10),
        Expanded(
            child: _Stat(
                icon: Icons.local_fire_department_outlined,
                value: '${calorieGoal.round()}',
                caption: 'kcal / jour',
                color: AppColors.carbs)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String caption;
  final Color color;

  const _Stat({
    required this.icon,
    required this.value,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Text(caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.bodyMedium)),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

/// Ligne d'action navigable (objectif, poids, messages, etc.).
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// Petite carte verticale pour un aliment favori.
class _FavoriteChip extends StatelessWidget {
  final FoodModel food;
  const _FavoriteChip({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FoodThumb(imageUrl: food.imageUrl, emoji: food.emoji),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              food.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
