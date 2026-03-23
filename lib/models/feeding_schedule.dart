// ============================================================
// lib/models/feeding_schedule.dart
// ============================================================
// Represents a single feeding schedule entry stored under:
//   /schedules/{scheduleId}/
//
// Each schedule tells the Arduino WHEN to open the feeder
// and HOW MUCH feed (grams) to dispense.
// ============================================================

class FeedingSchedule {
  /// Firebase push-key ID, e.g. "-NxAbCdEfGhIjKl"
  final String id;

  /// Human-readable label, e.g. "Morning Feed", "Evening Feed"
  final String label;

  /// Time of day as "HH:mm" 24-hour string, e.g. "06:00", "18:00"
  final String time;

  /// Amount of feed to dispense in grams.
  final int amountGrams;

  /// Whether this schedule is currently active.
  /// Inactive schedules are stored but the Arduino ignores them.
  final bool enabled;

  /// Which days of the week this schedule fires.
  /// Uses short labels: "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
  final List<String> days;

  const FeedingSchedule({
    required this.id,
    required this.label,
    required this.time,
    required this.amountGrams,
    this.enabled = true,
    this.days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  });

  // ── Factory: build from Firebase snapshot map ─────────────────────────────
  factory FeedingSchedule.fromMap(String id, Map<dynamic, dynamic> map) {
    // Firebase stores days as a comma-separated string for simplicity.
    final rawDays = map['days'] as String? ?? 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';
    final daysList = rawDays.split(',').map((d) => d.trim()).toList();

    return FeedingSchedule(
      id: id,
      label: map['label'] as String? ?? 'Feeding',
      time: map['time'] as String? ?? '06:00',
      amountGrams: (map['amount_grams'] as int?) ?? 500,
      enabled: map['enabled'] as bool? ?? true,
      days: daysList,
    );
  }

  // ── Convert to Firebase-compatible map ───────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'time': time,
      'amount_grams': amountGrams,
      'enabled': enabled,
      'days': days.join(','), // store as comma-separated string
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────
  FeedingSchedule copyWith({
    String? id,
    String? label,
    String? time,
    int? amountGrams,
    bool? enabled,
    List<String>? days,
  }) {
    return FeedingSchedule(
      id: id ?? this.id,
      label: label ?? this.label,
      time: time ?? this.time,
      amountGrams: amountGrams ?? this.amountGrams,
      enabled: enabled ?? this.enabled,
      days: days ?? List.from(this.days),
    );
  }

  @override
  String toString() =>
      'FeedingSchedule(id: $id, label: $label, time: $time, '
      'amount: ${amountGrams}g, enabled: $enabled, days: $days)';
}