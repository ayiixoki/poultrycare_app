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

  /// Amount of feed to dispense in grams — kept for older schedules
  /// saved before percent-based storage, and as a fallback display value.
  final int amountGrams;

  /// The percent of hopper capacity this schedule dispenses, if it was
  /// set that way. When present, the Pi recomputes grams at fire-time
  /// using the CURRENT hopper capacity setting, instead of the frozen
  /// amountGrams above.
  final int? percent;

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
    this.percent,
    this.enabled = true,
    this.days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  });

  // ── Percent helpers ────────────────────────────────────────────────────
  // One full feeding (100%) = 150g by default. 25/50/75% are fractions of
  // whatever targetGrams (hopper capacity) is passed in.
  static const int fullFeedingGrams = 150;

  static int gramsFromPercent(num percent, {int targetGrams = fullFeedingGrams}) =>
      ((percent / 100) * targetGrams).round();

  int percentOf({int targetGrams = fullFeedingGrams}) =>
      targetGrams > 0 ? ((amountGrams / targetGrams) * 100).round() : 0;

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
      percent: (map['percent'] as num?)?.round(),
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
      if (percent != null) 'percent': percent,
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
    int? percent,
    bool? enabled,
    List<String>? days,
  }) {
    return FeedingSchedule(
      id: id ?? this.id,
      label: label ?? this.label,
      time: time ?? this.time,
      amountGrams: amountGrams ?? this.amountGrams,
      percent: percent ?? this.percent,
      enabled: enabled ?? this.enabled,
      days: days ?? List.from(this.days),
    );
  }

  @override
  String toString() =>
      'FeedingSchedule(id: $id, label: $label, time: $time, '
      'amount: ${amountGrams}g, percent: $percent, enabled: $enabled, days: $days)';
}