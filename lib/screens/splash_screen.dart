// ============================================================
// lib/screens/splash_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _navigate(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              SizedBox(
                width: 220,
                height: 220,
                child: Image.asset(
                  'assets/images/logochick.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 12),

              // App Name
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: 'Kavoon',
                  fontSize: 38,
                  color: Color(0xFF1E2D4A),
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Smart Poultry Management',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A8A8A),
                ),
              ),

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => _navigate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4C84E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}