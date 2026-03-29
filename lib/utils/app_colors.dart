// ============================================================
// lib/utils/app_colors.dart  — REDESIGNED (Dark Navy Theme)
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Brand ─────────────────────────────────────────
  static const Color primary = Color(0xFF4DD9C0);
  static const Color primaryDark = Color(0xFF2BB8A0);
  static const Color primaryLight = Color(0xFF1A3A3A);

  // ── Backgrounds ───────────────────────────────────────────
  static const Color background = Color(0xFF0D1B2A);
  static const Color backgroundWarm = Color(0xFF112233);
  static const Color surface = Color(0xFF1A2E44);
  static const Color surfaceElevated = Color(0xFF1E3448);
  static const Color surfaceHighlight = Color(0xFF243D55);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4D8);
  static const Color textTertiary = Color(0xFF6B8CAE);
  static const Color textOnPrimary = Color(0xFF0D1B2A);

  // ── Borders ───────────────────────────────────────────────
  static const Color border = Color(0xFF1E3448);
  static const Color divider = Color(0xFF1A2E44);

  // ── Status ────────────────────────────────────────────────
  static const Color success = Color(0xFF4DD9C0);
  static const Color successLight = Color(0xFF0D2A25);
  static const Color warning = Color(0xFFF5A623);
  static const Color warningLight = Color(0xFF2A1F0A);
  static const Color error = Color(0xFFFF5252);
  static const Color errorLight = Color(0xFF2A0D0D);
  static const Color info = Color(0xFF4A9FFF);
  static const Color infoLight = Color(0xFF0D1A2A);

  // ── Devices ───────────────────────────────────────────────
  static const Color heatingActive = Color(0xFFFF6B35);
  static const Color coolingActive = Color(0xFF4DD9C0);
  static const Color feederActive = Color(0xFFF5A623);
  static const Color waterActive = Color(0xFF4A9FFF);

  // ── Alerts ────────────────────────────────────────────────
  static const Color alertCritical = Color(0xFFFF3B3B);
  static const Color alertWarning = Color(0xFFF5A623);
  static const Color alertInfo = Color(0xFF4A9FFF);

  // ── Misc ──────────────────────────────────────────────────
  static const Color shadow = Color(0x40000000);
  static const Color gradientTop = Color(0xFF0D1B2A);
  static const Color gradientBottom = Color(0xFF112233);
}