import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../utils/prefs_service.dart';
import '../screens/complaints/complaints_screen.dart';
import '../screens/notices/notices_screen.dart';
import '../screens/visitors/visitors_screen.dart';
import '../screens/bills/bills_screen.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Function(RemoteMessage)? _onForegroundMessage;
  static set onForegroundMessage(Function(RemoteMessage) callback) {
    _onForegroundMessage = callback;
  }

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

      // Subscribe to relevant topics
      await subscribeToTopics();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFcmToken);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _onForegroundMessage?.call(message);
    });
  }

  static Future<void> subscribeToTopics() async {
    final society = PrefsService.societyName.replaceAll(' ', '_').toLowerCase();
    if (society.isNotEmpty) {
      await _messaging.subscribeToTopic('society_$society');
    }
    final flat = PrefsService.userFlat.replaceAll(' ', '_').toLowerCase();
    if (flat.isNotEmpty) {
      await _messaging.subscribeToTopic('flat_${society}_$flat');
    }
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

  /// Call after the MaterialApp is built so the navigator is ready.
  static Future<void> setupInteractiveMessage(
      GlobalKey<NavigatorState> navigatorKey) async {
    // App opened from terminated state via notification tap
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage, navigatorKey);
    }

    // App was in background and notification was tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageTap(message, navigatorKey);
    });
  }

  static void _handleMessageTap(
      RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    final data = message.data;
    final type = data['type'] as String?;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (type) {
      case 'complaint':
        navigator.push(
            MaterialPageRoute(builder: (_) => const ComplaintsScreen()));
        break;
      case 'notice':
        navigator
            .push(MaterialPageRoute(builder: (_) => const NoticesScreen()));
        break;
      case 'visitor':
        navigator
            .push(MaterialPageRoute(builder: (_) => const VisitorsScreen()));
        break;
      case 'bill':
        navigator
            .push(MaterialPageRoute(builder: (_) => const BillsScreen()));
        break;
    }
  }
}
