// ============================================================
// lib/main.dart
// ============================================================
// Entry point for PoultryCare Flutter app.
//
// Responsibilities:
//   1. Initialize Firebase before runApp()
//   2. Configure MaterialApp with our custom theme
//   3. Start on SplashScreen (which routes to Login or Home)
//
// IMPORTANT: You must have already run:
//   flutter fire configure
// ...and have a valid google-services.json (Android) and
// GoogleService-Info.plist (iOS) in the correct folders.
// See FIREBASE_SETUP.md for the complete setup guide.
// ============================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/notification_service.dart';

// ── Firebase generated options (created by flutter fire configure) ─────────────
// This file is auto-generated — do NOT manually edit it.
// Re-run `flutter fire configure` if you change Firebase projects.
import 'firebase_options.dart';

import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

// Must match the channel ID in AndroidManifest.xml exactly.
const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
  'poultrycare_alerts',
  'PoultryCare Alerts',
  description: 'Notifications for low feed, low water, and temperature alerts.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No local notification display needed here — Android shows FCM
  // "notification" payloads automatically when the app isn't running.
  // This handler exists so Firebase doesn't log a warning, and gives
  // you a place to add background data-processing later if needed.
}

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only once
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Enable realtime database offline persistence.
  FirebaseDatabase.instance.setPersistenceEnabled(true);

  // Create the Android notification channel (required for Android 8+).
    await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  // Initialize the local notifications plugin so we can display
  // a banner when a push arrives while the app is in the foreground.
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await localNotifications.initialize(initSettings);

  // Register the background message handler (must happen before runApp).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request permission, get the FCM token, and save it to Firebase.
  await NotificationService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PoultryCareApp());
}

// ── Root widget ───────────────────────────────────────────────────────────────
class PoultryCareApp extends StatelessWidget {
  const PoultryCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── App metadata ──────────────────────────────────────────────
      title: 'PoultryCare',

      // ── Removes the debug banner from the top-right corner ────────
      debugShowCheckedModeBanner: false,

      // ── Apply our custom white/amber theme ────────────────────────
      theme: AppTheme.light,

      // ── Start on the splash screen ────────────────────────────────
      // SplashScreen will route to Login or Home based on auth state.
      home: const SplashScreen(),
    );
  }
}