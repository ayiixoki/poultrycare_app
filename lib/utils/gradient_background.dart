// lib/utils/gradient_background.dart
// Wrap any screen body with this to apply the gradient.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientTop,    // dark navy
            AppColors.gradientMid,    // medium blue
            AppColors.gradientBottom, // light grey-blue
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}