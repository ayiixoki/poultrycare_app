// ============================================================
// lib/utils/app_colors.dart
// ============================================================
// Defines the entire color palette for PoultryCare.
// White-based UI with warm amber/golden "poultry farm" accents.
//
// HOW TO USE:
//   import 'package:poultrycare_app/utils/app_colors.dart';
//   color: AppColors.primary
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor — this class should never be instantiated.
  AppColors._();

  // ── Primary Brand Colors ──────────────────────────────────────────────────
  /// Golden amber — the main brand color, inspired by corn/feed and sunlight.
  static const Color primary = Color(0xFFE8A020);

  /// Darker shade of primary, used for pressed states or headers.
  static const Color primaryDark = Color(0xFFC67C10);

  /// Very light amber tint — used for card highlights and subtle backgrounds.
  static const Color primaryLight = Color(0xFFFFF3DC);

  // ── Secondary / Accent Colors ─────────────────────────────────────────────
  /// Farm green — used for "active / healthy / online" indicators.
  static const Color success = Color(0xFF4CAF50);

  /// Light green — used for success badges and icon backgrounds.
  static const Color successLight = Color(0xFFE8F5E9);

  /// Alert orange — used for heating lamp / warnings.
  static const Color warning = Color(0xFFFF6B35);

  /// Light orange tint — used for warning badge backgrounds.
  static const Color warningLight = Color(0xFFFFF0EA);

  /// Error red — used for critical alerts (high temperature, empty feed).
  static const Color error = Color(0xFFEF4444);

  /// Light red tint — used for error badge backgrounds.
  static const Color errorLight = Color(0xFFFEE2E2);

  /// Info blue — used for informational log entries.
  static const Color info = Color(0xFF3B82F6);

  /// Light blue tint — used for info badge backgrounds.
  static const Color infoLight = Color(0xFFEFF6FF);

  // ── Background & Surface Colors ───────────────────────────────────────────
  /// Main app background — pure white.
  static const Color background = Color(0xFFFFFFFF);

  /// Slightly warm white — used for screen body backgrounds.
  static const Color backgroundWarm = Color(0xFFFAF8F4);

  /// Card / container surface — off-white with a warm tint.
  static const Color surface = Color(0xFFFFFBF0);

  /// Elevated card surface — used when a card needs to stand out more.
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ── Text Colors ───────────────────────────────────────────────────────────
  /// Primary text — near-black, used for titles and body text.
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Secondary text — medium grey, used for subtitles and descriptions.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Tertiary text — light grey, used for hints and timestamps.
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Text on primary (on amber buttons) — dark so it's readable.
  static const Color textOnPrimary = Color(0xFF1A1A1A);

  // ── Border & Divider Colors ───────────────────────────────────────────────
  /// Standard border — light warm grey for cards and inputs.
  static const Color border = Color(0xFFE5DDD0);

  /// Lighter divider — used inside cards between rows.
  static const Color divider = Color(0xFFF0EBE0);

  // ── Device State Colors ───────────────────────────────────────────────────
  /// Heating lamp active — warm red-orange glow.
  static const Color heatingActive = Color(0xFFFF6B35);

  /// Cooling fan active — cool teal-blue.
  static const Color coolingActive = Color(0xFF06B6D4);

  /// Feeder active — golden yellow.
  static const Color feederActive = Color(0xFFF59E0B);

  /// Water dispenser active — blue.
  static const Color waterActive = Color(0xFF3B82F6);

  // ── Shadow ────────────────────────────────────────────────────────────────
  /// Soft shadow for cards — warm-tinted drop shadow.
  static const Color shadow = Color(0x1AE8A020);
}