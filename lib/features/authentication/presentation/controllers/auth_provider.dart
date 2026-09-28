import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/firebase_bootstrap.dart';
import '../../../../data/models/admin_model.dart';
import '../../../../data/models/nutritionist_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Gère l'authentification et la session courante (tous rôles confondus).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  bool _loading = false;
  String? _error;

  UserAccount? get account => _repo.currentAccount;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isSignedIn => _repo.currentAccount != null;
  String get role => _repo.currentAccount?.role ?? '';

  UserModel? get currentUser {
    final a = account;
    if (a == null || a.role != UserRole.user) return null;
    return UserModel.fromMap(a.profile);
  }

  NutritionistModel? get currentNutritionist {
    final a = account;
    if (a == null || a.role != UserRole.nutritionist) return null;
    return NutritionistModel.fromMap(a.profile);
  }

  AdminModel? get currentAdmin {
    final a = account;
    if (a == null || a.role != UserRole.admin) return null;
    return AdminModel.fromMap(a.profile);
  }

  String get displayName =>
      account?.profile['fullName'] as String? ?? account?.email ?? '';

  /// Route d'atterrissage selon le rôle, en tenant compte de la vérification
  /// obligatoire du compte nutritionniste.
  String get landingRoute {
    switch (role) {
      case UserRole.nutritionist:
        final n = currentNutritionist;
        return (n != null && n.hasAccess)
            ? '/nutritionist/home'
            : '/nutritionist/verification';
      case UserRole.admin:
        return '/admin/home';
      default:
        return '/home';
    }
  }

  /// Initiales affichées dans les avatars (ex. « AK »).
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.login(email, password);
      _error = null;
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Erreur inattendue.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final user = UserModel(
        id: '',
        email: email.trim().toLowerCase(),
        fullName: fullName.trim(),
      );
      final account = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        profile: user.toMap(),
      );
      // On corrige l'id du profil avec celui du compte créé.
      final profileMap = Map<String, dynamic>.from(account.profile);
      profileMap['id'] = account.id;
      account.profile = profileMap;
      await _repo.updateProfile(account);
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Erreur inattendue.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Inscription d'un compte nutritionniste (rôle pro, soumis à vérification).
  Future<bool> registerNutritionist({
    required String fullName,
    required String email,
    required String password,
    required String specialization,
    required String licenseNumber,
    String phone = '',
    String city = '',
    int experienceYears = 0,
    String bio = '',
    List<String> diplomaUrls = const [],
  }) async {
    _setLoading(true);
    try {
      final id = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      final nutritionist = NutritionistModel(
        id: id,
        email: email.trim().toLowerCase(),
        fullName: fullName.trim(),
        specialization: specialization.trim(),
        licenseNumber: licenseNumber.trim(),
        phone: phone.trim(),
        city: city.trim(),
        experienceYears: experienceYears,
        bio: bio.trim(),
        diplomaUrls: diplomaUrls,
        isVerified: false,
        verificationStatus: VerificationStatus.pending,
      );
      final account = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        profile: nutritionist.toMap(),
        role: UserRole.nutritionist,
      );
      final profileMap = Map<String, dynamic>.from(account.profile);
      profileMap['id'] = account.id;
      account.profile = profileMap;
      await _repo.updateProfile(account);
      _error = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Erreur inattendue.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _repo.sendPasswordReset(email);
      _error = null;
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    notifyListeners();
  }

  /// Restaure la session sauvegardée au démarrage de l'application.
  Future<UserAccount?> restoreSession() async {
    final account = await _repo.restoreSession();
    if (account != null) notifyListeners();
    return account;
  }

  /// Persiste un profil utilisateur modifié.
  Future<void> updateUserProfile(UserModel user) async {
    final a = account;
    if (a == null) return;
    user.photoUrl = await _publishPhoto(user.photoUrl);
    a.profile = user.toMap();
    await _repo.updateProfile(a);
    notifyListeners();
  }

  Future<void> updateNutritionistProfile(NutritionistModel model) async {
    final a = account;
    if (a == null) return;
    model.photoUrl = await _publishPhoto(model.photoUrl);
    a.profile = model.toMap();
    await _repo.updateProfile(a);
    notifyListeners();
  }

  Future<String?> _publishPhoto(String? photo) async {
    if (photo == null || photo.isEmpty) return photo;
    if (photo.startsWith('http://') || photo.startsWith('https://')) return photo;
    if (FirebaseBootstrap.ready && account != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(account!.id)
            .child('avatar.jpg');
        if (!kIsWeb) {
          final file = File(photo);
          if (await file.exists()) {
            final task = await ref.putFile(file);
            return await task.ref.getDownloadURL();
          }
        }
      } catch (_) {}
    }
    return photo;
  }

  /// Persiste le profil de l'administrateur connecté (nom, photo…).
  Future<void> updateAdminProfile(AdminModel model) async {
    final a = account;
    if (a == null) return;
    a.profile = model.toMap();
    await _repo.updateProfile(a);
    notifyListeners();
  }

  /// Change le mot de passe du compte connecté.
  /// Retourne un message d'erreur, ou null si tout s'est bien passé.
  Future<String?> changePassword(String current, String fresh) async {
    final a = account;
    if (a == null) return 'Session expirée.';
    if (fresh.trim().length < 6) {
      return 'Le nouveau mot de passe doit faire au moins 6 caractères.';
    }
    try {
      await _repo.changePasswordWithReauth(current, fresh);
      return null;
    } on AppException catch (e) {
      return e.message;
    } catch (_) {
      return 'Impossible de modifier le mot de passe. Reconnectez-vous puis réessayez.';
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// Message d'erreur lisible pour l'UI.
  String? get errorMessage => _error;
}

/// Helper : mappe un code Firebase vers un message (réutilisé par l'UI).
String authErrorMessage(Object error) => ErrorHandler.messageFrom(error);
