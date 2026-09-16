// ============================================================
// lib/models/sensor_data.dart
// ============================================================
// Data model that maps to the Firebase Realtime Database node:
//   /sensor_data/
//
// The Arduino writes to this node via the Firebase REST API or
// the Firebase Arduino library.  This Dart class reads it.
// ============================================================

class SensorData {
  /// Current temperature inside the poultry house (°C).
  final double temperature;

  /// Current relative humidity inside the poultry house (%).
  final double humidity;

  /// Current feed level in grams remaining in the hopper.
  final double feedLevel;

  /// Maximum feed hopper capacity in grams (matches Pi's config.FEED_CAPACITY_GRAMS).
  final double feedMax;

  /// Feed level as a percentage (0-100), computed on the Pi from
  /// config.FEED_CAPACITY_GRAMS and pushed directly to Firebase as
  /// 'feed_percent'. This is the single source of truth the LCD also
  /// reads - the app should NOT recalculate this from feedLevel/feedMax.
  final double? feedPercent;

  /// Water level status: "FULL", "LOW", or "EMPTY".
  final String waterLevel;

  /// Whether the feeder motor is actively dispensing feed right now.
  final bool feederActive;

  /// Whether the water dispenser valve is currently open.
  final bool waterActive;

  /// Whether the Pi is connected to Firebase.
  final bool systemOnline;

  /// Unix timestamp (ms) of the last completed feeding dispense.
  final int lastFeedTime;

  const SensorData({
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.feedLevel = 0.0,
    this.feedMax = 200.0,
    this.feedPercent,
    this.waterLevel = 'UNKNOWN',
    this.feederActive = false,
    this.waterActive = false,
    this.systemOnline = false,
    this.lastFeedTime = 0,
  });

  // ── Feed Level as a fraction (0.0 to 1.0), for widgets that need it ──────
  /// Prefers the Pi-computed feed_percent (single source of truth, matches
  /// the LCD exactly). Only falls back to a local ratio if the Pi hasn't
  /// sent feed_percent yet - e.g. right after a fresh deploy before this
  /// field exists in Firebase.
  double get feedLevelPercent {
    if (feedPercent != null) return (feedPercent! / 100).clamp(0.0, 1.0);
    return feedMax > 0 ? (feedLevel / feedMax).clamp(0.0, 1.0) : 0.0;
  }

  // ── Factory constructor: build from Firebase Map ──────────────────────────
  /// Called when reading data from Firebase snapshot.
  /// The [map] argument is the raw Map<dynamic, dynamic> from Firebase.
  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      // NOTE: confirm this key against firebase_service.py's push_sensor_data -
      // it's likely 'feed_weight' (grams), not 'feed_level'.
      feedLevel: (map['feed_level'] as num?)?.toDouble() ?? 0.0,
      feedMax: (map['feed_max'] as num?)?.toDouble() ?? 200.0,
      feedPercent: (map['feed_percent'] as num?)?.toDouble(),
      waterLevel: map['water_level'] as String? ?? 'UNKNOWN',
      feederActive: map['feeder_active'] as bool? ?? false,
      waterActive: map['water_dispenser'] as bool? ?? false,
      systemOnline: map['system_online'] as bool? ?? false,
      lastFeedTime: (map['last_feed_time'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Convert to Map (for writing back to Firebase if needed) ──────────────
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'feed_level': feedLevel,
      'feed_max': feedMax,
      'feed_percent': feedPercent,
      'water_level': waterLevel,
      'feeder_active': feederActive,
      'water_dispenser': waterActive,
      'system_online': systemOnline,
      'last_feed_time': lastFeedTime,
    };
  }

  // ── copyWith: returns a new SensorData with some fields replaced ──────────
  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? feedLevel,
    double? feedMax,
    double? feedPercent,
    String? waterLevel,
    bool? heatingLamp,
    bool? coolingFan,
    bool? feederActive,
    bool? waterActive,
    bool? systemOnline,
    int? lastFeedTime,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      feedLevel: feedLevel ?? this.feedLevel,
      feedMax: feedMax ?? this.feedMax,
      feedPercent: feedPercent ?? this.feedPercent,
      waterLevel: waterLevel ?? this.waterLevel,
      feederActive: feederActive ?? this.feederActive,
      waterActive: waterActive ?? this.waterActive,
      systemOnline: systemOnline ?? this.systemOnline,
      lastFeedTime: lastFeedTime ?? this.lastFeedTime,
    );
  }
}