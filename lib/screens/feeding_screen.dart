// ============================================================
// lib/screens/feeding_screen.dart
// ============================================================
// Tab 1: Feeding
// Shows all feeding schedules and allows:
//   • Toggling a schedule on/off
//   • Adding a new schedule (bottom sheet form)
//   • Editing an existing schedule
//   • Deleting a schedule
//
// Data is streamed live from Firebase so changes from ANY device
// (including the Arduino's schedule trigger) appear instantly.
// ============================================================

import 'package:flutter/material.dart';
import '../models/feeding_schedule.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/schedule_tile.dart';

class FeedingScreen extends StatelessWidget {
  const FeedingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      floatingActionButton: FloatingActionButton.extended(
        // FAB to add a new feeding schedule.
        onPressed: () => _showScheduleSheet(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Schedule',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<FeedingSchedule>>(
        stream: FirebaseService().schedulesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final schedules = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // ── Page header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Feeding Schedules',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${schedules.where((s) => s.enabled).length} active of ${schedules.length} schedules',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Empty state ───────────────────────────────────────────
              if (schedules.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌾', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text('No schedules yet',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Add Schedule" to set up your\nfirst automated feeding time.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Schedule list ─────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final schedule = schedules[index];
                    return ScheduleTile(
                      schedule: schedule,
                      onToggle: (enabled) => FirebaseService()
                          .toggleSchedule(schedule.id, enabled),
                      onEdit: () => _showScheduleSheet(context, schedule),
                      onDelete: () => _confirmDelete(context, schedule),
                    );
                  },
                  childCount: schedules.length,
                ),
              ),

              // Bottom padding so FAB doesn't cover last item.
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // ── Add/Edit bottom sheet ─────────────────────────────────────────────────
  /// Shows a modal bottom sheet form.
  /// If [existing] is null, it's an ADD operation.
  /// If [existing] is provided, it's an EDIT operation.
  void _showScheduleSheet(BuildContext context, FeedingSchedule? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows sheet to expand for keyboard
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFormSheet(existing: existing),
    );
  }

  // ── Delete confirmation dialog ────────────────────────────────────────────
  void _confirmDelete(BuildContext context, FeedingSchedule schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
            'Delete "${schedule.label}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService().deleteSchedule(schedule.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${schedule.label}" deleted')),
              );
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Schedule form bottom sheet ────────────────────────────────────────────────
class _ScheduleFormSheet extends StatefulWidget {
  final FeedingSchedule? existing;
  const _ScheduleFormSheet({this.existing});

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _amountCtrl;

  // Currently selected time.
  late TimeOfDay _selectedTime;

  // Which days are checked.
  late List<String> _selectedDays;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;

    // Pre-fill with existing data or defaults.
    _labelCtrl = TextEditingController(text: s?.label ?? '');
    _amountCtrl = TextEditingController(
        text: s != null ? s.amountGrams.toString() : '500');

    // Parse existing time or default to 06:00.
    if (s != null) {
      final parts = s.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 6,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      _selectedTime = const TimeOfDay(hour: 6, minute: 0);
    }

    _selectedDays = s != null
        ? List.from(s.days)
        : List.from(AppConstants.weekDays);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── Time picker ──────────────────────────────────────────────────────────
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Format TimeOfDay to "HH:mm" string ───────────────────────────────────
  String get _timeString {
    final h = _selectedTime.hour.toString().padLeft(2, '0');
    final m = _selectedTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Save handler ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final schedule = FeedingSchedule(
      id: widget.existing?.id ?? '',
      label: _labelCtrl.text.trim(),
      time: _timeString,
      amountGrams: int.tryParse(_amountCtrl.text) ?? 500,
      enabled: widget.existing?.enabled ?? true,
      days: List.from(_selectedDays),
    );

    try {
      if (widget.existing != null) {
        await FirebaseService().updateSchedule(schedule);
      } else {
        await FirebaseService().addSchedule(schedule);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existing != null
              ? 'Schedule updated!'
              : 'Schedule added!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save schedule')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.existing != null ? 'Edit Schedule' : 'New Schedule',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 20),

              // ── Label field ───────────────────────────────────────────
              Text('LABEL', style: _labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _labelCtrl,
                decoration:
                    const InputDecoration(hintText: 'e.g. Morning Feed'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a label' : null,
              ),

              const SizedBox(height: 16),

              // ── Time picker button ────────────────────────────────────
              Text('TIME', style: _labelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Amount field ──────────────────────────────────────────
              Text('AMOUNT (GRAMS)', style: _labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '500',
                  suffixText: 'g',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Day selector ──────────────────────────────────────────
              Text('DAYS', style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 1), // "M", "T", etc.
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ── Save button ───────────────────────────────────────────
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Save Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );
}