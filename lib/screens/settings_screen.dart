// ============================================================
// lib/screens/settings_screen.dart
// ============================================================
import '../services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  double _tempMin = 30.0;
  double _tempMax = 35.0;

  // Humidity
  double _humidityLimit = 70.0;

  // Feed level (relevant addition — see note below build method)
  double _feedAlertPercent = 30.0;

  // Preferred manual feed dispense amount (grams). The Pi's
  // dispense_feed() runs the servo and polls the load cell until the
  // feeder reaches this weight, then closes — a closed-loop dispense,
  // not a fixed timer. Saved to thresholds/manualDispenseGrams and
  // sent as the target via FirebaseService().quickDispenseGrams().
  double _manualDispenseGrams = 100.0;

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
    final notifEnabled =
        await FirebaseService().getNotificationsEnabled();

    double minTemp =
        (data['tempMin'] as num?)?.toDouble() ?? 30;

    double maxTemp =
        (data['tempMax'] as num?)?.toDouble() ?? 35;

    // Prevent invalid range
    if (minTemp >= maxTemp) {
      minTemp = 30;
      maxTemp = 35;

      await FirebaseService().saveThreshold('tempMin', minTemp);
      await FirebaseService().saveThreshold('tempMax', maxTemp);
    }

    setState(() {
      _tempMin = minTemp;
      _tempMax = maxTemp;

      _humidityLimit =
          (data['humMax'] as num?)?.toDouble() ?? 70;

      _feedAlertPercent =
          (data['feedLow'] as num?)?.toDouble() ?? 30;

      _manualDispenseGrams =
          (data['manualDispenseGrams'] as num?)?.toDouble() ?? 100.0;

      _notificationsEnabled = notifEnabled;
      _isLoading = false;
    });
  } catch (_) {
    setState(() => _isLoading = false);
  }
}

Future<void> _saveThreshold(String key, double value) async {
  try {
    if (key == 'tempMin' && value >= _tempMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum temperature must be lower than Maximum temperature.'),
        ),
      );
      return;
    }

    if (key == 'tempMax' && value <= _tempMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum temperature must be greater than Minimum temperature.'),
        ),
      );
      return;
    }

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
                    icon: Icons.local_fire_department,
                    iconBg: const Color(0xFFFFE0B2),
                    iconColor: Colors.orange,
                    title: 'Minimum Temperature',
                    subtitle: 'Lamp turns ON below this',
                    value: _tempMin,
                    unit: '°C',
                    min: 20,
                    max: 40,
                    activeColor: _green,
                    onChanged: (v) => setState(() => _tempMin = v),
                    onChangeEnd: (v) => _saveThreshold('tempMin', v),
                  ),
                  const SizedBox(height: 12),

                  _SliderCard(
                    cardColor: _card,
                    icon: Icons.thermostat_rounded,
                    iconBg: const Color(0xFFFBDADA),
                    iconColor: const Color(0xFFE2574C),
                    title: 'Maximum Temperature',
                    subtitle: 'Fan turns ON above this',
                    value: _tempMax,
                    unit: '°C',
                    min: 20,
                    max: 45,
                    activeColor: _green,
                    onChanged: (v) => setState(() => _tempMax = v),
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

                  // ── Manual Feed Dispense Amount ──────────────
                  _CustomAmountCard(
                    cardColor: _card,
                    icon: Icons.restaurant_rounded,
                    iconBg: const Color(0xFFDCEEDD),
                    iconColor: const Color(0xFF3FA34D),
                    title: 'Manual Feed Dispense',
                    subtitle: '"Dispense Button" target amount',
                    unit: 'g',
                    value: _manualDispenseGrams,
                    min: 10,
                    max: 1000,
                    activeColor: _green,
                    onChanged: (v) => setState(() => _manualDispenseGrams = v),
                    onChangeEnd: (v) => _saveThreshold('manualDispenseGrams', v),
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
  final int? divisions;
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
    this.divisions,
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
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom amount card: header row + a direct text field where the
//    user types the exact gram amount, clamped to [min, max] and
//    saved once they're done editing.
class _CustomAmountCard extends StatefulWidget {
  final Color cardColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String unit;
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _CustomAmountCard({
    required this.cardColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<_CustomAmountCard> createState() => _CustomAmountCardState();
}

class _CustomAmountCardState extends State<_CustomAmountCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.value.toStringAsFixed(0));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      // Save as soon as the field loses focus (user tapped away).
      if (!_focusNode.hasFocus) _submit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text);
    if (parsed == null) {
      // Invalid input — reset to the last known good value.
      _controller.text = widget.value.toStringAsFixed(0);
      return;
    }
    final clamped = parsed.clamp(widget.min, widget.max);
    _controller.text = clamped.toStringAsFixed(0);
    widget.onChanged(clamped);
    widget.onChangeEnd(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
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
                  color: widget.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFDDDAD2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: widget.activeColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFDDDAD2)),
                    ),
                    suffixText: widget.unit,
                    suffixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Range: ${widget.min.toStringAsFixed(0)}–${widget.max.toStringAsFixed(0)}${widget.unit}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
          ),
        ],
      ),
    );
  }
}
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