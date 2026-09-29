import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_store.dart';

/// Réplique les collections locales (LocalStore) vers Postgres via PostgREST,
/// et recharge les données distantes utiles à la session courante.
///
/// Design : chaque table porte une colonne JSONB `data` contenant la
/// représentation exacte du modèle Dart (toMap()). Les colonnes relationnelles
/// (user_id, meal_date, …) servent au filtrage RLS et aux index. Le client
/// utilise le JWT du compte connecté : le RLS limite naturellement ce que
/// l'utilisateur voit et peut écrire.
class SupabaseSyncService {
  SupabaseSyncService._();
  static final instance = SupabaseSyncService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Clé d'auto-persistance du dernier pull, pour éviter un pull systématique.
  static const _lastPullKey = 'vitatrack_last_supabase_pull';

  /// Durée de validité du cache : sous ce seuil, un redémarrage n'attend pas
  /// le réseau et affiche immédiatement les données locales.
  static const Duration pullTtl = Duration(minutes: 2);

  // ── PUSH ──────────────────────────────────────────────────────────────

  /// Envoie la liste locale [rows] dans la table correspondante (upsert).
  Future<void> syncStoreList(String key, List<Map<String, dynamic>> rows) async {
    final table = _tableForStoreKey(key);
    if (table == null) return;
    if (_client.auth.currentUser == null) return; // hors-ligne / non connecté
    for (final raw in rows) {
      final id = raw['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final payload = _shapeForTable(table, key, raw);
      if (payload == null) continue;
      try {
        await _client.from(table).upsert(payload, onConflict: 'id');
      } catch (_) {/* RLS ou réseau : on ignore, la source locale reste fiable */}
    }
  }

  // ── PULL ──────────────────────────────────────────────────────────────

  /// true si un pull a réussi il y a moins de [within] : le cache local est
  /// considéré frais, l'app peut l'afficher sans attendre le réseau.
  bool hasRecentPull({Duration within = pullTtl}) {
    final raw = LocalStore.instance.readString(_lastPullKey);
    if (raw == null) return false;
    final t = DateTime.tryParse(raw);
    if (t == null) return false;
    return DateTime.now().difference(t) < within;
  }

  /// Recharge depuis Postgres les lignes visibles par le compte connecté.
  ///
  /// Les requêtes sont **indépendantes** et donc lancées en parallèle
  /// (Future.wait) : sur un réseau mobile/lointain cela efface le cumul des
  /// allers-retours séquentiels (≈ 10 RTT → 1). Chaque table gère ses propres
  /// erreurs pour qu'un échec isolé n'annule pas tout le rafraîchissement.
  Future<void> pullForCurrentAccount({required String role}) async {
    if (_client.auth.currentUser == null) return;
    final tasks = <Future<void>>[
      // Références partagées.
      _pullTable(SupabaseTables.foods, StoreKeys.foods),
      _pullTable(SupabaseTables.categories, StoreKeys.categories),
      // Données personnelles (RLS restreint à soi / patients assignés).
      _pullTable(SupabaseTables.meals, StoreKeys.meals),
      _pullTable(SupabaseTables.weightEntries, StoreKeys.weights),
      _pullTable(SupabaseTables.nutritionGoals, StoreKeys.goals),
      _pullTable(SupabaseTables.nutritionPlans, StoreKeys.mealPlans),
      _pullTable(SupabaseTables.recommendations, StoreKeys.recommendations),
      _pullTable(SupabaseTables.notifications, StoreKeys.notifications),
      _pullTable(SupabaseTables.conversations, StoreKeys.conversations),
      // Comptes : RLS renvoie soi (+ patients pour nutritionniste, tous pour admin).
      _pullProfilesIntoAccounts(),
      if (role == 'admin')
        _pullTable(SupabaseTables.activityLogs, StoreKeys.activityLogs),
    ];
    await Future.wait(tasks);
    await LocalStore.instance
        .writeString(_lastPullKey, DateTime.now().toIso8601String());
  }

  Future<void> _pullTable(String table, String storeKey) async {
    try {
      // On ne récupère que la colonne JSONB `data` : c'est la représentation
      // exacte du modèle, inutiles les colonnes relationnelles dupliquées.
      final rows = await _client.from(table).select('data');
      if (rows.isEmpty) return;
      final data = rows
          .map((r) => (r['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
          .where((m) => (m['id']?.toString() ?? '').isNotEmpty)
          .toList();
      if (data.isNotEmpty) {
        await LocalStore.instance.writeList(storeKey, data, syncFirebase: false);
      }
    } catch (_) {/* silencieux : l'app reste utilisable hors-ligne */}
  }

  /// Les lignes `profiles` sont converties en comptes locaux {id,email,role,profile}.
  Future<void> _pullProfilesIntoAccounts() async {
    try {
      final rows = await _client
          .from(SupabaseTables.profiles)
          .select('id,email,role,profile');
      if (rows.isEmpty) return;
      final accounts = rows.map((r) {
        final profile = (r['profile'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        profile['id'] = r['id'];
        profile['email'] = r['email'] ?? profile['email'] ?? '';
        profile['role'] = r['role'] ?? profile['role'] ?? 'user';
        return <String, dynamic>{
          'id': r['id'],
          'email': r['email'] ?? '',
          'role': r['role'] ?? 'user',
          'passwordHash': '',
          'profile': profile,
        };
      }).toList();
      await LocalStore.instance
          .writeList(StoreKeys.accounts, accounts, syncFirebase: false);
    } catch (_) {/* silencieux */}
  }

  // ── MAPPINGS ──────────────────────────────────────────────────────────

  String? _tableForStoreKey(String key) => switch (key) {
        StoreKeys.foods => SupabaseTables.foods,
        StoreKeys.categories => SupabaseTables.categories,
        StoreKeys.meals => SupabaseTables.meals,
        StoreKeys.weights => SupabaseTables.weightEntries,
        StoreKeys.goals => SupabaseTables.nutritionGoals,
        StoreKeys.mealPlans => SupabaseTables.nutritionPlans,
        StoreKeys.recommendations => SupabaseTables.recommendations,
        StoreKeys.notifications => SupabaseTables.notifications,
        StoreKeys.conversations => SupabaseTables.conversations,
        StoreKeys.activityLogs => SupabaseTables.activityLogs,
        StoreKeys.accounts => SupabaseTables.profiles,
        _ => null,
      };

  /// Construit la ligne Postgres (colonnes relationnelles + `data` JSONB).
  Map<String, dynamic>? _shapeForTable(
      String table, String storeKey, Map<String, dynamic> row) {
    if (table == SupabaseTables.profiles) {
      // `row` = compte {id,email,role,profile}
      final profile = (row['profile'] as Map?)?.cast<String, dynamic>() ?? {};
      return {
        'id': row['id'],
        'email': row['email'] ?? profile['email'] ?? '',
        'role': row['role'] ?? profile['role'] ?? 'user',
        'full_name': profile['fullName'] ?? '',
        'photo_url': profile['photoUrl'],
        'nutritionist_id': profile['nutritionistId'],
        'is_onboarded': profile['isOnboarded'] ?? false,
        'profile': profile,
      };
    }
    final base = <String, dynamic>{'id': row['id'], 'data': row};
    switch (table) {
      case SupabaseTables.foods:
        return {
          ...base,
          'name': row['name'] ?? '',
          'category_id': row['categoryId'] ?? '',
          'is_active': row['isActive'] ?? true,
          'image_url': row['imageUrl'],
        };
      case SupabaseTables.categories:
        return {
          ...base,
          'name': row['name'] ?? '',
          'emoji': row['emoji'] ?? '',
        };
      case SupabaseTables.meals:
        return {
          ...base,
          'user_id': row['userId'],
          'meal_type': row['type'] ?? '',
          'meal_date': row['date'] ?? DateTime.now().toIso8601String(),
        };
      case SupabaseTables.weightEntries:
        return {
          ...base,
          'user_id': row['userId'],
          'entry_date': row['date'] ?? DateTime.now().toIso8601String(),
        };
      case SupabaseTables.nutritionGoals:
        return {
          ...base,
          'user_id': row['userId'],
          'is_active': row['isActive'] ?? true,
          'start_date': row['startDate'] ?? DateTime.now().toIso8601String(),
        };
      case SupabaseTables.nutritionPlans:
        return {
          ...base,
          'nutritionist_id': row['nutritionistId'] ?? '',
          'patient_id': row['patientId'] ?? '',
          'created_at': row['createdAt'] ?? DateTime.now().toIso8601String(),
        };
      case SupabaseTables.recommendations:
        return {
          ...base,
          'user_id': row['userId'],
          'nutritionist_id': row['authorId'],
          'is_read': row['isRead'] ?? false,
          'created_at': row['createdAt'] ?? DateTime.now().toIso8601String(),
        };
      case SupabaseTables.notifications:
        return {
          ...base,
          'user_id': row['userId'],
          'is_read': row['isRead'] ?? false,
          'created_at': row['createdAt'] ?? DateTime.now().toIso8601String(),
        };
      case SupabaseTables.conversations:
        return {
          ...base,
          'user_id': row['userId'] ?? '',
          'nutritionist_id': row['nutritionistId'] ?? '',
          'updated_at': DateTime.now().toIso8601String(),
        };
      case SupabaseTables.activityLogs:
        return {
          ...base,
          'actor_id': row['actorId'] ?? '',
          'actor_role': row['actorRole'] ?? '',
          'action': row['action'] ?? '',
          'target': row['target'] ?? '',
          'created_at': row['createdAt'] ?? DateTime.now().toIso8601String(),
        };
    }
    return base;
  }
}

/// Noms de tables Postgres (miroir des collections Firestore d'origine).
class SupabaseTables {
  SupabaseTables._();
  static const profiles = 'profiles';
  static const foods = 'foods';
  static const categories = 'categories';
  static const meals = 'meals';
  static const weightEntries = 'weight_entries';
  static const nutritionGoals = 'nutrition_goals';
  static const nutritionPlans = 'nutrition_plans';
  static const recommendations = 'recommendations';
  static const notifications = 'notifications';
  static const conversations = 'conversations';
  static const activityLogs = 'activity_logs';
}
