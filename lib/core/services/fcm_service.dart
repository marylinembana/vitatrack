import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_bootstrap.dart';

/// Service gérant les notifications push via Firebase Cloud Messaging (FCM).
/// Firebase n'est utilisé ici que pour le push ; l'authentification, les
/// données et les images sont gérés par Supabase.
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  String? _fcmToken;
  String? get token => _fcmToken;

  /// Initialise FCM si Firebase est prêt.
  Future<void> init(String? userId) async {
    if (!FirebaseBootstrap.ready) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // Demande de permission (Web, iOS, Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Récupération du token
        _fcmToken = await messaging.getToken();
        if (kDebugMode && _fcmToken != null) {
          debugPrint('FCM token (${userId ?? '-'}): $_fcmToken');
        }

        // Écoute du renouvellement de token
        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
        });

        // Écoute des messages en premier plan
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            debugPrint('Notification reçue (foreground) : ${message.notification?.title}');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur d\'initialisation FCM : $e');
      }
    }
  }
}
