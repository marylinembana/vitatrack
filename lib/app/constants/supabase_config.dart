/// Configuration Supabase (URL + clé *anon* publique).
///
/// La clé `anon` est publique : la sécurité est assurée par le RLS (Row Level
/// Security) côté Postgres, pas par la clé. On peut l'exposer dans le bundle
/// web/PWA en toute sécurité. Valeurs surchargeables au build via :
///   flutter build web \
///     --dart-define=SUPABASE_URL=... \
///     --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rhpgxussbmcscumgjkzd.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI'
        '6InJocGd4dXNzYm1jc2N1bWdqa3pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2MDQ'
        '5OTEsImV4cCI6MjEwNjE4MDk5MX0.s6xJAli712NoSjfHcZ332SQ9G4Z6mLMopRyIPqauDk8',
  );

  /// Clé *publishable* (format `sb_publishable_…`) recommandée par Supabase,
  /// alternative moderne à `anonKey`. Publique : la sécurité vient du RLS.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_l3-8h9VfM2WkqvAaV1s3LA_AZT0_J7q',
  );

  /// Bucket Storage public pour les images importées depuis l'appareil.
  static const String imageBucket = 'images';

  // Noms des tables Postgres (miroir des collectionsFirestore d'origine).
  static const tableProfiles = 'profiles';
  static const tableFoods = 'foods';
  static const tableCategories = 'categories';
  static const tableMeals = 'meals';
  static const tableWeightEntries = 'weight_entries';
  static const tableNutritionGoals = 'nutrition_goals';
  static const tableNutritionPlans = 'nutrition_plans';
  static const tableRecommendations = 'recommendations';
  static const tableNotifications = 'notifications';
  static const tableConversations = 'conversations';
  static const tableActivityLogs = 'activity_logs';
}
