// ============================================================
// lib/screens/dashboard_screen.dart  — REDESIGNED (Reference UI)
// ============================================================
// Features: greeting with user name, critical alert banner,
// 2x2 sensor cards grid (feed, water, temp, humidity),
// environmental control status, device states.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../models/actuator_state.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/feed_level_bar.dart';
import 'settings_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/cache_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  bool _hasInternet = true;
  final Connectivity _connectivity = Connectivity();

  SensorData _cachedData = const SensorData();
  bool _cacheLoaded = false;

  String get _greeting {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 18) return 'Good Afternoon';
  return 'Good Evening';
}

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user?.email ?? 'Farmer';
    return email.split('@').first;
  }
@override
void initState() {
  super.initState();

  _loadCache();
  _checkInternet();

  _connectivity.onConnectivityChanged.listen((results) {
    if (!mounted) return;

    setState(() {
      _hasInternet = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);
    });
  });
}

Future<void> _checkInternet() async {
  final result = await _connectivity.checkConnectivity();

  if (!mounted) return;

  setState(() {
    _hasInternet =
        result.isNotEmpty && !result.contains(ConnectivityResult.none);
  });
}

Future<void> _loadCache() async {
  final data = await CacheService.load();

  if (!mounted) return;

  if (data != null) {
    setState(() {
      _cachedData = data;
      _cacheLoaded = true;
    });
  }
}

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
      final humMin = 50.0;

      return StreamBuilder<SensorData>(
        stream: FirebaseService().sensorStream(),
        builder: (context, snapshot) {
          final data = snapshot.hasData
              ? snapshot.data!
              : _cachedData;
          if (snapshot.hasData) {
              CacheService.save(data);

              _cachedData = data;
            }
          final isLoading = snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData &&
                  !_cacheLoaded;

          // Now uses Firebase thresholds, not hardcoded constants
          final hasCriticalAlert = data.systemOnline && (
            data.temperature > maxTemp ||
            data.waterLevel == 'EMPTY' ||
            data.feedLevelPercent < (feedLowPercent / 100)
          );

          String alertMessage = '';
          if (data.waterLevel == 'EMPTY') {
            alertMessage = 'Water Container Empty! Refill Required Immediately.';
          } else if (data.temperature > maxTemp) {
            alertMessage =
                'Temperature Critical! Reached ${data.temperature.toStringAsFixed(1)}°C';
          } else if (data.feedLevelPercent < (feedLowPercent / 100)) {
            alertMessage = 'Feed Running Low! Refill needed soon.';
          }

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color.fromARGB(255, 215, 196, 47)))
                : CustomScrollView(
                    slivers: [
                      if (!_hasInternet)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Card(
                              color: Color(0xFFFFF3CD),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.wifi_off, color: Colors.orange),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Offline - Showing last synchronized data',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ── Custom header ──────────────────────────
                      SliverToBoxAdapter(
                        child: _buildHeader(context, data),
                      ),

                      // ── Critical alert banner ──────────────────
                      if (hasCriticalAlert)
                        SliverToBoxAdapter(
                          child: _AlertBanner(message: alertMessage),
                        ),

                      // ── 2x2 Sensor cards grid ──────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Row 1: Temperature & Humidity
                              Row(
                                children: [
                                  Expanded(
                                    child: _TempHumCard(
                                      title: 'Temperature',
                                      value: '${data.temperature.toStringAsFixed(0)}°C',
                                      icon: Icons.thermostat,
                                      iconColor: Colors.orange,
                                      status: _tempStatus(data.temperature, maxTemp, minTemp),
                                      statusColor: _tempColor(data.temperature, maxTemp, minTemp),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TempHumCard(
                                      title: 'Humidity',
                                      value: '${data.humidity.toStringAsFixed(0)}%',
                                      icon: Icons.cloud,
                                      iconColor: Colors.blue,
                                      status: _humStatus(data.humidity, humMax, humMin),
                                      statusColor: _humColor(data.humidity, humMax, humMin),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Row 2: Feed Level & Water Level
                              // Row 2: Feed Level & Water Level
                              StreamBuilder<ActuatorState>(
                                stream: FirebaseService().actuatorsStream(),
                                builder: (context, actuatorSnap) {
                                  final actuatorData = actuatorSnap.data ?? const ActuatorState();
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _FeedLevelCard(
                                          data: data,
                                          feedLowPercent: feedLowPercent,
                                          isDispensing: actuatorData.feedServo,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _WaterLevelCard(
                                          data: data,
                                          isDispensing: actuatorData.waterServo,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Environmental Control Status ────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 14, 12),
                          child: StreamBuilder<ActuatorState>(
                            stream: FirebaseService().actuatorsStream(),
                            builder: (context, actuatorSnapshot) {
                              final actuatorData =
                                  actuatorSnapshot.data ?? const ActuatorState();
                              return _EnvironmentalControlStatus(data: actuatorData);
                            },
                          ),
                        ),
                      ),

                      // ── Spacing ────────────────────────────────
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
          );
        },
      );
    },
  );
}

  Widget _buildHeader(BuildContext context, SensorData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFD4C84E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$_greeting,\n${_userName}!',
            style: const TextStyle(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                          !_hasInternet
                              ? Icons.wifi_off_rounded
                              : Icons.wifi_rounded,
                          size: 16,
                          color: !_hasInternet
                              ? Colors.red
                              : data.systemOnline
                                  ? Colors.green
                                  : Colors.orange,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          !_hasInternet
                              ? 'Offline'
                              : data.systemOnline
                                  ? 'Online'
                                  : 'System Device Offline',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Color _tempColor(double t, double maxTemp, double minTemp) {
  if (t > maxTemp) return const Color(0xFFFF6B6B);
  if (t < minTemp) return AppColors.info;
  return AppColors.success;
}

String _tempStatus(double t, double maxTemp, double minTemp) {
  if (t > maxTemp) return 'Too Hot';
  if (t < minTemp) return 'Too Cold';
  return 'Normal';
}

String _humStatus(double h, double humMax, double humMin) {
  if (h > humMax) return 'High';
  if (h < humMin) return 'Low';
  return 'Good';
}

Color _humColor(double h, double humMax, double humMin) {
  if (h > humMax) return const Color(0xFFFF6B6B);
  if (h < humMin) return const Color(0xFFFFA500);
  return AppColors.success;
}
}

// ── Critical alert banner ─────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final String message;
  const _AlertBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        border: Border.all(
          color: const Color(0xFFFF6B6B),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF6B6B),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed Level Card ────────────────────────────────────────────
class _FeedLevelCard extends StatefulWidget {
  final SensorData data;
  final double feedLowPercent;
  final bool isDispensing;

  const _FeedLevelCard({
    required this.data,
    required this.feedLowPercent,
    required this.isDispensing,
  });

  @override
  State<_FeedLevelCard> createState() => _FeedLevelCardState();
}

class _FeedLevelCardState extends State<_FeedLevelCard> {
  bool _localPending = false;

Future<void> _handleDispense() async {
  final controller = TextEditingController(
    text: widget.feedLowPercent.toStringAsFixed(0),
  );

  final percent = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Dispense Feed'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(suffixText: '%', labelText: 'Amount to dispense'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final val = double.tryParse(controller.text.trim());
            if (val != null) Navigator.pop(context, val.clamp(0, 100).toDouble());
          },
          child: const Text('Dispense'),
        ),
      ],
    ),
  );

  if (percent == null) return; // user cancelled

  setState(() => _localPending = true);
  try {
    await FirebaseService().saveThreshold('manualDispensePercent', percent);
    await FirebaseService().triggerManualFeedFromSettings();
  } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to trigger feed dispense.')),
        );
      }
    }
    // Leave _localPending true until the Pi's feedServo flag catches up,
    // so the button doesn't flicker enabled between tap and Pi ack.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _localPending = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final feedLowPercent = widget.feedLowPercent;
    final busy = widget.isDispensing || _localPending;

    final percentValue = (data.feedLevelPercent * 100).round();
    String feedStatus;
    Color statusBgColor;
    Color statusTextColor;

    if (percentValue < feedLowPercent) {
      feedStatus = 'Low';
      statusBgColor = const Color(0xFFFFF3CD);
      statusTextColor = const Color(0xFF856404);
    } else if (percentValue >= feedLowPercent && percentValue <= 70) {
      feedStatus = 'Normal';
      statusBgColor = const Color(0xFFD4EDDA);
      statusTextColor = const Color(0xFF28A745);
    } else {
      feedStatus = 'Full';
      statusBgColor = const Color(0xFFD1ECFF);
      statusTextColor = const Color(0xFF004085);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grain, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Feed Level',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Text('$percentValue%',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
            child: Text(feedStatus,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusTextColor)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : _handleDispense,
              child: Text(busy ? 'Dispensing…' : 'Dispense Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4C84E),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Water Level Card ───────────────────────────────────────────
class _WaterLevelCard extends StatefulWidget {
  final SensorData data;
  final bool isDispensing;

  const _WaterLevelCard({required this.data, required this.isDispensing});

  @override
  State<_WaterLevelCard> createState() => _WaterLevelCardState();
}

class _WaterLevelCardState extends State<_WaterLevelCard> {
  bool _localPending = false;

  Future<void> _handleDispense() async {
    setState(() => _localPending = true);
    try {
      await FirebaseService().triggerManualWater();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispensing water until level reaches Normal…')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to trigger water dispense.')),
        );
      }
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _localPending = false);
    });
  }

  @override
  void didUpdateWidget(covariant _WaterLevelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fires only on the real Pi-confirmed transition: was dispensing,
    // now stopped, because the sensor reported water level back to Normal.
    if (oldWidget.isDispensing && !widget.isDispensing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Water level normal — dispensing stopped.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final busy = widget.isDispensing || _localPending;

    String waterStatus;
    Color statusBgColor;
    Color statusTextColor;

    switch (data.waterLevel.toLowerCase()) {
      case 'normal':
        waterStatus = 'Normal';
        statusBgColor = const Color(0xFFD4EDDA);
        statusTextColor = const Color(0xFF28A745);
        break;
      case 'low':
        waterStatus = 'Low';
        statusBgColor = const Color(0xFFFFF3CD);
        statusTextColor = const Color(0xFF856404);
        break;
      case 'empty':
        waterStatus = 'Empty';
        statusBgColor = const Color(0xFFF8D7DA);
        statusTextColor = const Color(0xFFDC3545);
        break;
      default:
        waterStatus = 'Unknown';
        statusBgColor = const Color(0xFFE2E3E5);
        statusTextColor = const Color(0xFF6C757D);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('Water Level',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Text(waterStatus,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
            child: Text(waterStatus,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusTextColor)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : _handleDispense,
              child: Text(busy ? 'Dispensing…' : 'Dispense Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4C84E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Temperature/Humidity Card ──────────────────────────────────
class _TempHumCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String status;
  final Color statusColor;

  const _TempHumCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
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

// ── Environmental Control Status ────────────────────────────────
class _EnvironmentalControlStatus extends StatelessWidget {
  final ActuatorState data;

  const _EnvironmentalControlStatus({required this.data});

  @override
  Widget build(BuildContext context) {
    final exhaustFanActive = data.exhaustFan;
    final heatingLampActive = data.heatingLamp;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Environmental Control Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DeviceStateBox(
                    title: 'Exhaust Fan',
                    isActive: exhaustFanActive,
                    activeColor: Colors.blue,
                    icon: Icons.air,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: _DeviceStateBox(
                  title: 'Heating Lamp',
                  isActive: heatingLampActive,
                  activeColor: Colors.orange,
                  icon: Icons.lightbulb,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Device State Box ───────────────────────────────────────────
class _DeviceStateBox extends StatelessWidget {
  final String title;
  final bool isActive;
  final Color activeColor;
  final IconData icon;

  const _DeviceStateBox({
    required this.title,
    required this.isActive,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.1) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? activeColor : Colors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? activeColor : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? activeColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}