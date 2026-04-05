import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get and store FCM token
      final token = await _messaging.getToken();
      if (token != null && AuthService.uid.isNotEmpty) {
        await _saveFcmToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFcmToken);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Could show a local notification here
    });
  }

  static Future<void> _saveFcmToken(String token) async {
    if (AuthService.uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(AuthService.uid)
        .update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
