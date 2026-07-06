// ============================================================
// lib/screens/splash_screen.dart
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EE),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // Logo
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Image.asset(
                    'assets/images/logochick.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // App Name
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontFamily: 'Kavoon',
                    fontSize: 38,
                    color: Color(0xFF1E2D4A),
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline
                const Text(
                  'Smart Poultry Management',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8A8A),
                  ),
                ),

                const SizedBox(height: 45),

                // Loading Indicator
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFD4C84E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}