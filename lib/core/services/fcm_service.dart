import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_bootstrap.dart';

/// Service gérant les notifications push via Firebase Cloud Messaging (FCM).
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
        if (_fcmToken != null && userId != null && userId.isNotEmpty) {
          await _saveTokenToUser(userId, _fcmToken!);
        }

        // Écoute du renouvellement de token
        messaging.onTokenRefresh.listen((newToken) async {
          _fcmToken = newToken;
          if (userId != null && userId.isNotEmpty) {
            await _saveTokenToUser(userId, newToken);
          }
        });

        // Écoute des messages en premier plan
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            print('Notification reçue (foreground) : ${message.notification?.title}');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur d\'initialisation FCM : $e');
      }
    }
  }

  /// Sauvegarde le token FCM dans le document de l'utilisateur dans Firestore.
  Future<void> _saveTokenToUser(String userId, String token) async {
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
