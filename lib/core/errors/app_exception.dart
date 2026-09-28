/// Exceptions applicatives de VitaTrack.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Élément introuvable']);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Erreur de connexion au serveur']);
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}
