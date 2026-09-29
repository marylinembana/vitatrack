import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/constants/supabase_config.dart';

/// Initialise le client Supabase (Auth + PostgREST + Storage).
/// Doit être appelé avant tout usage de [Supabase.instance].
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool ready = false;
  static Object? lastError;

  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
        debug: kDebugMode,
      );
      ready = true;
    } catch (e) {
      ready = false;
      lastError = e;
      if (kDebugMode) {
        debugPrint('Supabase init echoue : $e');
      }
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
