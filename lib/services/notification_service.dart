import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // add this if debugPrint isn't recognized
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart' show localNotifications, alertChannel;
import 'firebase_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      await _messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('FCM permission request failed/timed out: $e');
    }

    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 8));
      if (token != null) {
        await FirebaseService().saveDeviceToken(token);
      }
    } catch (e) {
      debugPrint('FCM getToken failed/timed out: $e');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseService().saveDeviceToken(newToken);
    });

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