// ============================================================
// lib/screens/settings_screen.dart
// ============================================================
// Settings screen accessible from the AppBar gear icon.
// Allows the farmer to configure:
//   • Minimum safe temperature threshold
//   • Maximum safe temperature threshold
//   • Auto Climate mode (Arduino controls heating/cooling)
//   • Auto Feeding mode (Arduino follows schedules automatically)
//   • Sign out
//
// Settings are stored in Firebase under /settings/ so the
// Arduino also reads them (min_temp and max_temp control the
// automatic heating/cooling logic on the microcontroller).
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── State variables ───────────────────────────────────────────────────────
  bool _isLoading = true;   // true while fetching settings from Firebase
  bool _isSaving = false;   // true while saving changes to Firebase

  // Settings values — initialized from Firebase, then editable here.
  double _minTemp = AppConstants.defaultMinTemp;
  double _maxTemp = AppConstants.defaultMaxTemp;
  bool _autoClimate = true;
  bool _autoFeeding = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ── Load current settings from Firebase ──────────────────────────────────
  Future<void> _loadSettings() async {
    try {
      final data = await FirebaseService().getSettings();
      setState(() {
        _minTemp = (data['min_temp'] as num?)?.toDouble()
            ?? AppConstants.defaultMinTemp;
        _maxTemp = (data['max_temp'] as num?)?.toDouble()
            ?? AppConstants.defaultMaxTemp;
        _autoClimate = data['auto_climate'] as bool? ?? true;
        _autoFeeding = data['auto_feeding'] as bool? ?? true;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Save changed settings to Firebase ────────────────────────────────────
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseService().saveSettings({
        'min_temp': _minTemp,
        'max_temp': _maxTemp,
        'auto_climate': _autoClimate,
        'auto_feeding': _autoFeeding,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save settings.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    // Show confirmation dialog first.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    // Navigate back to LoginScreen, clearing the entire stack.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          // Save button in the AppBar
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // ── Section: Temperature ───────────────────────────────
                const _SectionHeader('TEMPERATURE THRESHOLDS'),
                _SettingsCard(
                  children: [
                    // Min temperature slider
                    _SliderRow(
                      label: 'Min Temperature',
                      value: _minTemp,
                      unit: '°C',
                      min: 20.0,
                      max: 35.0,
                      onChanged: (v) {
                        setState(() {
                          _minTemp = v;
                          // Ensure min doesn't exceed max.
                          if (_minTemp >= _maxTemp) _maxTemp = _minTemp + 1;
                        });
                      },
                      description:
                          'Heating lamp activates when temp falls below this.',
                      activeColor: AppColors.info,
                    ),
                    const Divider(height: 1),
                    // Max temperature slider
                    _SliderRow(
                      label: 'Max Temperature',
                      value: _maxTemp,
                      unit: '°C',
                      min: 25.0,
                      max: 45.0,
                      onChanged: (v) {
                        setState(() {
                          _maxTemp = v;
                          // Ensure max doesn't go below min.
                          if (_maxTemp <= _minTemp) _minTemp = _maxTemp - 1;
                        });
                      },
                      description:
                          'Cooling fan activates when temp exceeds this.',
                      activeColor: AppColors.error,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Section: Automation ────────────────────────────────
                const _SectionHeader('AUTOMATION'),
                _SettingsCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.thermostat,
                      iconColor: AppColors.heatingActive,
                      title: 'Auto Climate Control',
                      subtitle:
                          'Arduino automatically manages heating lamp and cooling fan based on temperature thresholds.',
                      value: _autoClimate,
                      onChanged: (v) => setState(() => _autoClimate = v),
                    ),
                    const Divider(height: 1),
                    _ToggleRow(
                      icon: Icons.grain,
                      iconColor: AppColors.feederActive,
                      title: 'Auto Feeding',
                      subtitle:
                          'Arduino automatically dispenses feed at scheduled times.',
                      value: _autoFeeding,
                      onChanged: (v) => setState(() => _autoFeeding = v),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Section: Account ───────────────────────────────────
                const _SectionHeader('ACCOUNT'),
                _SettingsCard(
                  children: [
                    // Currently signed-in user email
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Signed in as',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  FirebaseAuth.instance.currentUser?.email ??
                                      'Unknown',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Sign out button ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Sign Out',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── App version ────────────────────────────────────────
                Center(
                  child: Text(
                    'PoultryCare v${AppConstants.appVersion} — Pampanga State University',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ── Section header label ──────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

// ── Card wrapper for settings groups ─────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

// ── Slider row for temperature thresholds ─────────────────────────────────────
class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String description;
  final Color activeColor;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.description,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              // Current value badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)}$unit',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          // Slider — steps in 0.5°C increments
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).toInt(),
            activeColor: activeColor,
            onChanged: onChanged,
          ),
          Text(description,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Toggle row for automation settings ───────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        )),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}