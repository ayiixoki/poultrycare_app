// ============================================================
// lib/services/notification_service.dart
// ============================================================
// Handles FCM permission requests, token retrieval/storage,
// and displaying notifications while the app is in the
// foreground. Background/closed-app notifications are shown
// automatically by Android using the channel set up in main.dart.
// ============================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart' show localNotifications, alertChannel;
import 'firebase_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once, at app startup. Requests permission, gets the device's
  /// FCM token, saves it to Firebase, and wires up foreground display.
  static Future<void> init() async {
    // 1. Ask the user for notification permission (Android 13+ requires this).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Get this device's unique FCM token.
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseService().saveDeviceToken(token);
    }

    // 3. If the token ever changes (reinstall, app data cleared, etc.),
    // keep Firebase updated so the Pi always has a working token.
    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseService().saveDeviceToken(newToken);
    });

    // 4. Show a visible banner when a push arrives while the app is OPEN.
    // (Android shows background/closed notifications automatically —
    // this listener only covers the foreground case.)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              alertChannel.id,
              alertChannel.name,
              channelDescription: alertChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }
}