// ============================================================
// lib/screens/splash_screen.dart  — REDESIGNED
// ============================================================
// Dark navy gradient splash with logo image, app name,
// tagline, and "Get Started" button for first-time users.
// Returns to HomeScreen directly if already logged in.
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
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  // If user is already logged in, skip the splash and go home.
  bool _alreadyLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Check if already logged in — if so, auto-navigate after 1.5s
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _alreadyLoggedIn = true;
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Dark navy gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color.fromARGB(255, 43, 82, 123),
              Color.fromARGB(255, 157, 162, 168),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── Logo image ─────────────────────────────
                      // Uses your uploaded chicken logo
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: Image.asset(
                          'assets/images/logochick.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if logo.png not found yet
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                              ),
                              child: const Center(
                                child: Text(
                                  '🐔',
                                  style: TextStyle(fontSize: 80),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── App name ───────────────────────────────
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Tagline ────────────────────────────────
                      Text(
                        'Smart Poultry Management',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(1.0),
                          letterSpacing: 0.3,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // ── Get Started button or loading indicator ─
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _alreadyLoggedIn
                            ? Column(
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: _goToLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.background,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0D1B2A),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}