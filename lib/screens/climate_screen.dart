// ============================================================
// lib/screens/climate_screen.dart
// ============================================================
// Tab 2: Climate
// Shows detailed temperature & humidity data and allows the
// farmer to manually override the heating lamp and cooling fan.
//
// When "Auto Climate" is enabled, the Arduino handles heating/
// cooling automatically based on the thresholds in /settings/.
// Manual toggles here directly write to Firebase, and the
// Arduino reads them within ~1 second.
// ============================================================

import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
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

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // ── Page title ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Climate Control',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Real-time environment monitoring',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),

            // ── Big temperature display ───────────────────────────────
            _BigTemperatureCard(
              temperature: data.temperature,
              humidity: data.humidity,
            ),

            const SizedBox(height: 16),

            // ── Threshold info card ───────────────────────────────────
            _ThresholdCard(
              currentTemp: data.temperature,
              minTemp: AppConstants.defaultMinTemp,
              maxTemp: AppConstants.defaultMaxTemp,
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'DEVICE CONTROLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // ── Heating lamp toggle card ──────────────────────────────
            _DeviceControlCard(
              icon: Icons.lightbulb_outlined,
              activeIcon: Icons.lightbulb,
              title: 'Heating Lamp',
              subtitle: data.heatingLamp
                  ? 'Active — keeping temperature up'
                  : 'Off — temperature is in range',
              isActive: data.heatingLamp,
              activeColor: AppColors.heatingActive,
              onToggle: (value) => FirebaseService().setHeatingLamp(value),
            ),

            const SizedBox(height: 10),

            // ── Cooling fan toggle card ───────────────────────────────
            _DeviceControlCard(
              icon: Icons.air,
              activeIcon: Icons.air,
              title: 'Cooling Fan',
              subtitle: data.coolingFan
                  ? 'Active — ventilating the house'
                  : 'Off — temperature is in range',
              isActive: data.coolingFan,
              activeColor: AppColors.coolingActive,
              onToggle: (value) => FirebaseService().setCoolingFan(value),
            ),

            const SizedBox(height: 10),

            // ── Water dispenser toggle card ───────────────────────────
            _DeviceControlCard(
              icon: Icons.water_drop_outlined,
              activeIcon: Icons.water_drop,
              title: 'Water Dispenser',
              subtitle: data.waterActive
                  ? 'Open — water is flowing'
                  : 'Closed — valve is shut',
              isActive: data.waterActive,
              activeColor: AppColors.waterActive,
              onToggle: (value) => FirebaseService().setWaterDispenser(value),
            ),

            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

// ── Big temperature display card ──────────────────────────────────────────────
class _BigTemperatureCard extends StatelessWidget {
  final double temperature;
  final double humidity;

  const _BigTemperatureCard({
    required this.temperature,
    required this.humidity,
  });

  // Color of the temperature value based on safety range.
  Color get _tempColor {
    if (temperature > AppConstants.defaultMaxTemp) return AppColors.error;
    if (temperature < AppConstants.defaultMinTemp) return AppColors.info;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _tempColor.withOpacity(0.08),
            _tempColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tempColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Temperature display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat, color: _tempColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Temperature',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: temperature.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: _tempColor,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: '°C',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: _tempColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Status label
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tempColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    temperature > AppConstants.defaultMaxTemp
                        ? 'TOO HOT'
                        : temperature < AppConstants.defaultMinTemp
                            ? 'TOO COLD'
                            : 'NORMAL RANGE',
                    style: TextStyle(
                      color: _tempColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(width: 1, height: 80, color: AppColors.border),
          const SizedBox(width: 24),

          // Humidity display
          Column(
            children: [
              const Icon(Icons.water_drop_outlined,
                  color: AppColors.info, size: 24),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: humidity.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                    const TextSpan(
                      text: '%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Humidity',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Min/Max threshold info card ───────────────────────────────────────────────
class _ThresholdCard extends StatelessWidget {
  final double currentTemp;
  final double minTemp;
  final double maxTemp;

  const _ThresholdCard({
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  Widget build(BuildContext context) {
    // Fraction of how far along the current temp is in the safe range.
    final safeRange = maxTemp - minTemp;
    final posInRange = ((currentTemp - minTemp) / safeRange).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safe Temperature Range',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Target: ${minTemp.toStringAsFixed(0)}°C – ${maxTemp.toStringAsFixed(0)}°C',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),

          // Custom range bar with current position marker
          Stack(
            children: [
              // Background bar (full range, grey)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info,    // cold (blue)
                        AppColors.success, // safe (green)
                        AppColors.error,   // hot (red)
                      ],
                    ),
                  ),
                ),
              ),

              // Position marker
              Positioned(
                left: MediaQuery.of(context).size.width *
                        posInRange *
                        0.75 - // scale for padding
                    6,
                top: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.textPrimary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Labels under the bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${minTemp.toStringAsFixed(0)}°C',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.info)),
              Text('Optimal Zone',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.success)),
              Text('${maxTemp.toStringAsFixed(0)}°C',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Device control toggle card ────────────────────────────────────────────────
class _DeviceControlCard extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String subtitle;
  final bool isActive;
  final Color activeColor;
  final ValueChanged<bool> onToggle;

  const _DeviceControlCard({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.activeColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withOpacity(0.06)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive ? activeColor.withOpacity(0.25) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isActive ? activeColor.withOpacity(0.15) : AppColors.backgroundWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : AppColors.textTertiary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),

          // Toggle switch
          Switch(
            value: isActive,
            onChanged: onToggle,
            activeThumbColor: activeColor,
          ),
        ],
      ),
    );
  }
}