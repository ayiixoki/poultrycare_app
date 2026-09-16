// ============================================================
// lib/screens/logs_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_log.dart';
import '../services/firebase_service.dart';

String _roundDecimals(String text) {
  final regex = RegExp(r'\d+\.\d+');
  return text.replaceAllMapped(regex, (match) {
    final value = double.parse(match.group(0)!);
    return value.round().toString();
  });
}

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  Future<void> _confirmClearAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all logs?'),
        content: const Text(
          'This will delete every log entry. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService().clearAllLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7DF),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<ActivityLog>>(
          stream: FirebaseService().logsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.black54,
                ),
              );
            }

            final allLogs = snapshot.data ?? [];

            // Sort logs: newest first
            allLogs.sort(
              (a, b) => b.timestamp.compareTo(a.timestamp),
            );

            // ── Date references ───────────────────────────────
            final now = DateTime.now();

            final todayStart = DateTime(
              now.year,
              now.month,
              now.day,
            );

            final yesterdayStart = todayStart.subtract(
              const Duration(days: 1),
            );

            // ── Group logs by date ─────────────────────────────
            final Map<String, List<ActivityLog>> groupedLogs = {};

            for (final log in allLogs) {
              final logDate =
                  DateTime.fromMillisecondsSinceEpoch(log.timestamp);

              final logDay = DateTime(
                logDate.year,
                logDate.month,
                logDate.day,
              );

              String sectionTitle;

              // Today
              if (logDay == todayStart) {
                sectionTitle = 'Today';
              }

              // Yesterday
              else if (logDay == yesterdayStart) {
                sectionTitle = 'Yesterday';
              }

              // Older dates
              else {
                sectionTitle =
                    DateFormat('MMMM d, yyyy').format(logDay);
              }

              groupedLogs.putIfAbsent(
                sectionTitle,
                () => [],
              );

              groupedLogs[sectionTitle]!.add(log);
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activity Log',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Everything that happened in the poultry',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _confirmClearAll(context),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Empty state ───────────────────────────────
                if (groupedLogs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Nothing has happened yet.',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Grouped activity logs ─────────────────────
                if (groupedLogs.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sectionTitle =
                              groupedLogs.keys.elementAt(index);

                          final logs =
                              groupedLogs[sectionTitle]!;

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // ── Date heading ────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  4,
                                  12,
                                  4,
                                  10,
                                ),
                                child: Text(
                                  sectionTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),

                              // ── Logs under this date ─────────
                              ...logs.map(
                                (log) => _ActivityCard(log: log),
                              ),
                            ],
                          );
                        },
                        childCount: groupedLogs.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Activity Card
// ============================================================

class _ActivityCard extends StatelessWidget {
  final ActivityLog log;

  const _ActivityCard({
    required this.log,
  });

  Color _borderColor(LogType type) {
    switch (type) {
      case LogType.alert:
        return Colors.red.shade300;

      case LogType.climate:
        return Colors.green.shade300;

      case LogType.feeding:
        return Colors.orange.shade300;

      case LogType.water:
        return Colors.blue.shade300;

      case LogType.info:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor(log.type),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Text(
            log.timeLabel,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9A9A9A),
            ),
          ),

          const SizedBox(height: 4),

          // Title
          Text(
            log.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 6),

          // Message
          Text(
            _roundDecimals(log.message),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF707070),
            ),
          ),
        ],
      ),
    );
  }
}