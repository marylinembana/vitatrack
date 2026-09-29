import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../app/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/local_store.dart';
import '../../core/services/supabase_bootstrap.dart';
import '../../core/services/supabase_sync_service.dart';

class UserAccount {
  final String id;
  final String email;
  final String role;
  String passwordHash;
  Map<String, dynamic> profile;
  UserAccount(
      {required this.id,
      required this.email,
      required this.role,
      required this.passwordHash,
      required this.profile});
  factory UserAccount.fromMap(Map<String, dynamic> map) => UserAccount(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? UserRole.user,
      passwordHash: map['passwordHash'] as String? ?? '',
      profile: (map['profile'] as Map?)?.cast<String, dynamic>() ?? {});
  Map<String, dynamic> toMap() =>
      {'id': id, 'email': email, 'role': role, 'passwordHash': passwordHash, 'profile': profile};
}

/// Authentification et gestion des comptes.
///
/// Backend réel : **Supabase Auth** (GoTrue) + table `profiles`. Un cache local
/// (`LocalStore`) garde la liste des comptes visibles pour des lectures
/// synchrones des repositories. Hors connexion (Supabase indisponible), on
/// retombe sur des comptes locaux hashés pour que l'app reste utilisable.
class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  final LocalStore _store = LocalStore.instance;
  final Random _random = Random();
  UserAccount? _current;
  UserAccount? get currentAccount => _current;

  sb.SupabaseClient get _client => sb.Supabase.instance.client;
  bool get _online => SupabaseBootstrap.ready;

  String get _newId =>
      'acc_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  String _hash(String p) => base64.encode(utf8.encode('vita::${p.trim()}'));
  String hashForDemo(String p) => _hash(p);

  List<UserAccount> allAccounts() =>
      _store.readList(StoreKeys.accounts).map(UserAccount.fromMap).toList();
  List<UserAccount> _loadAccounts() => allAccounts();

  /// Écrit le cache local et pousse les comptes modifiés vers `profiles`
  /// (le RLS n'autorise l'écriture que de son propre profil, ou de tous en
  /// tant qu'admin ; les écritures refusées sont ignorées silencieusement).
  Future<void> saveAccounts(List<UserAccount> a) =>
      _store.writeList(StoreKeys.accounts, a.map((x) => x.toMap()).toList());

  /// Comptes de démonstration locaux, uniquement si Supabase n'est pas prêt.
  Future<void> seedDemoAccounts() async {
    if (_online || _loadAccounts().isNotEmpty) return;
    final now = DateTime.now().toIso8601String();
    final userId = 'acc_demo_user';
    final nutritionistId = 'acc_demo_nutritionist';
    final adminId = 'acc_demo_admin';
    final accounts = [
      UserAccount(id: userId, email: 'user@vitatrack.app', role: UserRole.user,
          passwordHash: _hash('demo1234'), profile: {'id': userId, 'email': 'user@vitatrack.app', 'role': 'user', 'fullName': 'Afiwa Mbarga', 'gender': 'female', 'birthDate': '1998-05-12T00:00:00.000', 'heightCm': 165, 'activityFactor': 1.375, 'goalType': 'lose', 'targetWeightKg': 62, 'calorieGoal': 1650, 'isOnboarded': true, 'emailVerified': true, 'favoriteFoodIds': ['food_001', 'food_015'], 'createdAt': now}),
      UserAccount(id: nutritionistId, email: 'nutritionist@vitatrack.app', role: UserRole.nutritionist,
          passwordHash: _hash('demo1234'), profile: {'id': nutritionistId, 'email': 'nutritionist@vitatrack.app', 'role': 'nutritionist', 'fullName': 'Dr. Renaud Adjovi', 'specialization': 'Nutrition générale', 'licenseNumber': 'NUT-DEMO-001', 'bio': 'Nutritionniste VitaTrack', 'city': 'Yaoundé', 'experienceYears': 8, 'patientIds': [userId], 'isVerified': true, 'verificationStatus': 'verified', 'createdAt': now}),
      UserAccount(id: adminId, email: 'admin@vitatrack.app', role: UserRole.admin,
          passwordHash: _hash('demo1234'), profile: {'id': adminId, 'email': 'admin@vitatrack.app', 'role': 'super_admin', 'fullName': 'Administrateur VitaTrack', 'createdAt': now}),
    ];
    await _store.writeList(StoreKeys.accounts, accounts.map((x) => x.toMap()).toList(), syncFirebase: false);
  }

  Future<UserAccount?> restoreSession() async {
    if (_online) {
      final user = _client.auth.currentUser;
      if (user != null) {
        final a = await _fromProfile(user);
        _current = a;
        await _cache(a);
        return a;
      }
    }
    final id = _store.readString(StoreKeys.session);
    if (id == null) return null;
    final a = _loadAccounts().where((x) => x.id == id).cast<UserAccount?>().firstOrNull;
    _current = a;
    return a;
  }

  Future<UserAccount> register({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> profile,
    String role = UserRole.user,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (_online) {
      try {
        final res = await _client.auth.signUp(
            email: normalized,
            password: password,
            data: {'full_name': fullName.trim(), 'role': role});
        final user = res.user;
        if (user == null) {
          throw const AuthException(
              'Inscription impossible. Vérifiez vos informations.',
              code: 'signup-failed');
        }
        final id = user.id;
        final p = Map<String, dynamic>.from(profile)
          ..addAll({
            'id': id,
            'email': normalized,
            'role': role,
            'fullName': fullName.trim(),
            'isActive': true,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        await _upsertProfile(id, normalized, role, p);
        final a = UserAccount(id: id, email: normalized, role: role, passwordHash: '', profile: p);
        _current = a;
        await _cache(a);
        await _store.writeString(StoreKeys.session, id);
        return a;
      } on AuthException {
        rethrow;
      } catch (e) {
        throw AuthException(_message(e), code: _code(e));
      }
    }
    if (_loadAccounts().any((a) => a.email == normalized)) {
      throw const AuthException('Un compte existe déjà avec cet email.', code: 'email-already-in-use');
    }
    final id = _newId;
    final a = UserAccount(id: id, email: normalized, role: role, passwordHash: _hash(password),
        profile: {...profile, 'id': id, 'email': normalized, 'role': role, 'fullName': fullName.trim()});
    final list = _loadAccounts()..add(a);
    await _store.writeList(StoreKeys.accounts, list.map((x) => x.toMap()).toList(), syncFirebase: false);
    _current = a;
    await _store.writeString(StoreKeys.session, id);
    return a;
  }

  Future<UserAccount> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (_online) {
      try {
        final res = await _client.auth.signInWithPassword(email: normalized, password: password);
        final a = await _fromProfile(res.user!);
        _current = a;
        await _cache(a);
        await _store.writeString(StoreKeys.session, a.id);
        await SupabaseSyncService.instance.pullForCurrentAccount(role: a.role);
        return a;
      } on AuthException {
        rethrow;
      } catch (e) {
        throw AuthException(_message(e), code: _code(e));
      }
    }
    final a = _loadAccounts().where((x) => x.email == normalized).cast<UserAccount?>().firstOrNull;
    if (a == null || a.passwordHash != _hash(password)) {
      throw const AuthException('Email ou mot de passe incorrect.', code: 'invalid-credential');
    }
    _current = a;
    await _store.writeString(StoreKeys.session, a.id);
    return a;
  }

  Future<void> logout() async {
    if (_online) {
      try { await _client.auth.signOut(); } catch (_) {}
    }
    _current = null;
    await _store.remove(StoreKeys.session);
  }

  Future<void> updateProfile(UserAccount a) async {
    if (_online) {
      await _upsertProfile(a.id, a.email, a.role, a.profile);
    }
    final list = _loadAccounts();
    final i = list.indexWhere((x) => x.id == a.id);
    if (i == -1) {
      list.add(a);
    } else {
      list[i] = a;
    }
    await _store.writeList(StoreKeys.accounts, list.map((x) => x.toMap()).toList(), syncFirebase: false);
    if (_current?.id == a.id) _current = a;
  }

  /// Persiste un profil modifié pour un AUTRE compte (ex. : validation
  /// admin d'un nutritionniste). Le RLS n'autorise cette écriture qu'au
  /// rôle admin ; sans cet envoi, le changement resterait confiné au
  /// cache local de l'admin et serait perdu au rechargement du concerné.
  Future<void> syncProfileToBackend(UserAccount a) async {
    await _upsertProfile(a.id, a.email, a.role, a.profile);
  }

  /// Recharge le compte connecté depuis Supabase (statut à jour après
  /// validation admin). Retourne null hors-ligne ou session perdue.
  Future<UserAccount?> refreshCurrentAccount() async {
    if (!_online) return null;
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final a = await _fromProfile(user);
    _current = a;
    await _cache(a);
    return a;
  }

  Future<void> sendPasswordReset(String email) async {
    if (_online) {
      try {
        await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
        return;
      } catch (e) {
        throw AuthException(_message(e), code: _code(e));
      }
    }
    if (!_loadAccounts().any((a) => a.email == email.trim().toLowerCase())) {
      throw const AuthException('Aucun compte trouvé avec cet email.', code: 'user-not-found');
    }
  }

  bool checkCurrentPassword(String password) {
    final a = _current;
    return a != null && (a.passwordHash.isEmpty || a.passwordHash == _hash(password));
  }

  Future<void> changePassword(String id, String fresh) async {
    if (_online && _client.auth.currentUser?.id == id) {
      await _client.auth.updateUser(sb.UserAttributes(password: fresh));
      return;
    }
    final list = _loadAccounts();
    final i = list.indexWhere((a) => a.id == id);
    if (i == -1) throw const NotFoundException('Compte introuvable.');
    list[i].passwordHash = _hash(fresh);
    await _store.writeList(StoreKeys.accounts, list.map((x) => x.toMap()).toList(), syncFirebase: false);
  }

  /// Change le mot de passe en revalidant d'abord le mot de passe courant
  /// (Supabase exige une session récente pour modifier un mot de passe).
  Future<void> changePasswordWithReauth(String current, String fresh) async {
    if (_online) {
      final user = _client.auth.currentUser;
      if (user == null || user.email == null) {
        throw const AuthException('Session expirée.');
      }
      try {
        await _client.auth.signInWithPassword(email: user.email!, password: current);
        await _client.auth.updateUser(sb.UserAttributes(password: fresh));
        return;
      } catch (e) {
        throw AuthException(_message(e), code: _code(e));
      }
    }
    final a = _current;
    if (a == null || a.passwordHash != _hash(current)) {
      throw const AuthException('Mot de passe actuel incorrect.');
    }
    final list = _loadAccounts();
    final i = list.indexWhere((x) => x.id == a.id);
    if (i == -1) throw const NotFoundException('Compte introuvable.');
    list[i].passwordHash = _hash(fresh);
    await _store.writeList(StoreKeys.accounts, list.map((x) => x.toMap()).toList(), syncFirebase: false);
  }

  Future<void> changePasswordOnBackend(String current, String fresh) async =>
      changePasswordWithReauth(current, fresh);

  Future<void> deleteAccount(String id) async {
    final list = _loadAccounts()..removeWhere((a) => a.id == id);
    await _store.writeList(StoreKeys.accounts, list.map((x) => x.toMap()).toList(), syncFirebase: false);
    // La suppression distante d'un compte relève de l'admin (service role).
    // Côté client on clôture au maximum la session courante.
    if (_online && _client.auth.currentUser?.id == id) {
      try { await _client.auth.signOut(); } catch (_) {}
    }
  }

  Future<void> _cache(UserAccount a) async {
    final list = _loadAccounts();
    final i = list.indexWhere((x) => x.id == a.id);
    if (i == -1) {
      list.add(a);
    } else {
      list[i] = a;
    }
    await _store.writeList(StoreKeys.accounts, list.map((x) => x.toMap()).toList(), syncFirebase: false);
  }

  /// Persiste/actualise la ligne `profiles` (colonnes relationnelles + JSONB).
  Future<void> _upsertProfile(String id, String email, String role, Map<String, dynamic> profile) async {
    if (!_online) return;
    final payload = <String, dynamic>{
      'id': id,
      'email': email,
      'role': role,
      'full_name': profile['fullName'] ?? '',
      'photo_url': profile['photoUrl'],
      'nutritionist_id': profile['nutritionistId'],
      'is_onboarded': profile['isOnboarded'] ?? false,
      'profile': profile,
    };
    try {
      await _client.from(SupabaseTables.profiles).upsert(payload, onConflict: 'id');
    } catch (_) {/* RLS : écriture limitée à soi-même ou en tant qu'admin */}
  }

  /// Construit un compte depuis la session Supabase + la ligne `profiles`.
  Future<UserAccount> _fromProfile(sb.User user) async {
    var profile = <String, dynamic>{
      'id': user.id,
      'email': user.email ?? '',
      'fullName': (user.userMetadata?['full_name'] as String?) ?? '',
      'role': (user.userMetadata?['role'] as String?) ?? UserRole.user,
      'emailVerified': user.emailConfirmedAt != null,
      'createdAt': DateTime.now().toIso8601String(),
    };
    try {
      final row = await _client
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        profile = (row['profile'] as Map?)?.cast<String, dynamic>() ?? profile;
        profile['id'] = user.id;
        profile['email'] = row['email'] ?? profile['email'];
        profile['role'] = row['role'] ?? profile['role'];
        profile['emailVerified'] = user.emailConfirmedAt != null;
      }
    } catch (_) {}
    final role = profile['role']?.toString() ?? UserRole.user;
    return UserAccount(
        id: user.id, email: user.email ?? '', role: role, passwordHash: '', profile: profile);
  }

  String _code(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('invalid') && s.contains('credential')) return 'invalid-credential';
    if (s.contains('already')) return 'email-already-in-use';
    if (s.contains('not confirmed')) return 'email-not-confirmed';
    if (s.contains('network')) return 'network-request-failed';
    return 'auth-error';
  }

  String _message(Object e) => _friendly(e.toString());

  String _friendly(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('invalid login credentials') || s.contains('invalid credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (s.contains('email not confirmed') || s.contains('not confirmed')) {
      return 'Confirmez votre email avant de vous connecter.';
    }
    if (s.contains('already registered') || s.contains('already exists') || s.contains('already in use')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (s.contains('password')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (s.contains('network') || s.contains('failed host lookup')) {
      return 'Connexion réseau indisponible.';
    }
    if (s.contains('email') && s.contains('invalid')) {
      return 'Adresse email invalide.';
    }
    return 'Une erreur est survenue.';
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
