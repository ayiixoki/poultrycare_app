// ============================================================
// lib/widgets/feed_level_bar.dart
// ============================================================
// Displays the feed level as an animated horizontal progress bar
// with a color that changes based on how full the hopper is.
//
// Green  → 60% – 100% (plenty of feed)
// Amber  → 30% – 59%  (getting low)
// Red    → 0%  – 29%  (critical — needs refill)
//
// USAGE:
//   FeedLevelBar(
//     feedLevel: 1.5,   // kg remaining
//     feedMax: 5.0,     // kg total capacity
//   )
// ============================================================

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FeedLevelBar extends StatelessWidget {
  /// Current feed level in kilograms.
  final double feedLevel;

  /// Maximum hopper capacity in kilograms.
  final double feedMax;

  const FeedLevelBar({
    super.key,
    required this.feedLevel,
    required this.feedMax,
  });

  // ── Fraction 0.0 → 1.0 ───────────────────────────────────────────────────
  double get _fraction => feedMax > 0 ? (feedLevel / feedMax).clamp(0.0, 1.0) : 0.0;

  // ── Choose bar color based on level ──────────────────────────────────────
  Color get _barColor {
    if (_fraction >= 0.60) return AppColors.success;
    if (_fraction >= 0.30) return AppColors.primary; // amber
    return AppColors.error;
  }

  // ── Choose label ─────────────────────────────────────────────────────────
  String get _statusLabel {
    if (_fraction >= 0.60) return 'Feed OK';
    if (_fraction >= 0.30) return 'Getting Low';
    return 'Refill Needed!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _barColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.grain, color: _barColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feed Level',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      _statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _barColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              // Right side: kg reading
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: feedLevel.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                        ),
                        TextSpan(
                          text: ' kg',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'of ${feedMax.toStringAsFixed(0)} kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Progress Bar ──────────────────────────────────────────────
          // ClipRRect clips the bar to rounded corners.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              // Animates the bar fill smoothly when the value changes.
              tween: Tween(begin: 0, end: _fraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(_barColor),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Percentage label ──────────────────────────────────────────
          Text(
            '${(_fraction * 100).toStringAsFixed(0)}% remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}