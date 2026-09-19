// ============================================================
// lib/screens/alerts_screen.dart — Alerts Screen (active only)
// ============================================================
// Shows ONLY currently-active problems, derived live from the
// current sensor reading vs thresholds (same style as the
// dashboard's alert banner). No history here — that lives in
// logs_screen.dart. This means:
//   • Exactly one alert per active problem, no repeats
//   • Alert disappears automatically once the value is normal
// ============================================================

import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class ClimateScreen extends StatelessWidget {
  const ClimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: FirebaseService().thresholdsStream(),
      builder: (context, threshSnap) {
        final thresholds = threshSnap.data ?? {};
        final maxTemp = (thresholds['tempMax'] as num?)?.toDouble() ?? AppConstants.defaultMaxTemp;
        final minTemp = (thresholds['tempMin'] as num?)?.toDouble() ?? AppConstants.defaultMinTemp;
        final feedLowPercent = (thresholds['feedLow'] as num?)?.toDouble() ?? 30.0;
        final humMax = (thresholds['humMax'] as num?)?.toDouble() ?? 80.0;
        const humMin = 50.0;

        return StreamBuilder<SensorData>(
          stream: FirebaseService().sensorStream(),
          builder: (context, sensorSnap) {
            final data = sensorSnap.data ?? const SensorData();

            final activeAlerts = _activeAlerts(
              data, maxTemp, minTemp, humMax, humMin, feedLowPercent,
            );

            return Container(
              color: const Color(0xFFF5F5F5),
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────
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
                            'Current farm status',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Offline banner ───────────────────────────
                  if (!data.systemOnline)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cloud_off_rounded,
                                  color: Colors.grey.shade500, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Device offline — alerts paused.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── All-clear state ──────────────────────────
                  if (activeAlerts.isEmpty && data.systemOnline)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('✓', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 16),
                            Text(
                              'All systems normal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No active alerts.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Active alerts list (live, deduped) ───────
                  if (activeAlerts.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _AlertCard(alert: activeAlerts[index]),
                        childCount: activeAlerts.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Derives the CURRENT set of active problems directly from live
  // sensor data. This is what makes alerts disappear automatically
  // once the underlying value returns to normal — no dedup needed.
  List<Alert> _activeAlerts(
    SensorData data,
    double maxTemp,
    double minTemp,
    double humMax,
    double humMin,
    double feedLowPercent,
  ) {
    if (!data.systemOnline) return [];
    final alerts = <Alert>[];

    if (data.temperature > maxTemp) {
      alerts.add(Alert(
        type: 'temperature',
        title: 'Temperature High',
        description:
            'Currently ${data.temperature.toStringAsFixed(1)}°C — cooling fan is ON.',
        icon: Icons.thermostat,
        backgroundColor: const Color(0xFFFFEAEA),
        iconColor: const Color(0xFFFF6B6B),
      ));
    } else if (data.temperature < minTemp) {
      alerts.add(Alert(
        type: 'temperature',
        title: 'Temperature Low',
        description:
            'Currently ${data.temperature.toStringAsFixed(1)}°C — heating lamp is ON.',
        icon: Icons.thermostat,
        backgroundColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF2196F3),
      ));
    }

    if (data.humidity > humMax) {
      alerts.add(Alert(
        type: 'humidity',
        title: 'Humidity High',
        description:
            'Currently ${data.humidity.toStringAsFixed(0)}% — exhaust fan is ON.',
        icon: Icons.water,
        backgroundColor: const Color(0xFFFFF3CD),
        iconColor: const Color(0xFFFFA500),
      ));
    } else if (data.humidity < humMin) {
      alerts.add(Alert(
        type: 'humidity',
        title: 'Humidity Low',
        description: 'Currently ${data.humidity.toStringAsFixed(0)}%.',
        icon: Icons.water,
        backgroundColor: const Color(0xFFFFF3CD),
        iconColor: const Color(0xFFFFA500),
      ));
    }

    final feedPercent = (data.feedLevelPercent * 100);
    if (feedPercent < feedLowPercent) {
      alerts.add(Alert(
        type: 'feed',
        title: 'Feed Level Low',
        description: 'Feed at ${feedPercent.toStringAsFixed(0)}%. Refill when possible.',
        icon: Icons.grain,
        backgroundColor: const Color(0xFFFFF3CD),
        iconColor: const Color(0xFFFFA500),
      ));
    }

    switch (data.waterLevel.toLowerCase()) {
      case 'empty':
        alerts.add(Alert(
          type: 'water',
          title: 'Water Container Empty',
          description: 'Refill required immediately.',
          icon: Icons.water_drop,
          backgroundColor: const Color(0xFFF8D7DA),
          iconColor: const Color(0xFFDC3545),
        ));
        break;
      case 'low':
        alerts.add(Alert(
          type: 'water',
          title: 'Water Level Low',
          description: 'Water is running low. Please refill soon.',
          icon: Icons.water_drop,
          backgroundColor: const Color(0xFFFFF3CD),
          iconColor: const Color(0xFFFFA500),
        ));
        break;
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

  Alert({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: alert.iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(alert.icon, color: alert.iconColor, size: 24),
            ),
            const SizedBox(width: 12),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: alert.iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Active now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: alert.iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.warning_rounded,
              color: alert.iconColor.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}