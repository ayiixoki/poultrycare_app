// ============================================================
// lib/screens/settings_screen.dart
// ============================================================
import '../services/firebase_service.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _bg = Color(0xFFEAE7DF);
  static const Color _card = Color(0xFFF7F5F0);
  static const Color _green = Color(0xFF3FCB6E);
  static const Color _subtitleGray = Color(0xFF8A8A8A);

  // Existing 'thresholds' node in Realtime Database — keys already in
  // use by the rest of the app: tempMax, tempMin, humMax, humMin, feedLow.
  // We read/write to this node directly instead of creating a new
  // 'settings' node, so this screen stays the single source of truth
  // for the same data everything else already relies on.


  bool _isLoading = true;

  // Temperature
  double _tempLimit = 32.0;

  // Humidity
  double _humidityLimit = 70.0;

  // Feed level (relevant addition — see note below build method)
  double _feedAlertPercent = 30.0;

  // Water level
  double _waterAlertPercent = 30.0;

  // Notifications
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

Future<void> _loadSettings() async {
  try {
    final data = await FirebaseService().getThresholds();
    final notifEnabled = await FirebaseService().getNotificationsEnabled();

    setState(() {
      _tempLimit = (data['tempMax'] as num?)?.toDouble() ?? _tempLimit;
      _humidityLimit = (data['humMax'] as num?)?.toDouble() ?? _humidityLimit;
      _feedAlertPercent = (data['feedLow'] as num?)?.toDouble() ?? _feedAlertPercent;
      _waterAlertPercent = (data['waterLow'] as num?)?.toDouble() ?? _waterAlertPercent;
      _notificationsEnabled = notifEnabled;
      _isLoading = false;
    });
  } catch (_) {
    setState(() => _isLoading = false);
  }
}

Future<void> _saveThreshold(String key, double value) async {
  try {
    await FirebaseService().saveThreshold(key, value);
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to save setting.')),
    );
  }
}

Future<void> _saveNotifications(bool value) async {
  try {
    await FirebaseService().setNotificationsEnabled(value);
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to save setting.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.black54))
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  // ── Header ──────────────────────────────────
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Adjust farm preferences',
                    style: TextStyle(fontSize: 14, color: _subtitleGray),
                  ),
                  const SizedBox(height: 20),

                  // ── Temperature Limit ──────────────────────
                  _SliderCard(
                    cardColor: _card,
                    icon: Icons.thermostat_rounded,
                    iconBg: const Color(0xFFFBDADA),
                    iconColor: const Color(0xFFE2574C),
                    title: 'Temperature Limit',
                    subtitle: 'Alert when Too Hot',
                    value: _tempLimit,
                    unit: '°C',
                    min: 20,
                    max: 45,
                    activeColor: _green,
                    onChanged: (v) => setState(() => _tempLimit = v),
                    onChangeEnd: (v) => _saveThreshold('tempMax', v),
                  ),
                  const SizedBox(height: 12),

                  // ── Humidity Limit ──────────────────────────
                  _SliderCard(
                    cardColor: _card,
                    icon: Icons.cloud_outlined,
                    iconBg: const Color(0xFFD8EAFB),
                    iconColor: const Color(0xFF3B8FE0),
                    title: 'Humidity Limit',
                    subtitle: 'Alert when high humid',
                    value: _humidityLimit,
                    unit: '%',
                    min: 0,
                    max: 100,
                    activeColor: _green,
                    onChanged: (v) => setState(() => _humidityLimit = v),
                    onChangeEnd: (v) => _saveThreshold('humMax', v),
                  ),
                  const SizedBox(height: 12),

                  // ── Feed Level Alert (relevant addition) ─────
                  // Reads/writes the existing thresholds/feedLow value
                  // already used elsewhere in the app, instead of a
                  // separate settings field.
                  _SliderCard(
                    cardColor: _card,
                    icon: Icons.grain_rounded,
                    iconBg: const Color(0xFFFBE7CE),
                    iconColor: const Color(0xFFD68A2A),
                    title: 'Feed Level Alert',
                    subtitle: 'Alert when feed is low',
                    value: _feedAlertPercent,
                    unit: '%',
                    min: 5,
                    max: 60,
                    activeColor: _green,
                    onChanged: (v) =>
                        setState(() => _feedAlertPercent = v),
                    onChangeEnd: (v) => _saveThreshold('feedLow', v),
                  ),
                  const SizedBox(height: 12),

                  // ── Water Limit ───────────────────────────────
                  _SliderCard(
                    cardColor: _card,
                    icon: Icons.water_drop_rounded,
                    iconBg: const Color(0xFFD6EEF7),
                    iconColor: const Color(0xFF1FA3C9),
                    title: 'Water Limit',
                    subtitle: 'Alert when Low',
                    value: _waterAlertPercent,
                    unit: '%',
                    min: 5,
                    max: 60,
                    activeColor: _green,
                    onChanged: (v) =>
                        setState(() => _waterAlertPercent = v),
                    onChangeEnd: (v) => _saveThreshold('waterLow', v),
                  ),
                  const SizedBox(height: 12),

                  // ── Notifications ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3E2D6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded,
                              color: Color(0xFF6B6B5E), size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Enable Alerts on Phone',
                                style: TextStyle(
                                    fontSize: 13, color: _subtitleGray),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          activeColor: Colors.white,
                          activeTrackColor: _green,
                          onChanged: (v) {
                            setState(() => _notificationsEnabled = v);
                            _saveNotifications(v);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Center(
                    child: Text(
                      'PoultryCare — Pampanga State University',
                      style: TextStyle(fontSize: 11, color: _subtitleGray),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Slider card (matches photo style exactly) ───────────────────
class _SliderCard extends StatelessWidget {
  final Color cardColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double value;
  final String unit;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _SliderCard({
    required this.cardColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}$unit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: activeColor,
              inactiveTrackColor: const Color(0xFFDDDAD2),
              thumbColor: Colors.white,
              thumbShape: const _RingThumbShape(ringColor: Color(0xFF3FCB6E)),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom thumb: white circle with green ring, matches photo ──
class _RingThumbShape extends SliderComponentShape {
  final Color ringColor;
  const _RingThumbShape({required this.ringColor});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(18, 18);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}