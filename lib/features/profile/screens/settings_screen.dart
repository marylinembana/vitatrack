import 'package:flutter/material.dart';

import '../../../../core/services/firebase_bootstrap.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/services/local_store.dart';
import '../../../../core/widgets/app_card.dart';

/// Paramètres : rappels de repas, objectif d'eau, notifications.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kReminders = 'vitatrack_setting_reminders';
  static const _kWater = 'vitatrack_setting_water';
  static const _kWeekly = 'vitatrack_setting_weekly_report';

  bool _reminders = true;
  bool _water = true;
  bool _weekly = false;

  @override
  void initState() {
    super.initState();
    final store = LocalStore.instance;
    _reminders = store.readString(_kReminders) != 'off';
    _water = store.readString(_kWater) != 'off';
    _weekly = store.readString(_kWeekly) == 'on';
  }

  Future<void> _set(String key, bool value) =>
      LocalStore.instance.writeString(key, value ? 'on' : 'off');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        children: [
          Text('Notifications',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.paddingSm),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: _reminders,
                  activeColor: AppColors.primary,
                  title: const Text('Rappels des repas'),
                  subtitle: const Text(
                      'Petit-déjeuner, déjeuner, dîner et collation'),
                  onChanged: (v) {
                    setState(() => _reminders = v);
                    _set(_kReminders, v);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  value: _water,
                  activeColor: AppColors.primary,
                  title: const Text('Rappel hydratation'),
                  subtitle: const Text('Boire de l\'eau toutes les 2 h'),
                  onChanged: (v) {
                    setState(() => _water = v);
                    _set(_kWater, v);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  value: _weekly,
                  activeColor: AppColors.primary,
                  title: const Text('Bilan hebdomadaire'),
                  subtitle: const Text('Résumé par email chaque dimanche'),
                  onChanged: (v) {
                    setState(() => _weekly = v);
                    _set(_kWeekly, v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Text('À propos',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimensions.paddingSm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VitaTrack — version 1.0.0'),
                const SizedBox(height: 4),
                Text(
                  FirebaseBootstrap.ready
                      ? 'Firebase actif : authentification et données synchronisées avec Cloud Firestore.'
                      : 'Firebase non configuré : l’application utilise le mode local de secours. Exécutez flutterfire configure pour activer Firebase.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
