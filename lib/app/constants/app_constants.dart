/// Constantes générales de l'application.
class AppConstants {
  AppConstants._();

  static const String appName = 'VitaTrack';
  static const String appTagline = 'Votre santé nutritionnelle, simplement';

  // Objectifs caloriques par défaut
  static const double defaultCalorieGoalLoss = 1600;
  static const double defaultCalorieGoalMaintain = 2200;
  static const double defaultCalorieGoalGain = 2600;

  // Répartition des macros (%).
  static const double proteinRatio = 0.30;
  static const double carbRatio = 0.45;
  static const double fatRatio = 0.25;

  // Journal
  static const int weekDays = 7;

  // Clés de stockage local (préfixe des clés SharedPreferences).
  static const String storagePrefix = 'vitatrack_';
}

/// Rôles disponibles dans l'application.
class UserRole {
  UserRole._();

  static const String user = 'user';
  static const String nutritionist = 'nutritionist';
  static const String admin = 'admin';
}

/// Types de repas.
class MealType {
  MealType._();

  static const String breakfast = 'Petit-déjeuner';
  static const String lunch = 'Déjeuner';
  static const String dinner = 'Dîner';
  static const String snack = 'Collation';

  static const List<String> all = [breakfast, lunch, dinner, snack];
}
