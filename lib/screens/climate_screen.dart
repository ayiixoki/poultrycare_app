// ============================================================
// lib/screens/climate_screen.dart
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

        return Container(
          color: const Color(0xFFF5F0E8),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // ── Page title ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Climate Control',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time environment monitoring',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Big temperature card ───────────────────────────
              _BigTemperatureCard(
                temperature: data.temperature,
                humidity: data.humidity,
              ),

              const SizedBox(height: 12),

              // ── Threshold card ─────────────────────────────────
              _ThresholdCard(
                currentTemp: data.temperature,
                minTemp: AppConstants.defaultMinTemp,
                maxTemp: AppConstants.defaultMaxTemp,
              ),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
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

              // ── Heating lamp ───────────────────────────────────
              _DeviceControlCard(
                icon: Icons.lightbulb_outlined,
                activeIcon: Icons.lightbulb,
                title: 'Heating Lamp',
                subtitle: data.heatingLamp
                    ? 'Active — keeping temperature up'
                    : 'Off — temperature is in range',
                isActive: data.heatingLamp,
                activeColor: AppColors.heatingActive,
                onToggle: (v) => FirebaseService().setHeatingLamp(v),
              ),

              const SizedBox(height: 10),

              // ── Cooling fan ────────────────────────────────────
              _DeviceControlCard(
                icon: Icons.air,
                activeIcon: Icons.air,
                title: 'Cooling Fan',
                subtitle: data.coolingFan
                    ? 'Active — ventilating the house'
                    : 'Off — temperature is in range',
                isActive: data.coolingFan,
                activeColor: AppColors.coolingActive,
                onToggle: (v) => FirebaseService().setCoolingFan(v),
              ),

              const SizedBox(height: 10),

              // ── Water dispenser ────────────────────────────────
              _DeviceControlCard(
                icon: Icons.water_drop_outlined,
                activeIcon: Icons.water_drop,
                title: 'Water Dispenser',
                subtitle: data.waterActive
                    ? 'Open — water is flowing'
                    : 'Closed — valve is shut',
                isActive: data.waterActive,
                activeColor: AppColors.waterActive,
                onToggle: (v) => FirebaseService().setWaterDispenser(v),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Big temperature card ───────────────────────────────────────────────────────
class _BigTemperatureCard extends StatelessWidget {
  final double temperature;
  final double humidity;

  const _BigTemperatureCard({
    required this.temperature,
    required this.humidity,
  });

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Temperature
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat, color: _tempColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Temperature',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: temperature.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1,
                        ),
                      ),
                      const TextSpan(
                        text: '°C',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tempColor.withOpacity(0.12),
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
          Container(
            width: 1,
            height: 90,
            color: Colors.black.withOpacity(0.08),
          ),
          const SizedBox(width: 24),

          // Humidity
          Column(
            children: [
              Icon(Icons.water_drop_outlined,
                  color: Colors.black.withOpacity(0.6), size: 24),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: humidity.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const TextSpan(
                      text: '%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Humidity',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Threshold card ─────────────────────────────────────────────────────────────
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
    final safeRange = maxTemp - minTemp;
    final posInRange =
        ((currentTemp - minTemp) / safeRange).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Safe Temperature Range',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${minTemp.toStringAsFixed(0)}°C – ${maxTemp.toStringAsFixed(0)}°C',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 14),

          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info,
                        AppColors.success,
                        AppColors.error,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (MediaQuery.of(context).size.width - 64) *
                        posInRange -
                    9,
                top: -3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${minTemp.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600)),
              const Text('Optimal Zone',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600)),
              Text('${maxTemp.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Device control card ────────────────────────────────────────────────────────
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
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // Toggle
          Switch(
            value: isActive,
            onChanged: onToggle,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}