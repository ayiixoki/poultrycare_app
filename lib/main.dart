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

// ── Firebase generated options (created by flutter fire configure) ─────────────
// This file is auto-generated — do NOT manually edit it.
// Re-run `flutter fire configure` if you change Firebase projects.
import 'firebase_options.dart';

import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // ── 1. Ensure Flutter engine is initialized before calling platform code ──
  // Required when calling platform channels (like Firebase) before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. Lock the app to portrait mode ──────────────────────────────────────
  // A farm monitoring app doesn't need landscape mode.
  try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
} catch (e) {
  // Ignore duplicate app error on hot restart
}

  // ── 3. Style the system status bar ────────────────────────────────────────
  // Makes the status bar transparent so the app content shows through.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── 4. Initialize Firebase ────────────────────────────────────────────────
  // This MUST be called before any Firebase service is used.
  // It reads your google-services.json / GoogleService-Info.plist.
  if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

  // ── 5. Launch the app ─────────────────────────────────────────────────────
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