import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_sync_service.dart';

/// Finest abstraction de persistance locale (JSON via SharedPreferences).
///
/// Cette classe centralise le stockage des collections de l'application.
/// Elle jouera le rôle de Firebase/Backend une fois ces services branchés :
/// il suffira de remplacer son implémentation par des appels réseau.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p =>
      _prefs ??
      (throw StateError('LocalStore.init() doit être appelé avant usage.'));

  /// Lit une liste d'objets JSON stockée sous [key].
  List<Map<String, dynamic>> readList(String key) {
    final raw = _p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Écrit une liste d'objets JSON sous [key].
  Future<void> writeList(String key, List<Map<String, dynamic>> value, {bool syncFirebase = true}) async {
    await _p.setString(key, jsonEncode(value));
    if (syncFirebase) {
      try { await FirebaseSyncService.instance.syncStoreList(key, value); } catch (_) {}
    }
  }

  String? readString(String key) => _p.getString(key);

  Future<void> writeString(String key, String value) =>
      _p.setString(key, value);

  Future<void> remove(String key) => _p.remove(key);

  bool hasKey(String key) => _p.containsKey(key);
}

/// Clés de stockage centralisées.
class StoreKeys {
  StoreKeys._();

  static const accounts = 'vitatrack_accounts';
  static const session = 'vitatrack_session';
  static const onboardingSeen = 'vitatrack_onboarding_seen';
  static const foods = 'vitatrack_foods';
  static const categories = 'vitatrack_categories';
  static const favorites = 'vitatrack_favorites';
  static const meals = 'vitatrack_meals';
  static const weights = 'vitatrack_weights';
  static const goals = 'vitatrack_goals';
  static const recommendations = 'vitatrack_recommendations';
  static const mealPlans = 'vitatrack_meal_plans';
  static const notifications = 'vitatrack_notifications';
  static const conversations = 'vitatrack_conversations';
  static const activityLogs = 'vitatrack_activity_logs';
  static const seeded = 'vitatrack_seeded_v1';

  // Jetons de la session backend (mode serveur uniquement).
  static const accessToken = 'vitatrack_access_token';
  static const refreshToken = 'vitatrack_refresh_token';
}
