// ============================================================
// lib/screens/splash_screen.dart
// ============================================================
// Shown for ~2 seconds when the app launches.
// Checks if a user is already logged in via Firebase Auth.
//   • If logged in  → navigate to HomeScreen
//   • If not logged in → navigate to LoginScreen
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for the logo fade-in + scale effect.
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // ── Set up entrance animation ──────────────────────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Start animation immediately.
    _controller.forward();

    // After a short delay, determine where to navigate.
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  /// Checks Firebase Auth state and routes to the correct screen.
  void _navigate() {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user != null ? const HomeScreen() : const LoginScreen(),
        // Fade transition when leaving splash.
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warm white background matching the overall theme.
      backgroundColor: AppColors.backgroundWarm,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── App Logo ───────────────────────────────────────
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryDark,
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      // Chicken emoji as the logo icon.
                      child: const Center(
                        child: Text('🐔', style: TextStyle(fontSize: 48)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── App Name ───────────────────────────────────────
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontSize: 32),
                    ),

                    const SizedBox(height: 8),

                    // ── Tagline ────────────────────────────────────────
                    Text(
                      AppConstants.appTagline,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 48),

                    // ── Loading indicator ──────────────────────────────
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}