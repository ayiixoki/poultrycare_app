// ============================================================
// lib/screens/dashboard_screen.dart
// ============================================================
// Greeting header, critical alert banner, sensor cards
// (temperature, humidity, feed, water + container), and the
// environmental control status.
//
// Water: the trough is refilled automatically by the Pi, so the
// water card has no button. It shows the trough level, a
// "Refilling" state while the Pi's water servo is open, and the
// water CONTAINER status (ok / empty).
// ============================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/actuator_state.dart';
import '../models/sensor_data.dart';
import '../services/cache_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

const Color kStatusGreen = Color(0xFF28A745);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasInternet = true;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connSub;

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

    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() {
        _hasInternet =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
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
        final maxTemp = (thresholds['tempMax'] as num?)?.toDouble() ??
            AppConstants.defaultMaxTemp;
        final minTemp = (thresholds['tempMin'] as num?)?.toDouble() ??
            AppConstants.defaultMinTemp;
        final humMax = (thresholds['humMax'] as num?)?.toDouble() ?? 80.0;
        const humMin = 50.0;

        return StreamBuilder<SensorData>(
          stream: FirebaseService().sensorStream(),
          builder: (context, snapshot) {
            final data = snapshot.hasData ? snapshot.data! : _cachedData;
            if (snapshot.hasData) {
              CacheService.save(data);
              _cachedData = data;
            }
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData &&
                    !_cacheLoaded;

            final containerEmpty = data.containerLevel.toLowerCase() == 'empty';

            final hasCriticalAlert = data.systemOnline &&
                (data.temperature > maxTemp ||
                    containerEmpty ||
                    data.feedLowActive);

            String alertMessage = '';
            if (containerEmpty) {
              alertMessage =
                  'Water Container Empty! Refill Required Immediately.';
            } else if (data.temperature > maxTemp) {
              alertMessage =
                  'Temperature Critical! Reached ${data.temperature.toStringAsFixed(1)}°C';
            } else if (data.feedLowActive) {
              alertMessage = 'Feed Running Low! Refill needed soon.';
            }

            return Container(
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 215, 196, 47)))
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
                                      Icon(Icons.wifi_off,
                                          color: Colors.orange),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Offline - Showing last synchronized data',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // ── Header ─────────────────────────────
                        SliverToBoxAdapter(
                          child: _buildHeader(context, data),
                        ),

                        // ── Critical alert banner ──────────────
                        if (hasCriticalAlert)
                          SliverToBoxAdapter(
                            child: _AlertBanner(message: alertMessage),
                          ),

                        // ── Sensor cards ───────────────────────
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
                                        value:
                                            '${data.temperature.toStringAsFixed(0)}°C',
                                        icon: Icons.thermostat,
                                        iconColor: Colors.orange,
                                        status: _tempStatus(
                                            data.temperature, maxTemp, minTemp),
                                        statusColor: _tempColor(
                                            data.temperature, maxTemp, minTemp),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _TempHumCard(
                                        title: 'Humidity',
                                        value:
                                            '${data.humidity.toStringAsFixed(0)}%',
                                        icon: Icons.cloud,
                                        iconColor: Colors.blue,
                                        status: _humStatus(
                                            data.humidity, humMax, humMin),
                                        statusColor: _humColor(
                                            data.humidity, humMax, humMin),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Row 2: Feed Level & Water Container
                                StreamBuilder<ActuatorState>(
                                  stream: FirebaseService().actuatorsStream(),
                                  builder: (context, actuatorSnap) {
                                    final actuatorData = actuatorSnap.data ??
                                        const ActuatorState();
                                    return IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: _FeedLevelCard(
                                              data: data,
                                              isDispensing:
                                                  actuatorData.feedServo,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _WaterContainerCard(
                                              data: data,
                                              isRefilling:
                                                  actuatorData.waterServo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Row 3: Feed Container (ultrasonic)
                                StreamBuilder<Map<String, dynamic>>(
                                  stream: FirebaseService().sensorRawStream(),
                                  builder: (context, snap) => _FeedContainerCard(
                                      raw: snap.data ??
                                          const <String, dynamic>{}),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Environmental Control Status ───────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 14, 12),
                            child: StreamBuilder<ActuatorState>(
                              stream: FirebaseService().actuatorsStream(),
                              builder: (context, actuatorSnapshot) {
                                final actuatorData =
                                    actuatorSnapshot.data ??
                                        const ActuatorState();
                                return _EnvironmentalControlStatus(
                                    data: actuatorData);
                              },
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
            '$_greeting,\n$_userName!',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
    return kStatusGreen;
  }

  String _tempStatus(double t, double maxTemp, double minTemp) {
    if (t > maxTemp) return 'High';
    if (t < minTemp) return 'Low';
    return 'Normal';
  }

  String _humStatus(double h, double humMax, double humMin) {
    if (h > humMax) return 'High';
    if (h < humMin) return 'Low';
    return 'Normal';
  }

  Color _humColor(double h, double humMax, double humMin) {
    if (h > humMax) return const Color(0xFFFF6B6B);
    if (h < humMin) return const Color(0xFFFFA500);
    return kStatusGreen;
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
        border: Border.all(color: const Color(0xFFFF6B6B), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFF6B6B), size: 24),
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
  final bool isDispensing;

  const _FeedLevelCard({
    required this.data,
    required this.isDispensing,
  });

  @override
  State<_FeedLevelCard> createState() => _FeedLevelCardState();
}

class _FeedLevelCardState extends State<_FeedLevelCard> {
  bool _localPending = false;

  Future<void> _handleDispense() async {
    final controller = TextEditingController(text: '100');

    final percent = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispense Feed'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
              suffixText: '%', labelText: 'Amount to dispense'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(context, val.clamp(0, 100).toDouble());
              }
            },
            child: const Text('Dispense'),
          ),
        ],
      ),
    );

    if (percent == null) return;

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
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _localPending = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final busy = widget.isDispensing || _localPending;

    final percentValue = (data.feedLevelPercent * 100).round();
    String feedStatus;
    Color statusBgColor;
    Color statusTextColor;

    if (data.feedLowActive) {
      feedStatus = 'Low';
      statusBgColor = const Color(0xFFFFF3CD);
      statusTextColor = const Color(0xFF856404);
    } else if (percentValue <= 95) {
      feedStatus = 'Normal';
      statusBgColor = const Color(0xFFD4EDDA);
      statusTextColor = kStatusGreen;
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
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Text('$percentValue%',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: statusBgColor, borderRadius: BorderRadius.circular(6)),
            child: Text(feedStatus,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor)),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : _handleDispense,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4C84E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(busy ? 'Dispensing…' : 'Dispense Now'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Water Container Card ───────────────────────────────────────
// The drinker refills itself on the Pi, so this card shows the
// CONTAINER (second float sensor) - the part a person must refill.
class _WaterContainerCard extends StatelessWidget {
  final SensorData data;
  final bool isRefilling; // true while the Pi is auto-refilling the drinker

  const _WaterContainerCard({required this.data, required this.isRefilling});

  @override
  Widget build(BuildContext context) {
    final level = data.containerLevel.toLowerCase();
    String status;
    String badge;
    Color badgeBg;
    Color badgeText;

    if (level == 'empty') {
      status = 'Empty';
      badge = 'Refill needed';
      badgeBg = const Color(0xFFF8D7DA);
      badgeText = const Color(0xFFDC3545);
    } else if (level == 'ok') {
      status = 'Has water';
      badge = 'OK';
      badgeBg = const Color(0xFFD4EDDA);
      badgeText = kStatusGreen;
    } else {
      status = '--';
      badge = 'Unknown';
      badgeBg = const Color(0xFFE2E3E5);
      badgeText = const Color(0xFF6C757D);
    }

    final drinker = isRefilling
        ? 'Drinker: refilling...'
        : data.waterLevel.toLowerCase() == 'low'
            ? 'Drinker: low'
            : 'Drinker: OK';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Flexible(
                child: Text('Water Container',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(status,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(6)),
            child: Text(badge,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeText)),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Text(drinker,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

// ── Feed Container Card (ultrasonic sensor) ────────────────────
class _FeedContainerCard extends StatelessWidget {
  final Map<String, dynamic> raw;
  const _FeedContainerCard({required this.raw});

  @override
  Widget build(BuildContext context) {
    final percent = (raw['feed_bin_percent'] as num?)?.toDouble();
    final health = raw['sensor_health'];
    final sensorOk = !(health is Map && health['feed_bin'] == false);
    final state = (raw['feed_bin_state'] as String?) ??
        (raw['feed_bin_low_active'] == true ? 'low' : 'ok');

    String status;
    String badge;
    Color badgeBg;
    Color badgeText;
    Color barColor;

    if (!sensorOk) {
      status = 'Sensor problem';
      badge = 'Check the sensor';
      badgeBg = const Color(0xFFF8D7DA);
      badgeText = const Color(0xFFDC3545);
      barColor = Colors.grey;
    } else if (percent == null) {
      status = '--';
      badge = 'Waiting for reading';
      badgeBg = const Color(0xFFE2E3E5);
      badgeText = const Color(0xFF6C757D);
      barColor = Colors.grey;
    } else if (state == 'empty') {
      status = 'Empty';
      badge = 'Refill now';
      badgeBg = const Color(0xFFF8D7DA);
      badgeText = const Color(0xFFDC3545);
      barColor = const Color(0xFFDC3545);
    } else if (state == 'low') {
      status = 'Low';
      badge = 'Refill soon';
      badgeBg = const Color(0xFFFFF3CD);
      badgeText = const Color(0xFF856404);
      barColor = const Color(0xFFFFA500);
    } else {
      status = 'Has feed';
      badge = 'OK';
      badgeBg = const Color(0xFFD4EDDA);
      badgeText = kStatusGreen;
      barColor = kStatusGreen;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Feed Container',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                percent != null && sensorOk
                    ? '${percent.toStringAsFixed(0)}%'
                    : '--',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(width: 12),
              Text(status,
                  style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeText)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percent != null && sensorOk)
                  ? (percent / 100).clamp(0.0, 1.0)
                  : 0,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
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
                  isActive: data.exhaustFan,
                  activeColor: Colors.blue,
                  icon: Icons.air,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DeviceStateBox(
                  title: 'Heating Lamp',
                  isActive: data.heatingLamp,
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
        color:
            isActive ? activeColor.withOpacity(0.1) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.3) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? activeColor : Colors.grey, size: 32),
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