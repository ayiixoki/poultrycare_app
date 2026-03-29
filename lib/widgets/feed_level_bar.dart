// ============================================================
// lib/widgets/feed_level_bar.dart  — REDESIGNED (Dark Theme)
// ============================================================

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FeedLevelBar extends StatelessWidget {
  final double feedLevel;
  final double feedMax;

  const FeedLevelBar({
    super.key,
    required this.feedLevel,
    required this.feedMax,
  });

  double get _fraction =>
      feedMax > 0 ? (feedLevel / feedMax).clamp(0.0, 1.0) : 0.0;

  Color get _barColor {
    if (_fraction >= 0.60) return AppColors.success;
    if (_fraction >= 0.30) return AppColors.warning;
    return AppColors.error;
  }

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _barColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.grain_rounded,
                    color: _barColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feed Level',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _barColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: feedLevel.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(
                          text: ' kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'of ${feedMax.toStringAsFixed(0)} kg',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
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

          Text(
            '${(_fraction * 100).toStringAsFixed(0)}% remaining',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}