// ============================================================
// lib/screens/logs_screen.dart
// ============================================================
// Tab 3: Logs / Activity History
// Shows the latest 50 activity log entries from Firebase.
// Entries are categorized as: Feeding, Alert, Climate, Water, Info.
// The farmer can filter by type using chips at the top.
// ============================================================

import 'package:flutter/material.dart';
import '../models/activity_log.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // null means "show all types"
  LogType? _filterType;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityLog>>(
      stream: FirebaseService().logsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLogs = snapshot.data ?? [];

        // Apply filter
        final logs = _filterType == null
            ? allLogs
            : allLogs.where((l) => l.type == _filterType).toList();

        return Column(
          children: [
            // ── Header + filter chips ─────────────────────────────────
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Activity Log',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            Text('${allLogs.length} total entries',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      // Mark all read button
                      TextButton.icon(
                        onPressed: () => FirebaseService().markAllLogsRead(),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Mark all read'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Filter chips row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _filterType == null,
                          onTap: () => setState(() => _filterType = null),
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Alerts',
                          isSelected: _filterType == LogType.alert,
                          onTap: () =>
                              setState(() => _filterType = LogType.alert),
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Feeding',
                          isSelected: _filterType == LogType.feeding,
                          onTap: () =>
                              setState(() => _filterType = LogType.feeding),
                          color: AppColors.feederActive,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Climate',
                          isSelected: _filterType == LogType.climate,
                          onTap: () =>
                              setState(() => _filterType = LogType.climate),
                          color: AppColors.heatingActive,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Water',
                          isSelected: _filterType == LogType.water,
                          onTap: () =>
                              setState(() => _filterType = LogType.water),
                          color: AppColors.waterActive,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Log list ──────────────────────────────────────────────
            Expanded(
              child: logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📋',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text('No logs yet',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Activity from the system will\nappear here.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const Divider(
                        indent: 72,
                        endIndent: 16,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        return _LogTile(log: logs[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Individual log tile ───────────────────────────────────────────────────────
class _LogTile extends StatelessWidget {
  final ActivityLog log;
  const _LogTile({required this.log});

  // Return emoji icon for the log type.
  String get _emoji {
    switch (log.type) {
      case LogType.feeding:  return '🌾';
      case LogType.alert:    return '🌡️';
      case LogType.climate:  return '💡';
      case LogType.water:    return '💧';
      default:               return '📡';
    }
  }

  // Return color for the log type badge.
  Color get _color {
    switch (log.type) {
      case LogType.feeding:  return AppColors.feederActive;
      case LogType.alert:    return AppColors.error;
      case LogType.climate:  return AppColors.heatingActive;
      case LogType.water:    return AppColors.waterActive;
      default:               return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Emoji icon with colored circle ────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(_emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(width: 12),

          // ── Title, message, timestamp ─────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontSize: 14,
                                color: log.type == LogType.alert
                                    ? AppColors.error
                                    : null),
                      ),
                    ),
                    // Unread dot
                    if (!log.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  log.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.timeLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip widget ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}