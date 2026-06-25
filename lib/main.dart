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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only once
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

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