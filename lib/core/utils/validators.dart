/// Validateurs de formulaires.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(
    r'^[\w.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
  );

  static String? required(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) return '$field est requis';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'L\'email est requis';
    if (!_email.hasMatch(v)) return 'Email invalide';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Le mot de passe est requis';
    if (v.length < 6) return 'Au moins 6 caractères';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'La valeur'}) {
    final v = double.tryParse(value?.trim() ?? '');
    if (v == null) return '$field doit être un nombre';
    if (v <= 0) return '$field doit être positif';
    return null;
  }

  static String? weight(String? value) {
    final v = double.tryParse(value?.trim() ?? '');
    if (v == null) return 'Poids invalide';
    if (v < 20 || v > 300) return 'Le poids doit être entre 20 et 300 kg';
    return null;
  }

  static String? age(String? value) {
    final v = int.tryParse(value?.trim() ?? '');
    if (v == null) return 'Âge invalide';
    if (v < 10 || v > 100) return 'L\'âge doit être entre 10 et 100 ans';
    return null;
  }
}
