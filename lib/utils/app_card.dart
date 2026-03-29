// ============================================================
// lib/widgets/app_card.dart
// ============================================================
// Reusable card widget with consistent styling
// ============================================================

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = 0,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation,
      color: backgroundColor ?? AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}