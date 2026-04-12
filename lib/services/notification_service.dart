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
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _messaging.getToken();
        if (token != null && AuthService.uid.isNotEmpty) {
          await _saveFcmToken(token);
        }
        await subscribeToTopics();
        _messaging.onTokenRefresh.listen(_saveFcmToken);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _onForegroundMessage?.call(message);
      });
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  static Future<void> subscribeToTopics() async {
    try {
      final society = PrefsService.societyName.replaceAll(' ', '_').toLowerCase();
      if (society.isNotEmpty) {
        await _messaging.subscribeToTopic('society_$society');
      }
      final flat = PrefsService.userFlat.replaceAll(' ', '_').toLowerCase();
      if (flat.isNotEmpty) {
        await _messaging.subscribeToTopic('flat_${society}_$flat');
      }
    } catch (e) {
      debugPrint('NotificationService.subscribeToTopics error: $e');
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
    try {
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage, navigatorKey);
      }
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleMessageTap(message, navigatorKey);
      });
    } catch (e) {
      debugPrint('NotificationService.setupInteractiveMessage error: $e');
    }
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
