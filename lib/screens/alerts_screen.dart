// ============================================================
// lib/screens/climate_screen.dart — Alerts Screen
// ============================================================
// Shows recent farm notifications and alerts based on sensor data.
// All alerts are dynamically generated from Firebase sensor values.
//
// Alert types:
//   • Temperature alerts (too hot/too cold)
//   • Water level alerts
//   • Feed level alerts
//   • Feeding completion notifications
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class ClimateScreen extends StatelessWidget {
  const ClimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData>(
      stream: FirebaseService().sensorStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? const SensorData();
        final alerts = _generateAlerts(data);

        return Container(
          color: const Color(0xFFF5F5F5),
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alerts',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recent farm notifications',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Empty state ───────────────────────────────────
              if (alerts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✓', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const Text(
                          'All systems normal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No alerts at this time.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Alerts list ───────────────────────────────────
              if (alerts.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _AlertCard(alert: alerts[index]),
                    childCount: alerts.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        );
      },
    );
  }

  List<Alert> _generateAlerts(SensorData data) {
    final alerts = <Alert>[];

    // Temperature alert
    if (data.temperature > AppConstants.defaultMaxTemp) {
      alerts.add(Alert(
        type: 'temperature',
        title: 'Temperature High',
        description:
            'Now ${data.temperature.toStringAsFixed(1)}°C - cooling fan turned ON.',
        icon: Icons.thermostat,
        backgroundColor: const Color(0xFFFFEAEA),
        iconColor: const Color(0xFFFF6B6B),
        timestamp: DateTime.now(),
      ));
    } else if (data.temperature < AppConstants.defaultMinTemp) {
      alerts.add(Alert(
        type: 'temperature',
        title: 'Temperature Low',
        description:
            'Now ${data.temperature.toStringAsFixed(1)}°C - heating lamp turned ON.',
        icon: Icons.thermostat,
        backgroundColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF2196F3),
        timestamp: DateTime.now(),
      ));
    }

    // Water level alert
    if (data.waterLevel.toLowerCase() == 'low') {
      alerts.add(Alert(
        type: 'water',
        title: 'Water Level is low',
        description: 'Water level at 40%. Please refill soon.',
        icon: Icons.water_drop,
        backgroundColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF2196F3),
        timestamp: DateTime.now(),
      ));
    } else if (data.waterLevel.toLowerCase() == 'empty') {
      alerts.add(Alert(
        type: 'water',
        title: 'Water Level is empty',
        description: 'Water container is empty. Refill immediately!',
        icon: Icons.water_drop,
        backgroundColor: const Color(0xFFFFEAEA),
        iconColor: const Color(0xFFFF6B6B),
        timestamp: DateTime.now(),
      ));
    }

    // Feed level alert
    if (data.feedLevelPercent < 0.30) {
      alerts.add(Alert(
        type: 'feed',
        title: 'Feed Level Low',
        description:
            'Feed at ${(data.feedLevelPercent * 100).toStringAsFixed(0)}%. Refill when possible.',
        icon: Icons.grain,
        backgroundColor: const Color(0xFFFFF3CD),
        iconColor: const Color(0xFFFFA500),
        timestamp: DateTime.now(),
      ));
    }

    // Feeding complete notification (example - you can customize based on your system)
    if (data.lastFeedTime > 0) {
      final lastFeedDuration = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(data.lastFeedTime));
      if (lastFeedDuration.inMinutes < 5) {
        // Show recent feeding completions
        alerts.insert(
          0,
          Alert(
            type: 'feeding',
            title: 'Feeding Complete',
            description: '${(data.feedLevelPercent * 100).toStringAsFixed(0)}% portion dispensed.',
            icon: Icons.check_circle,
            backgroundColor: const Color(0xFFD4EDDA),
            iconColor: const Color(0xFF28A745),
            timestamp: DateTime.fromMillisecondsSinceEpoch(data.lastFeedTime),
          ),
        );
      }
    }

    return alerts;
  }
}

// ── Alert Model ────────────────────────────────────────────────────────────
class Alert {
  final String type;
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final DateTime timestamp;

  Alert({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.timestamp,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}

// ── Alert Card ─────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.iconColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: alert.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alert.icon,
                    color: alert.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Alert icon (top right)
                if (alert.type != 'feeding')
                  Icon(
                    Icons.warning_rounded,
                    color: alert.iconColor.withOpacity(0.4),
                    size: 20,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}