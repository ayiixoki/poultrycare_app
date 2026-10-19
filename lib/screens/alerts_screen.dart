// ============================================================
// lib/screens/alerts_screen.dart — Alerts Screen (active only)
// ============================================================
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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
        final maxTemp = (thresholds['tempMax'] as num?)?.toDouble() ??
            AppConstants.defaultMaxTemp;
        final minTemp = (thresholds['tempMin'] as num?)?.toDouble() ??
            AppConstants.defaultMinTemp;
        final humMax = (thresholds['humMax'] as num?)?.toDouble() ?? 80.0;
        const humMin = 50.0;

        return StreamBuilder<SensorData>(
          stream: FirebaseService().sensorStream(),
          builder: (context, sensorSnap) {
            final data = sensorSnap.data ?? const SensorData();

            return StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('sensor_data').onValue,
              builder: (context, healthSnap) {
                final raw = healthSnap.data?.snapshot.value;
                final root = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};
                final healthRaw = root['sensor_health'];
                final health = healthRaw is Map
                    ? Map<String, dynamic>.from(healthRaw)
                    : <String, dynamic>{};

                final activeAlerts = _activeAlerts(
                    data, maxTemp, minTemp, humMax, humMin, health, root);

                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: CustomScrollView(
                    slivers: [
                      // ── Header ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alerts',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              const SizedBox(height: 4),
                              Text(
                                activeAlerts.isEmpty
                                    ? 'Current farm status'
                                    : '${activeAlerts.length} thing${activeAlerts.length > 1 ? 's' : ''} need${activeAlerts.length > 1 ? '' : 's'} your attention',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Offline banner ──
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
                                  Expanded(
                                    child: Text(
                                      'The farm device is offline, so alerts are paused.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── All clear ──
                      if (activeAlerts.isEmpty && data.systemOnline)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('✓', style: TextStyle(fontSize: 48)),
                                  SizedBox(height: 16),
                                  Text('All good',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 8),
                                  Text('Nothing needs your attention right now.',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── Active alerts ──
                      if (activeAlerts.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _AlertCard(alert: activeAlerts[index]),
                            childCount: activeAlerts.length,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Alert> _activeAlerts(
    SensorData data,
    double maxTemp,
    double minTemp,
    double humMax,
    double humMin,
    Map<String, dynamic> health,
    Map<String, dynamic> root,
  ) {
    if (!data.systemOnline) return [];
    final alerts = <Alert>[];

    bool stuck(String key) {
      final reasons = root['sensor_fault_reason'];
      return reasons is Map && reasons[key] == 'stuck';
    }

    // ── Feed container ──
    if (health['feed_bin'] == false) {
      alerts.add(Alert(
        title: 'Feed Container Sensor Problem',
        description: stuck('feed_bin')
            ? 'The sensor that checks the feed container keeps showing the same number. It may be broken.'
            : 'The sensor that checks the feed container is not working, so we cannot tell how much feed is left.',
        action: 'Check the sensor wire. If this stays, ask your technician.',
        icon: Icons.sensors_off,
        color: const Color(0xFF6C757D),
      ));
    } else if (root['feed_bin_state'] == 'empty') {
      alerts.add(Alert(
        title: 'Feed Container Empty',
        description: 'There is no feed left in the feed container.',
        action: 'Refill the feed container now.',
        icon: Icons.inventory_2,
        color: const Color(0xFFD32F2F),
      ));
    } else if (root['feed_bin_low_active'] == true) {
      final pct = (root['feed_bin_percent'] as num?)?.toDouble();
      alerts.add(Alert(
        title: 'Feed Container Low',
        description: pct != null
            ? 'Only about ${pct.toStringAsFixed(0)}% of feed is left in the feed container.'
            : 'The feed container is almost empty.',
        action: 'Refill the feed container soon.',
        icon: Icons.inventory_2,
        color: const Color(0xFFE67E00),
      ));
    }

    // ── Parts that stopped working ──
    if (health['dht22'] == false) {
      alerts.add(Alert(
        title: 'Temperature Sensor Problem',
        description: stuck('dht22')
            ? 'The temperature and humidity sensor keeps showing the same numbers. It may be broken.'
            : 'The temperature and humidity sensor is not working. The numbers you see may be wrong.',
        action: 'Check the sensor wire. If this stays, ask your technician.',
        icon: Icons.sensors_off,
        color: const Color(0xFF6C757D),
      ));
    }
    if (health['load_cell'] == false) {
      alerts.add(Alert(
        title: 'Feed Scale Problem',
        description: stuck('load_cell')
            ? 'The scale under the feeding plate keeps showing the same weight. It may be broken.'
            : 'The scale under the feeding plate is not working, so the feed amount may be wrong.',
        action: 'Check the scale wire. If this stays, ask your technician.',
        icon: Icons.scale,
        color: const Color(0xFF8E24AA),
      ));
    }
    if (health['water_refill'] == false) {
      alerts.add(Alert(
        title: 'Drinker Is Not Filling',
        description:
            'The system tried to fill the drinker but the water is still low.',
        action:
            'Check the water tank, the valve and the float. Look for a leak too.',
        icon: Icons.water_drop,
        color: const Color(0xFF1565C0),
      ));
    }

    // ── Temperature ──
    if (data.temperature > maxTemp) {
      alerts.add(Alert(
        title: 'Too Hot',
        description:
            'It is ${data.temperature.toStringAsFixed(1)}°C inside the coop. The fan is ON to cool it down.',
        action: 'Make sure the fan is working and air can flow freely.',
        icon: Icons.thermostat,
        color: const Color(0xFFE53935),
      ));
    } else if (data.temperature < minTemp) {
      alerts.add(Alert(
        title: 'Too Cold',
        description:
            'It is ${data.temperature.toStringAsFixed(1)}°C inside the coop. The heating lamp is ON to warm it up.',
        action: 'Check that the lamp bulb is working.',
        icon: Icons.ac_unit,
        color: const Color(0xFF1E88E5),
      ));
    }

    // ── Humidity ──
    if (data.humidity > humMax) {
      alerts.add(Alert(
        title: 'Air Is Too Damp',
        description:
            'Humidity is ${data.humidity.toStringAsFixed(0)}%. The fan is ON to dry the air.',
        action: 'Keep the bedding dry and check for water leaks.',
        icon: Icons.water,
        color: const Color(0xFF00897B),
      ));
    } else if (data.humidity < humMin) {
      alerts.add(Alert(
        title: 'Air Is Too Dry',
        description: 'Humidity is only ${data.humidity.toStringAsFixed(0)}%.',
        action: 'Make sure the chickens have enough water to drink.',
        icon: Icons.water,
        color: const Color(0xFFF9A825),
      ));
    }

    // ── Feed on the plate ──
    if (data.feedLowActive) {
      final feedPercent = data.feedLevelPercent * 100;
      alerts.add(Alert(
        title: 'Feed Plate Is Low',
        description:
            'Only about ${feedPercent.toStringAsFixed(0)}% of feed is left on the feeding plate.',
        action: 'Tap "Dispense Now" on the Home screen to add more feed.',
        icon: Icons.grain,
        color: const Color(0xFFEF6C00),
      ));
    }

    // ── Water container ──
    if (data.containerLevel.toLowerCase() == 'empty') {
      alerts.add(Alert(
        title: 'Water Tank Is Low',
        description:
            'The tank that fills the drinker is almost empty. The drinker cannot fill itself without water.',
        action: 'Refill the water tank now.',
        icon: Icons.water_drop,
        color: const Color(0xFF0277BD),
      ));
    }

    return alerts;
  }
}

// ── Alert Model ────────────────────────────────────────────────
class Alert {
  final String title;
  final String description;
  final String action;
  final IconData icon;
  final Color color; // icon color, so each alert stands out

  Alert({
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
    required this.color,
  });
}

// ── Alert Card (all light red, icon color differs) ─────────────
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
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(alert.icon, color: alert.color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(alert.description,
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.black.withOpacity(0.75))),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: alert.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(alert.action,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}