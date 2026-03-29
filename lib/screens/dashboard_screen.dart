// ============================================================
// lib/screens/dashboard_screen.dart  — REDESIGNED (Dark Theme)
// ============================================================
// Features: greeting with user name, critical alert banner,
// sensor cards (temp, humidity, last fed, water level),
// feed level bar, device states, quick dispense button.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/feed_level_bar.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user?.email ?? 'Farmer';
    return email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData>(
      stream: FirebaseService().sensorStream(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const SensorData();
        final isLoading = snapshot.connectionState == ConnectionState.waiting
            && !snapshot.hasData;

        // Determine if there's a critical alert to show
        final hasCriticalAlert = data.systemOnline && (
          data.temperature > AppConstants.defaultMaxTemp ||
          data.waterLevel == 'EMPTY' ||
          data.feedLevelPercent < 0.10
        );

        String alertMessage = '';
        if (data.waterLevel == 'EMPTY') {
          alertMessage = 'Water Container Empty! Refill Required Immediately.';
        } else if (data.temperature > AppConstants.defaultMaxTemp) {
          alertMessage =
              'Temperature Critical! Reached ${data.temperature.toStringAsFixed(1)}°C';
        } else if (data.feedLevelPercent < 0.10) {
          alertMessage = 'Feed Running Low! Refill needed soon.';
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1B2A), Color(0xFF112233)],
            ),
          ),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : CustomScrollView(
                  slivers: [
                    // ── Custom header ──────────────────────────
                    SliverToBoxAdapter(
                      child: _buildHeader(context),
                    ),

                    // ── Critical alert banner ──────────────────
                    if (hasCriticalAlert)
                      SliverToBoxAdapter(
                        child: _AlertBanner(message: alertMessage),
                      ),

                    // ── Sensor cards 2x2 grid ──────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildListDelegate([
                          _SensorCard(
                            icon: Icons.thermostat_rounded,
                            label: 'Temperature',
                            value: '${data.temperature.toStringAsFixed(0)}°C',
                            statusLabel: _tempStatus(data.temperature),
                            statusColor: _tempColor(data.temperature),
                            iconColor: _tempColor(data.temperature),
                          ),
                          _SensorCard(
                            icon: Icons.water_drop_rounded,
                            label: 'Humidity',
                            value: '${data.humidity.toStringAsFixed(0)}%',
                            statusLabel: _humStatus(data.humidity),
                            statusColor: _humColor(data.humidity),
                            iconColor: AppColors.info,
                          ),
                          _SensorCard(
                            icon: Icons.schedule_rounded,
                            label: 'Last Fed',
                            value: _lastFed(data.lastFeedTime),
                            statusLabel: 'Most recent feed',
                            statusColor: AppColors.feederActive,
                            iconColor: AppColors.feederActive,
                          ),
                          _SensorCard(
                            icon: Icons.water_rounded,
                            label: 'Water Level',
                            value: data.waterLevel,
                            statusLabel: data.waterLevel == 'FULL'
                                ? 'Water OK'
                                : 'Check Tank',
                            statusColor: data.waterLevel == 'FULL'
                                ? AppColors.success
                                : AppColors.error,
                            iconColor: AppColors.waterActive,
                          ),
                        ]),
                      ),
                    ),

                    // ── Feed level bar ─────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: FeedLevelBar(
                          feedLevel: data.feedLevel,
                          feedMax: data.feedMax,
                        ),
                      ),
                    ),

                    // ── Device states ──────────────────────────
                    SliverToBoxAdapter(
                      child: _DeviceStatesRow(data: data),
                    ),

                    // ── Quick dispense ─────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: ElevatedButton.icon(
                          onPressed: data.feederActive
                              ? null
                              : () => _quickDispense(context),
                          icon: const Icon(Icons.grain_rounded),
                          label: Text(data.feederActive
                              ? 'Dispensing...'
                              : 'Quick Dispense Feed'),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Profile avatar + settings
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _userName.isNotEmpty
                      ? _userName[0].toUpperCase()
                      : 'F',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _quickDispense(BuildContext context) async {
    try {
      await FirebaseService().quickDispense(AppConstants.quickDispenseSeconds);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Dispensing feed for ${AppConstants.quickDispenseSeconds}s...'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to trigger dispense.')),
      );
    }
  }

  Color _tempColor(double t) {
    if (t > AppConstants.defaultMaxTemp) return AppColors.error;
    if (t < AppConstants.defaultMinTemp) return AppColors.info;
    return AppColors.warning;
  }

  String _tempStatus(double t) {
    if (t > AppConstants.defaultMaxTemp) return 'Too Hot!';
    if (t < AppConstants.defaultMinTemp) return 'Too Cold';
    return 'Normal';
  }

  String _humStatus(double h) {
    if (h > 80) return 'Too Humid';
    if (h < 40) return 'Too Dry';
    return 'Good';
  }

  Color _humColor(double h) {
    if (h > 80 || h < 40) return AppColors.warning;
    return AppColors.success;
  }

  String _lastFed(int ms) {
    if (ms == 0) return '--:--';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateFormat('h:mm a').format(dt);
  }
}

// ── Critical alert banner ─────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final String message;
  const _AlertBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.alertCritical,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual sensor card ────────────────────────────────────
class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String statusLabel;
  final Color statusColor;
  final Color iconColor;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.statusLabel,
    required this.statusColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Main value
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),

          const SizedBox(height: 6),

          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device states row ─────────────────────────────────────────
class _DeviceStatesRow extends StatelessWidget {
  final SensorData data;
  const _DeviceStatesRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEVICE STATES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DeviceChip(
                  icon: Icons.lightbulb_rounded,
                  label: 'Heating\nLamp',
                  isActive: data.heatingLamp,
                  color: AppColors.heatingActive,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DeviceChip(
                  icon: Icons.air_rounded,
                  label: 'Cooling\nFan',
                  isActive: data.coolingFan,
                  color: AppColors.coolingActive,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DeviceChip(
                  icon: Icons.grain_rounded,
                  label: 'Feeder\nMotor',
                  isActive: data.feederActive,
                  color: AppColors.feederActive,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DeviceChip(
                  icon: Icons.water_rounded,
                  label: 'Water\nValve',
                  isActive: data.waterActive,
                  color: AppColors.waterActive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;

  const _DeviceChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isActive ? color : AppColors.textTertiary,
              size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? color : AppColors.textTertiary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? color : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}