// ============================================================
// lib/screens/settings_screen.dart
// ============================================================
import '../services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'reference_screen.dart';

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

  // Notifications
  bool _notificationsEnabled = true;

  // Manual dispense amount — configured here, triggered from the
  // Dashboard's own "Dispense Now" button (not duplicated on this screen).
  double _manualDispensePercent = 20.0;

  double _feedCapacityGrams = 150.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await FirebaseService().getThresholds();
      final notifEnabled = await FirebaseService().getNotificationsEnabled();

      double minTemp = (data['tempMin'] as num?)?.toDouble() ?? 30;
      double maxTemp = (data['tempMax'] as num?)?.toDouble() ?? 35;

      // Prevent invalid range
      if (minTemp >= maxTemp) {
        minTemp = 30;
        maxTemp = 35;

        await FirebaseService().saveThreshold('tempMin', minTemp);
        await FirebaseService().saveThreshold('tempMax', maxTemp);
      }

      final manualDispensePercent =
          (data['manualDispensePercent'] as num?)?.toDouble() ?? 20;

      setState(() {
        _tempMin = minTemp;
        _tempMax = maxTemp;

        _humidityLimit = (data['humMax'] as num?)?.toDouble() ?? 70;

        _feedAlertPercent = (data['feedLow'] as num?)?.toDouble() ?? 30;

        _manualDispensePercent = manualDispensePercent;

        _notificationsEnabled = notifEnabled;
        _isLoading = false;

        _feedCapacityGrams = (data['feedCapacityGrams'] as num?)?.toDouble() ?? 150;
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
            content: Text(
                'Minimum temperature must be lower than Maximum temperature.'),
          ),
        );
        return;
      }

      if (key == 'tempMax' && value <= _tempMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Maximum temperature must be greater than Minimum temperature.'),
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
            ? const Center(
                child: CircularProgressIndicator(color: Colors.black54))
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

                  // ── Reference Guide (quick access) ─────────
                  _NavCard(
                    cardColor: _card,
                    icon: Icons.menu_book_rounded,
                    iconBg: const Color(0xFFE3EFE0),
                    iconColor: _green,
                    title: 'Reference Guide',
                    subtitle: 'Temperature, humidity & feed chart by week',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReferenceScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Temperature Limit ──────────────────────
                  _SliderCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                    title: 'Minimum Temperature',
                    subtitle: 'Lamp turns ON below this',
                    value: _tempMin,
                    min: 0.0,
                    max: 50.0,
                    unit: '°C',
                    onChanged: (value) {
                      setState(() {
                        _tempMin = value;
                      });
                    },
                    onChangeEnd: (value) async {
                      if (_tempMin >= _tempMax) {
                        _tempMin = _tempMax - 0.5;
                        setState(() {});
                      }

                      await _saveThreshold('tempMin', _tempMin);
                    },
                    cardColor: _card,
                    iconBg: const Color(0xFFFFF3E0),
                    activeColor: _green,
                  ),
                  const SizedBox(height: 12),

                  _SliderCard(
                    icon: Icons.thermostat_rounded,
                    iconColor: Colors.red,
                    title: 'Maximum Temperature',
                    subtitle: 'Exhaust Fan turns ON above this level',
                    value: _tempMax,
                    min: 0.0,
                    max: 50.0,
                    unit: '°C',
                    onChanged: (value) {
                      setState(() {
                        _tempMax = value;
                      });
                    },
                    onChangeEnd: (value) async {
                      if (_tempMax <= _tempMin) {
                        _tempMax = _tempMin + 0.5;
                        setState(() {});
                      }

                      await _saveThreshold('tempMax', _tempMax);
                    },
                    cardColor: _card,
                    iconBg: const Color(0xFFFFDADA),
                    activeColor: _green,
                  ),
                  const SizedBox(height: 12),

                  // ── Humidity Limit ──────────────────────────
                  _SliderCard(
                    cardColor: _card,
                    icon: Icons.cloud_outlined,
                    iconBg: const Color(0xFFD8EAFB),
                    iconColor: const Color(0xFF3B8FE0),
                    title: 'Humidity Limit',
                    subtitle: 'Exhaust Fan turns ON above this level',
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
                    subtitle: 'Alert when the feed is below this level',
                    value: _feedAlertPercent,
                    unit: '%',
                    min: 5,
                    max: 60,
                    activeColor: _green,
                    onChanged: (v) => setState(() => _feedAlertPercent = v),
                    onChangeEnd: (v) => _saveThreshold('feedLow', v),
                  ),
                  const SizedBox(height: 12),
                  _FeedCapacityCard(
                    value: _feedCapacityGrams,
                    onSave: (grams) async {
                      setState(() => _feedCapacityGrams = grams);
                      await _saveThreshold('feedCapacityGrams', grams);
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Simple nav card (icon + title/subtitle + chevron) ───────────
class _NavCard extends StatelessWidget {
  final Color cardColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.cardColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF8A8A8A)),
            ],
          ),
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

// ── Feeder Capacity card (large entry box + confirm button) ─────
class _FeedCapacityCard extends StatefulWidget {
  final double value;
  final ValueChanged<double> onSave;
  const _FeedCapacityCard({required this.value, required this.onSave});

  @override
  State<_FeedCapacityCard> createState() => _FeedCapacityCardState();
}

class _FeedCapacityCardState extends State<_FeedCapacityCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? widget.value.toStringAsFixed(0) : '',
    );
  }

  @override
  void didUpdateWidget(covariant _FeedCapacityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text =
          widget.value > 0 ? widget.value.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = double.tryParse(_controller.text.trim());
    if (val != null && val > 0) {
      final clamped = val.clamp(1, 5000).toDouble();
      widget.onSave(clamped);
      _controller.text = clamped.toStringAsFixed(0);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Feeder capacity set to ${clamped.toStringAsFixed(0)}g')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of grams.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0),
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
                decoration: const BoxDecoration(
                    color: Color(0xFFEFE3FB), shape: BoxShape.circle),
                child: const Icon(Icons.inventory_2_rounded,
                    color: Color(0xFF8B5CF6), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Grams of Feeds',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    SizedBox(height: 2),
                    Text(
                      'Enter total grams of feed. (PER SCHEDULE AMOUNT (g = %))',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
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
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDDAD2)),
                  ),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: '0',
                      suffixText: 'g',
                      suffixStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                width: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3FCB6E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _submit,
                  child: const Icon(Icons.check_rounded,
                      size: 26, color: Colors.white),
                ),
              ),
            ],
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