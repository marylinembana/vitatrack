import '../models/user_model.dart';
import 'auth_repository.dart';

/// Repository des profils utilisateurs (stockés dans les comptes).
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final AuthRepository _auth = AuthRepository.instance;

  /// Liste tous les profils utilisateurs (rôle user), pour l'admin et
  /// la liste des patients du nutritionniste.
  List<UserModel> allUsers() => _auth
      .allAccounts()
      .where((a) => a.role == 'user')
      .map((a) => UserModel.fromMap(a.profile))
      .toList();

  UserModel? byId(String userId) {
    final account =
        _auth.allAccounts().cast<UserAccount?>().firstWhere(
              (a) => a!.id == userId,
              orElse: () => null,
            );
    if (account == null) return null;
    return UserModel.fromMap(account.profile);
  }

  Future<void> saveUser(UserModel user) async {
    final accounts = _auth.allAccounts();
    final account = accounts.firstWhere((a) => a.id == user.id);
    account.profile = user.toMap();
    await _auth.saveAccounts(accounts);
  }

  Future<void> toggleFavorite(String userId, String foodId) async {
    final user = byId(userId);
    if (user == null) return;
    if (user.favoriteFoodIds.contains(foodId)) {
      user.favoriteFoodIds.remove(foodId);
    } else {
      user.favoriteFoodIds.add(foodId);
    }
    await saveUser(user);
  }
}
