import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// Initialise Firebase Core **uniquement pour le push (FCM)**.
/// L'authentification, les données et le stockage d'images sont désormais
/// gérés par Supabase. Si Firebase n'est pas disponible, l'app fonctionne
/// quand même (le push est simplement désactivé).
class FirebaseBootstrap {
  FirebaseBootstrap._();
  static bool ready = false;
  static Object? lastError;

  static Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      ready = true;
    } catch (e) {
      ready = false;
      lastError = e;
    }
  }
}
