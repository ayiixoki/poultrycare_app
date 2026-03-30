// ============================================================
// lib/widgets/schedule_tile.dart
// ============================================================
// Displays a single FeedingSchedule entry in a styled list tile.
// Shows the time, label, days, amount, and an enable/disable toggle.
//
// The farmer can tap the toggle to activate/deactivate a schedule
// without deleting it.
//
// USAGE:
//   ScheduleTile(
//     schedule: mySchedule,
//     onToggle: (enabled) => db.toggleSchedule(id, enabled),
//     onEdit: () => _showEditSheet(mySchedule),
//     onDelete: () => db.deleteSchedule(id),
//   )
// ============================================================

import 'package:flutter/material.dart';
import '../models/feeding_schedule.dart';
import '../utils/app_colors.dart';

class ScheduleTile extends StatelessWidget {
  /// The schedule to display.
  final FeedingSchedule schedule;

  /// Called when the enable/disable toggle is flipped.
  final ValueChanged<bool> onToggle;

  /// Called when the user taps "Edit".
  final VoidCallback onEdit;

  /// Called when the user taps "Delete".
  final VoidCallback onDelete;

  const ScheduleTile({
    super.key,
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  // ── Parse HH:mm → 12-hour display string ─────────────────────────────────
  String get _displayTime {
    final parts = schedule.time.split(':');
    if (parts.length != 2) return schedule.time;
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '$hour:$min $period';
  }

  // ── Build shortened day chips ("Mon · Wed · Fri") ─────────────────────────
  String get _daysLabel {
    // If all 7 days are selected, just show "Every Day"
    if (schedule.days.length == 7) return 'Every Day';
    // If Mon–Fri only, show "Weekdays"
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    if (schedule.days.toSet().containsAll(weekdays) &&
        !schedule.days.contains('Sat') &&
        !schedule.days.contains('Sun')) {
      return 'Weekdays';
    }
    return schedule.days.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: schedule.enabled ? AppColors.surfaceElevated : AppColors.backgroundWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: schedule.enabled ? const Color.fromARGB(255, 137, 137, 137).withOpacity(0.25) : const Color.fromARGB(255, 206, 206, 206),
        ),
        boxShadow: schedule.enabled
            ? [const BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Time block ───────────────────────────────────────────────
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: schedule.enabled
                    ? AppColors.primaryLight
                    : const Color.fromARGB(255, 52, 52, 52).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    _displayTime.split(' ')[0], // "6:00"
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: schedule.enabled
                              ? AppColors.primaryDark
                              : AppColors.textTertiary,
                        ),
                  ),
                  Text(
                    _displayTime.split(' ').length > 1
                        ? _displayTime.split(' ')[1]
                        : '', // "AM" or "PM"
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: schedule.enabled
                              ? AppColors.primaryDark
                              : AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ── Info column ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: schedule.enabled
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _daysLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // Amount chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9CD31),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${schedule.amountGrams}g of feed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions column (toggle + popup menu) ─────────────────────
            Column(
              children: [
                // Enable / Disable toggle
                Switch(
                  value: schedule.enabled,
                  onChanged: onToggle,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                // More options (edit, delete) via popup menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF000000),),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}