import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();
  static bool ready = false;
  static Object? lastError;

  static Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      FirebaseAuth.instance;
      FirebaseFirestore.instance;
      ready = true;
    } catch (e) {
      ready = false;
      lastError = e;
    }
  }
}
