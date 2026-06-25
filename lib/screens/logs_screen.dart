// ============================================================
// lib/screens/logs_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import '../models/activity_log.dart';
import '../services/firebase_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
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
                child: CircularProgressIndicator(color: Colors.black54),
              );
            }

            final allLogs = snapshot.data ?? [];

            // Only show today's activity, oldest first (matches design).
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);

            final todayLogs = allLogs
                .where((l) => DateTime.fromMillisecondsSinceEpoch(l.timestamp)
                    .isAfter(todayStart))
                .toList()
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Activity Today',
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
                  ),
                ),

                // ── Empty state ────────────────────────────────
                if (todayLogs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Nothing has happened yet today.',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Activity list ──────────────────────────────
                if (todayLogs.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _ActivityCard(log: todayLogs[index]),
                        childCount: todayLogs.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Activity card ───────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final ActivityLog log;
  const _ActivityCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.timeLabel,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9A9A9A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            log.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}