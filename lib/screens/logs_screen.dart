// ============================================================
// lib/screens/logs_screen.dart
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
  LogType? _filterType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: StreamBuilder<List<ActivityLog>>(
          stream: FirebaseService().logsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final allLogs = snapshot.data ?? [];
            final unreadCount = allLogs.where((l) => !l.isRead).length;

            final logs = _filterType == null
                ? allLogs
                : allLogs.where((l) => l.type == _filterType).toList();

            // Group by date
            final today = <ActivityLog>[];
            final yesterday = <ActivityLog>[];
            final older = <ActivityLog>[];

            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final yesterdayStart =
                todayStart.subtract(const Duration(days: 1));

            for (final log in logs) {
              final dt =
                  DateTime.fromMillisecondsSinceEpoch(log.timestamp);
              if (dt.isAfter(todayStart)) {
                today.add(log);
              } else if (dt.isAfter(yesterdayStart)) {
                yesterday.add(log);
              } else {
                older.add(log);
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Alerts',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    unreadCount > 0
                                        ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                                        : '0 unread notifications',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => FirebaseService().markAllLogsRead(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: unreadCount > 0 
                                      ? const Color(0xFFB8F5B0)  // ← light green when has notifs
                                      : Colors.white, 
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.border),
                                  ),
                                  child: const Text(
                                    'Mark As All Read',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Filter chips ───────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 35,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _filterType == null,
                          onTap: () =>
                              setState(() => _filterType = null),
                          color: Colors.black,
                        ),
                        const SizedBox(width: 4),
                        _FilterChip(
                          label: 'Alerts',
                          isSelected: _filterType == LogType.alert,
                          onTap: () => setState(
                              () => _filterType = LogType.alert),
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        _FilterChip(
                          label: 'Feeding',
                          isSelected: _filterType == LogType.feeding,
                          onTap: () => setState(
                              () => _filterType = LogType.feeding),
                          color: AppColors.feederActive,
                        ),
                        const SizedBox(width: 4),
                        _FilterChip(
                          label: 'Climate',
                          isSelected: _filterType == LogType.climate,
                          onTap: () => setState(
                              () => _filterType = LogType.climate),
                          color: AppColors.heatingActive,
                        ),
                        const SizedBox(width: 4),
                        _FilterChip(
                          label: 'Water',
                          isSelected: _filterType == LogType.water,
                          onTap: () => setState(
                              () => _filterType = LogType.water),
                          color: AppColors.waterActive,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Empty state ────────────────────────────────
                if (logs.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 56,
                              color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          const Text(
                            'No alerts yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'System activity will appear here.',
                            style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Today ──────────────────────────────────────
                if (today.isNotEmpty) ...[
                  _SectionHeader(label: 'TODAY'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _LogTile(log: today[index]),
                      childCount: today.length,
                    ),
                  ),
                ],

                // ── Yesterday ──────────────────────────────────
                if (yesterday.isNotEmpty) ...[
                  _SectionHeader(label: 'YESTERDAY'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _LogTile(log: yesterday[index]),
                      childCount: yesterday.length,
                    ),
                  ),
                ],

                // ── Older ──────────────────────────────────────
                if (older.isNotEmpty) ...[
                  _SectionHeader(label: 'OLDER'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _LogTile(log: older[index]),
                      childCount: older.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                    child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ── Log tile ───────────────────────────────────────────────────
class _LogTile extends StatelessWidget {
  final ActivityLog log;
  const _LogTile({required this.log});

  Color get _color {
    switch (log.type) {
      case LogType.alert:
        return AppColors.error;
      case LogType.feeding:
        return AppColors.feederActive;
      case LogType.climate:
        return AppColors.heatingActive;
      case LogType.water:
        return AppColors.waterActive;
      default:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (log.type) {
      case LogType.alert:
        return Icons.warning_rounded;
      case LogType.feeding:
        return Icons.grain_rounded;
      case LogType.climate:
        return Icons.thermostat_rounded;
      case LogType.water:
        return Icons.water_drop_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
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
                const SizedBox(height: 4),
                Text(
                  log.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  log.timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────
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
            const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}