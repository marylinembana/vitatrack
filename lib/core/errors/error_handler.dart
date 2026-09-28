import 'app_exception.dart';

/// Traduit les exceptions (Firebase, réseau, etc.) en messages compréhensibles.
class ErrorHandler {
  ErrorHandler._();

  static String messageFrom(Object error) {
    if (error is AppException) return error.message;
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Centralise le mapping des codes d'erreur Firebase Auth.
  static AppException fromFirebaseAuthCode(String? code) {
    return switch (code) {
      'invalid-email' => const AuthException('Email invalide.',
          code: 'invalid-email'),
      'user-disabled' => const AuthException('Ce compte a été désactivé.',
          code: 'user-disabled'),
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        const AuthException('Email ou mot de passe incorrect.',
            code: 'invalid-credential'),
      'email-already-in-use' => const AuthException(
          'Un compte existe déjà avec cet email.',
          code: 'email-already-in-use'),
      'weak-password' => const AuthException(
          'Mot de passe trop faible (6 caractères minimum).',
          code: 'weak-password'),
      'network-request-failed' => const NetworkException(),
      _ => AuthException('Erreur d\'authentification (${code ?? 'inconnue'}).'),
    };
  }
}
