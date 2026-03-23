// ============================================================
// lib/screens/dashboard_screen.dart
// ============================================================
// Tab 0: Dashboard
// Shows a live overview of ALL sensor readings and device states.
// Data is streamed from Firebase Realtime Database so it updates
// automatically when the Arduino sends new readings.
//
// Layout:
//   • System status banner (Online/Offline)
//   • 2×2 sensor card grid (Temp, Humidity, Feed Level, Water)
//   • Feed level bar with % indicator
//   • Device status row (Heating Lamp, Cooling Fan, Feeder, Water)
//   • Quick action button (Dispense Feed Now)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/sensor_card.dart';
import '../widgets/feed_level_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData>(
      // Listen to live sensor updates from Firebase.
      stream: FirebaseService().sensorStream(),
      builder: (context, snapshot) {
        // While connecting, show a loading spinner.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        } 

        // Use data or fall back to empty/default SensorData.
        final data = snapshot.data ?? const SensorData();

        return RefreshIndicator(
          // Pull-to-refresh re-subscribes (StreamBuilder handles this auto).
          onRefresh: () async => await Future.delayed(Duration.zero),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // ── System status banner ──────────────────────────────────
              _SystemStatusBanner(isOnline: data.systemOnline),

              const SizedBox(height: 16),

              // ── Section header ────────────────────────────────────────
              const _SectionLabel('LIVE READINGS'),

              // ── 2×2 sensor card grid ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true, // let ListView determine scroll height
                  physics: const NeverScrollableScrollPhysics(), // no nested scroll
                  childAspectRatio: 1.0,
                  children: [
                    // Temperature card
                    SensorCard(
                      icon: Icons.thermostat,
                      iconColor: _tempColor(data.temperature),
                      label: 'Temperature',
                      value: data.temperature.toStringAsFixed(1),
                      unit: '°C',
                      subtitle: _tempStatus(data.temperature),
                      statusColor: _tempColor(data.temperature),
                    ),
                    // Humidity card
                    SensorCard(
                      icon: Icons.water_drop_outlined,
                      iconColor: AppColors.info,
                      label: 'Humidity',
                      value: data.humidity.toStringAsFixed(0),
                      unit: '%',
                      subtitle: _humidityStatus(data.humidity),
                      statusColor: _humidityStatusColor(data.humidity),
                    ),
                    // Water level card
                    SensorCard(
                      icon: Icons.water,
                      iconColor: AppColors.waterActive,
                      label: 'Water Level',
                      value: data.waterLevel,
                      unit: '',
                      subtitle: data.waterLevel == 'FULL'
                          ? 'Water OK'
                          : data.waterLevel == 'LOW'
                              ? 'Refill Soon'
                              : 'Check Tank',
                      statusColor: data.waterLevel == 'FULL'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    // Last feed time card
                    SensorCard(
                      icon: Icons.schedule,
                      iconColor: AppColors.feederActive,
                      label: 'Last Fed',
                      value: _lastFedTime(data.lastFeedTime),
                      unit: '',
                      subtitle: 'Most recent feed',
                      statusColor: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Feed level bar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FeedLevelBar(
                  feedLevel: data.feedLevel,
                  feedMax: data.feedMax,
                ),
              ),

              const SizedBox(height: 20),

              // ── Section header ────────────────────────────────────────
              const _SectionLabel('DEVICE STATES'),

              // ── Device state cards ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _DeviceStateChip(
                        icon: Icons.lightbulb_outlined,
                        label: 'Heating\nLamp',
                        isActive: data.heatingLamp,
                        activeColor: AppColors.heatingActive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DeviceStateChip(
                        icon: Icons.air,
                        label: 'Cooling\nFan',
                        isActive: data.coolingFan,
                        activeColor: AppColors.coolingActive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DeviceStateChip(
                        icon: Icons.grain,
                        label: 'Feeder\nMotor',
                        isActive: data.feederActive,
                        activeColor: AppColors.feederActive,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DeviceStateChip(
                        icon: Icons.water,
                        label: 'Water\nValve',
                        isActive: data.waterActive,
                        activeColor: AppColors.waterActive,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick Dispense button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: data.feederActive
                      ? null // Disabled while already dispensing
                      : () => _quickDispense(context),
                  icon: const Icon(Icons.grain),
                  label: data.feederActive
                      ? const Text('Dispensing...')
                      : const Text('Quick Dispense Feed'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ── Trigger a quick dispense and show feedback ────────────────────────────
  void _quickDispense(BuildContext context) async {
    try {
      await FirebaseService()
          .quickDispense(AppConstants.quickDispenseSeconds);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Dispensing feed for ${AppConstants.quickDispenseSeconds}s...'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to trigger dispense.')),
      );
    }
  }

  // ── Temperature helpers ───────────────────────────────────────────────────
  Color _tempColor(double temp) {
    if (temp > AppConstants.defaultMaxTemp) return AppColors.error;
    if (temp < AppConstants.defaultMinTemp) return AppColors.info;
    return AppColors.success;
  }

  String _tempStatus(double temp) {
    if (temp > AppConstants.defaultMaxTemp) return 'Too Hot!';
    if (temp < AppConstants.defaultMinTemp) return 'Too Cold';
    return 'Normal';
  }

  // ── Humidity helpers ──────────────────────────────────────────────────────
  String _humidityStatus(double h) {
    if (h > 80) return 'Too Humid';
    if (h < 40) return 'Too Dry';
    return 'Normal';
  }

  Color _humidityStatusColor(double h) {
    if (h > 80 || h < 40) return AppColors.warning;
    return AppColors.success;
  }

  // ── Format last feed timestamp ────────────────────────────────────────────
  String _lastFedTime(int ms) {
    if (ms == 0) return '--:--';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('h:mm a').format(dt);
  }
}

// ── System status banner widget ───────────────────────────────────────────────
class _SystemStatusBanner extends StatelessWidget {
  final bool isOnline;
  const _SystemStatusBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Pulsing dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOnline
                  ? 'System Online — Arduino connected'
                  : 'System Offline — Check your device',
              style: TextStyle(
                color: isOnline ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? AppColors.success : AppColors.error,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ── Small device state chip ───────────────────────────────────────────────────
class _DeviceStateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;

  const _DeviceStateChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.1) : AppColors.backgroundWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isActive ? activeColor : AppColors.textTertiary,
              size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? activeColor : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? activeColor : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label widget ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}