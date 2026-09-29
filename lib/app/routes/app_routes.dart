/// Nom des routes de l'application (routes nommées).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  /// Choix d'un nouveau mot de passe après ouverture du lien de récupération.
  static const String resetPassword = '/auth/reset';

  /// Premier réglage d'objectif après l'inscription.
  static const String onboardingSetup = '/onboarding-setup';

  // Rôles
  static const String userHome = '/home';
  static const String nutritionistHome = '/nutritionist/home';
  static const String adminHome = '/admin/home';

  /// Écran d'attente de vérification d'un nutritionniste.
  static const String nutritionistVerification =
      '/nutritionist/verification';

  // Fonctionnalités utilisateur
  static const String foods = '/foods';
  static const String foodSearch = '/foods/search';

  /// Accepte `arguments: foodId` (String).
  static const String foodDetail = '/foods/detail';
  static const String categories = '/categories';

  /// Accepte `arguments: {date, type}` (facultatif).
  static const String addMeal = '/meals/add';
  static const String journal = '/journal';
  static const String goals = '/goals';
  static const String weight = '/weight';
  static const String recommendations = '/recommendations';
  static const String notifications = '/notifications';

  /// « Mon coach » : nutritionniste choisi par le patient + accès au chat.
  static const String coach = '/coach';

  /// Choix d'un nutritionniste vérifié par le patient.
  static const String nutritionistPicker = '/coach/choose';
  static const String messaging = '/messaging';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
}
