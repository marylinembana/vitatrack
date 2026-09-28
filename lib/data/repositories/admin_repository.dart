import '../../app/constants/app_constants.dart';
import '../../core/services/local_store.dart';
import '../models/admin_model.dart';
import 'auth_repository.dart';
import 'food_repository.dart';
import 'meal_repository.dart';
import 'user_repository.dart';

/// Repository administrateur : journal d'activités et statistiques globales.
class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  final LocalStore _store = LocalStore.instance;

  List<ActivityLogModel> _load() => _store
      .readList(StoreKeys.activityLogs)
      .map(ActivityLogModel.fromMap)
      .toList();

  Future<void> _save(List<ActivityLogModel> list) => _store.writeList(
        StoreKeys.activityLogs,
        list.map((l) => l.toMap()).toList(),
      );

  List<ActivityLogModel> logs() => _load()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> log({
    required String actorId,
    required String actorRole,
    required String action,
    String target = '',
  }) async {
    final list = _load();
    list.add(ActivityLogModel(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      actorId: actorId,
      actorRole: actorRole,
      action: action,
      target: target,
    ));
    await _save(list);
  }

  /// Statistiques globales pour le tableau de bord admin.
  Future<({
    int totalUsers,
    int totalNutritionists,
    int totalFoods,
    int totalCategories,
    int mealsLogged,
    int activeToday,
  })> statistics() async {
    final accounts = AuthRepository.instance.allAccounts();
    final foods = await FoodRepository.instance.all(includeInactive: true);
    final categories = await FoodRepository.instance.categories();
    return (
      totalUsers: accounts.where((a) => a.role == 'user').length,
      totalNutritionists:
          accounts.where((a) => a.role == 'nutritionist').length,
      totalFoods: foods.length,
      totalCategories: categories.length,
      mealsLogged: MealRepository.instance.totalMeals(),
      activeToday: UserRepository.instance.allUsers().length,
    );
  }

  // ── Gestion des administrateurs (réservée au super administrateur) ──

  /// Tous les comptes administrateurs (super_admin inclus).
  List<AdminModel> admins() {
    final list = AuthRepository.instance
        .allAccounts()
        .where((a) => a.role == UserRole.admin)
        .map((a) {
          final profile = Map<String, dynamic>.from(a.profile);
          profile['id'] ??= a.id;
          profile['email'] ??= a.email;
          return AdminModel.fromMap(profile);
        })
        .toList()
      ..sort((x, y) => x.fullName.compareTo(y.fullName));
    return list;
  }

  /// Crée un compte administrateur. Retourne un message d'erreur ou null.
  Future<String?> createAdmin({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String actorId,
  }) async {
    final normalized = email.trim().toLowerCase();
    final accounts = AuthRepository.instance.allAccounts();
    if (accounts.any((a) => a.email == normalized)) {
      return 'Un compte existe déjà avec cet email.';
    }
    final id = 'acc_admin_${DateTime.now().millisecondsSinceEpoch}';
    accounts.add(UserAccount(
      id: id,
      email: normalized,
      role: UserRole.admin,
      passwordHash: AuthRepository.instance.hashForDemo(password),
      profile: {
        'id': id,
        'email': normalized,
        'fullName': fullName.trim(),
        'role': role == 'super_admin' ? 'super_admin' : 'admin',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ));
    await AuthRepository.instance.saveAccounts(accounts);
    await log(
      actorId: actorId,
      actorRole: UserRole.admin,
      action: 'create_admin',
      target: '$normalized (${role == 'super_admin' ? 'super_admin' : 'admin'})',
    );
    return null;
  }

  /// Promeut ou rétrograde un administrateur. Retourne un message d'erreur
  /// ou null. [actorIsSuperAdmin] doit être vrai pour toucher un pair.
  Future<String?> setAdminRole({
    required String targetId,
    required String newRole,
    required String actorId,
    required bool actorIsSuperAdmin,
  }) async {
    if (targetId == actorId) {
      return 'Vous ne pouvez pas modifier votre propre rôle.';
    }
    final accounts = AuthRepository.instance.allAccounts();
    final index = accounts.indexWhere((a) => a.id == targetId);
    if (index == -1) return 'Administrateur introuvable.';
    final currentRole = accounts[index].profile['role'] ?? 'admin';
    if (!actorIsSuperAdmin) {
      return 'Seul le super administrateur peut modifier les rôles.';
    }
    if (currentRole == 'super_admin' && newRole != 'super_admin') {
      final supers =
          accounts.where((a) => a.profile['role'] == 'super_admin').length;
      if (supers <= 1) {
        return 'Impossible de rétrograder le dernier super administrateur.';
      }
    }
    accounts[index].profile['role'] =
        newRole == 'super_admin' ? 'super_admin' : 'admin';
    await AuthRepository.instance.saveAccounts(accounts);
    await log(
      actorId: actorId,
      actorRole: UserRole.admin,
      action: 'set_admin_role',
      target: '${accounts[index].email} → ${accounts[index].profile['role']}',
    );
    return null;
  }

  /// Supprime un compte administrateur. Retourne un message d'erreur ou null.
  Future<String?> deleteAdmin({
    required String targetId,
    required String actorId,
  }) async {
    if (targetId == actorId) {
      return 'Vous ne pouvez pas supprimer votre propre compte.';
    }
    final accounts = AuthRepository.instance.allAccounts();
    final target = accounts.cast<UserAccount?>().firstWhere(
          (a) => a!.id == targetId,
          orElse: () => null,
        );
    if (target == null) return 'Administrateur introuvable.';
    if (target.profile['role'] == 'super_admin') {
      final supers =
          accounts.where((a) => a.profile['role'] == 'super_admin').length;
      if (supers <= 1) {
        return 'Impossible de supprimer le dernier super administrateur.';
      }
    }
    await AuthRepository.instance.deleteAccount(targetId);
    await log(
      actorId: actorId,
      actorRole: UserRole.admin,
      action: 'delete_admin',
      target: target.email,
    );
    return null;
  }
}
