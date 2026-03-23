// ============================================================
// lib/widgets/sensor_card.dart
// ============================================================
// A small reusable card that displays a single sensor reading
// (e.g., Temperature, Humidity, Feed Level).
//
// USAGE:
//   SensorCard(
//     icon: Icons.thermostat,
//     iconColor: AppColors.warning,
//     label: 'Temperature',
//     value: '30.5',
//     unit: '°C',
//     subtitle: 'Normal',
//     statusColor: AppColors.success,
//   )
// ============================================================

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class SensorCard extends StatelessWidget {
  /// Icon shown on the left side of the card.
  final IconData icon;

  /// Color of the icon and its circular background.
  final Color iconColor;

  /// Small label above the value, e.g. "Temperature"
  final String label;

  /// The main numeric or text reading, e.g. "30.5"
  final String value;

  /// Unit appended next to value, e.g. "°C", "%", "kg"
  final String unit;

  /// Status text shown below the value, e.g. "Normal", "High"
  final String subtitle;

  /// Color of the status dot/text — green for normal, red for alert.
  final Color statusColor;

  const SensorCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    // Each card is contained in a styled Box — no Card widget
    // so we can control borders and shadows precisely.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon circle + label row ───────────────────────────────────
          Row(
            children: [
              // Circular colored icon background
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              // Label text
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Main value display ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Large number
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 4),
              // Unit label aligned to the bottom of the number
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Status badge row ──────────────────────────────────────────
          Row(
            children: [
              // Small colored dot indicator
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}