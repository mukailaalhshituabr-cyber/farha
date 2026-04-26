// lib/data/services/notification_service.dart
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Must be top-level for Firebase background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background FCM messages are shown automatically by the OS.
  debugPrint('FCM background: ${message.notification?.title}');
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'farha_messages';
  static const _channelName = 'Farha Messages';

  final FirebaseMessaging _fcm;

  NotificationService() : _fcm = FirebaseMessaging.instance;

  // ── One-time app init ────────────────────────────────────────────────────
  Future<void> init() async {
    // Local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 8+ notification channel
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Messages from Farha users',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      ),
    );

    // FCM: background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // FCM: request permission
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _fcm.getToken();
      debugPrint('FCM token: $token');
    }

    // FCM token refresh
    _fcm.onTokenRefresh.listen((t) => debugPrint('FCM token refresh: $t'));

    // Show a local notification banner when an FCM message arrives FOREGROUND
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        showMessage(
          title: n.title ?? 'New message',
          body:  n.body  ?? '',
        );
      }
    });
  }

  // ── Show a local notification ────────────────────────────────────────────
  static Future<void> showMessage({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance:       Importance.high,
          priority:         Priority.high,
          playSound:        true,
          enableVibration:  true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          icon:             '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
