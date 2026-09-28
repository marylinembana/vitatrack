import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../data/repositories/admin_repository.dart';
import '../../authentication/presentation/controllers/auth_provider.dart';
import 'admins_management_screen.dart';
import 'categories_management_screen.dart';
import 'foods_management_screen.dart';

/// Tableau de bord de l'administrateur : chiffres clés + accès aux gestions.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<({int totalUsers, int totalNutritionists, int totalFoods,
      int totalCategories, int mealsLogged, int activeToday})> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminRepository.instance.statistics();
  }

  void _reloadStats() {
    setState(() {
      _statsFuture = AdminRepository.instance.statistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadStats,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMd),
            children: [
              Text('Bonjour ${auth.displayName} 👋',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.paddingSm),
              Text('Voici l\'état de la plateforme VitaTrack.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppDimensions.paddingMd),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Utilisateurs',
                      value: '${stats.totalUsers}',
                      icon: Icons.people,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Expanded(
                    child: _StatTile(
                      label: 'Nutritionnistes',
                      value: '${stats.totalNutritionists}',
                      icon: Icons.local_hospital,
                      color: AppColors.carbs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Aliments',
                      value: '${stats.totalFoods}',
                      icon: Icons.eco,
                      color: AppColors.proteins,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingSm),
                  Expanded(
                    child: _StatTile(
                      label: 'Repas enregistrés',
                      value: '${stats.mealsLogged}',
                      icon: Icons.restaurant,
                      color: AppColors.calories,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              Text('Gestions',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppDimensions.paddingSm),
              AppCard(
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          const FoodsManagementScreen(onChanged: null)));
                  _reloadStats();
                },
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.eco, color: AppColors.primary),
                  ),
                  title: Text('Gestion des aliments'),
                  subtitle: Text('Ajouter, modifier, activer ou supprimer'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              AppCard(
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CategoriesManagementScreen()));
                  _reloadStats();
                },
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child:
                        Icon(Icons.category, color: AppColors.primary),
                  ),
                  title: Text('Gestion des catégories'),
                  subtitle: Text('Organiser les familles d\'aliments'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              AppCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const FoodsManagementScreen(
                        onChanged: null, includeInactive: true))),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.inventory_2,
                        color: AppColors.primary),
                  ),
                  title: Text('Catalogue complet'),
                  subtitle:
                      Text('Inclure les aliments désactivés'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              if (auth.currentAdmin?.isSuperAdmin ?? false) ...[
                const SizedBox(height: AppDimensions.paddingSm),
                AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AdminsManagementScreen())),
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentSoft,
                      child: Icon(Icons.shield,
                          color: AppColors.primaryDark),
                    ),
                    title: Text('Gestion des administrateurs'),
                    subtitle: Text(
                        'Super administrateur — créer, promouvoir, supprimer'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
