// ============================================================
// lib/models/sensor_data.dart
// ============================================================
// Data model that maps to the Firebase Realtime Database node:
//   /sensor_data/
//
// The Raspberry Pi writes this node (firebase_service.push_sensor_data
// plus main.py's extra_updates). This Dart class reads it.
// ============================================================

class SensorData {
  /// Current temperature inside the poultry house (°C).
  final double temperature;

  /// Current relative humidity inside the poultry house (%).
  final double humidity;

  /// Current feed level in grams on the feed plate.
  final double feedLevel;

  /// Maximum feed hopper capacity in grams (matches Pi's config.FEED_CAPACITY_GRAMS).
  final double feedMax;

  /// Feed level as a percentage (0-100), computed on the Pi and pushed as
  /// 'feed_percent'. Single source of truth (the LCD reads the same value).
  final double? feedPercent;

  /// Drinker (trough) status from the Pi: "NORMAL" or "LOW".
  final String waterLevel;

  /// Raw water container float: "ok" or "empty" (instant reading, not the alert state).
  final String containerLevel;

  /// True once the water container has stayed LOW for the confirm time (10 min).
  final bool containerEmptyActive;

  /// Water container, confirmed state: "ok" or "low".
  final String waterBinState;

  /// Water container in plain words: "Normal" or "Low".
  final String waterBinLabel;

  /// Feed container (ultrasonic), confirmed state: "ok", "low" or "empty".
  final String feedBinState;

  /// Feed container in plain words: "Full", "Normal", "Low" or "Empty".
  final String feedBinLabel;

  /// Feed container fill percent from the ultrasonic sensor (kept for reference,
  /// the UI should show [feedBinLabel] instead).
  final double? feedBinPercent;
  final bool feedBinLowActive;

  /// True when the drinker refill (valve / float / supply) has a confirmed problem.
  final bool waterRefillFailed;

  /// Health of every component, debounced on the Pi. true = working.
  /// Keys: dht22, load_cell, feed_bin, feed_servo, water_refill,
  ///       heating_lamp, exhaust_fan. A missing key means "no problem known".
  final Map<String, bool> sensorHealth;

  /// Why a component is faulty (only present while it is faulty). Values:
  /// no_reading, stuck, no_output, error, stuck_open, no_fill, repeating,
  /// no_heat, no_airflow.
  final Map<String, String> sensorFaultReason;

  /// Whether the feeder motor is actively dispensing feed right now.
  final bool feederActive;

  /// Whether the water dispenser valve is currently open.
  final bool waterActive;

  /// Whether the Pi is currently online. NOT read from the Pi's 'system_online'
  /// flag (a Pi that lost WiFi can't set it to false). FirebaseService.sensorStream()
  /// computes it from [lastUpdated] going stale.
  final bool systemOnline;

  final bool feedLowActive;

  /// Unix timestamp (ms) of the last completed feeding dispense.
  final int lastFeedTime;

  /// Unix timestamp (ms) of the Pi's most recent sensor push.
  final int lastUpdated;

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
    this.feedLowActive = false,
    this.lastFeedTime = 0,
    this.lastUpdated = 0,
    this.containerLevel = 'unknown',
    this.containerEmptyActive = false,
    this.waterBinState = 'ok',
    this.waterBinLabel = '--',
    this.feedBinState = 'ok',
    this.feedBinLabel = '--',
    this.feedBinPercent,
    this.feedBinLowActive = false,
    this.waterRefillFailed = false,
    this.sensorHealth = const {},
    this.sensorFaultReason = const {},
  });

  // ── Feed Level as a fraction (0.0 to 1.0), for widgets that need it ──────
  double get feedLevelPercent {
    if (feedPercent != null) return (feedPercent! / 100).clamp(0.0, 1.0);
    return feedMax > 0 ? (feedLevel / feedMax).clamp(0.0, 1.0) : 0.0;
  }

  // ── Component health helpers ──────────────────────────────────────────────
  /// Plain names for the UI.
  static const Map<String, String> componentNames = {
    'dht22': 'Temp & humidity sensor',
    'load_cell': 'Feed scale',
    'feed_bin': 'Feed container sensor',
    'feed_servo': 'Feed dispenser',
    'water_refill': 'Drinker refill',
    'heating_lamp': 'Heating lamp',
    'exhaust_fan': 'Exhaust fan',
  };

  /// Plain-language explanation for a fault reason.
  static const Map<String, String> reasonText = {
    'no_reading': 'Not working. Check its cable.',
    'stuck': 'The reading is stuck. Please check it.',
    'no_output': 'Opened but no feed came out. Check for a jam.',
    'error': 'Had an error. Check the servo.',
    'stuck_open': 'May be stuck open. Check it now.',
    'no_fill': 'Not filling up. Check the valve, supply and float.',
    'repeating': 'Keeps going low. Check for a leak or stuck float.',
    'no_heat': 'Is ON but not warming up. Check the bulb and wiring.',
    'no_airflow': 'Is ON but the air is not improving. Check the fan.',
  };

  /// true unless the Pi has flagged this component as faulty.
  bool isComponentOk(String key) => sensorHealth[key] ?? true;

  /// Keys of every component that currently has a problem, in display order.
  List<String> get problemKeys =>
      componentNames.keys.where((k) => !isComponentOk(k)).toList();

  /// "Feed dispenser: Opened but no feed came out. Check for a jam."
  String problemText(String key) {
    final name = componentNames[key] ?? key;
    final reason = reasonText[sensorFaultReason[key]] ?? 'Not working. Please check it.';
    return '$name: $reason';
  }

  bool get hasProblems => problemKeys.isNotEmpty;

  // ── Factory constructor: build from Firebase Map ──────────────────────────
  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    final bool containerEmpty = map['container_empty_active'] as bool? ?? false;

    // Confirmed container states. If an older Pi version didn't send the new
    // keys yet, fall back to values we can work out ourselves.
    final String waterBinState =
        map['water_bin_state'] as String? ?? (containerEmpty ? 'low' : 'ok');
    final String waterBinLabel = map['water_bin_label'] as String? ??
        (waterBinState == 'low' ? 'Low' : 'Normal');

    final double? feedBinPercent = (map['feed_bin_percent'] as num?)?.toDouble();
    final String feedBinState = map['feed_bin_state'] as String? ?? 'ok';
    String feedBinLabel = map['feed_bin_label'] as String? ?? '';
    if (feedBinLabel.isEmpty) {
      if (feedBinState == 'empty') {
        feedBinLabel = 'Empty';
      } else if (feedBinState == 'low') {
        feedBinLabel = 'Low';
      } else if (feedBinPercent == null) {
        feedBinLabel = '--';
      } else {
        feedBinLabel = feedBinPercent >= 80 ? 'Full' : 'Normal';
      }
    }

    return SensorData(
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      // NOTE: confirm this key against firebase_service.py's push_sensor_data -
      // the Pi pushes 'sensor_data/feed_level' (grams).
      feedLevel: (map['feed_level'] as num?)?.toDouble() ?? 0.0,
      feedMax: (map['feed_max'] as num?)?.toDouble() ?? 200.0,
      feedPercent: (map['feed_percent'] as num?)?.toDouble(),
      waterLevel: map['water_level'] as String? ?? 'UNKNOWN',
      feederActive: map['feeder_active'] as bool? ?? false,
      waterActive: map['water_dispenser'] as bool? ?? false,
      systemOnline: map['system_online'] as bool? ?? false,
      feedLowActive: map['feed_low_active'] as bool? ?? false,
      lastFeedTime: (map['last_feed_time'] as num?)?.toInt() ?? 0,
      lastUpdated: (map['last_updated'] as num?)?.toInt() ?? 0,
      containerLevel: map['container_level'] as String? ?? 'unknown',
      containerEmptyActive: containerEmpty,
      waterBinState: waterBinState,
      waterBinLabel: waterBinLabel,
      feedBinState: feedBinState,
      feedBinLabel: feedBinLabel,
      feedBinPercent: feedBinPercent,
      feedBinLowActive: map['feed_bin_low_active'] as bool? ?? false,
      waterRefillFailed: map['water_refill_failed'] as bool? ?? false,
      sensorHealth: _parseBoolMap(map['sensor_health']),
      sensorFaultReason: _parseStringMap(map['sensor_fault_reason']),
    );
  }

  static Map<String, bool> _parseBoolMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, bool>{};
    raw.forEach((k, v) {
      if (v is bool) out[k.toString()] = v;
    });
    return out;
  }

  static Map<String, String> _parseStringMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    raw.forEach((k, v) {
      if (v is String) out[k.toString()] = v;
    });
    return out;
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
      'feed_low_active': feedLowActive,
      'last_feed_time': lastFeedTime,
      'last_updated': lastUpdated,
      'container_level': containerLevel,
      'container_empty_active': containerEmptyActive,
      'water_bin_state': waterBinState,
      'water_bin_label': waterBinLabel,
      'feed_bin_state': feedBinState,
      'feed_bin_label': feedBinLabel,
      'feed_bin_percent': feedBinPercent,
      'feed_bin_low_active': feedBinLowActive,
      'water_refill_failed': waterRefillFailed,
      'sensor_health': sensorHealth,
      'sensor_fault_reason': sensorFaultReason,
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
    bool? feederActive,
    bool? waterActive,
    bool? systemOnline,
    bool? feedLowActive,
    int? lastFeedTime,
    int? lastUpdated,
    String? containerLevel,
    bool? containerEmptyActive,
    String? waterBinState,
    String? waterBinLabel,
    String? feedBinState,
    String? feedBinLabel,
    double? feedBinPercent,
    bool? feedBinLowActive,
    bool? waterRefillFailed,
    Map<String, bool>? sensorHealth,
    Map<String, String>? sensorFaultReason,
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
      feedLowActive: feedLowActive ?? this.feedLowActive,
      lastFeedTime: lastFeedTime ?? this.lastFeedTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      containerLevel: containerLevel ?? this.containerLevel,
      containerEmptyActive: containerEmptyActive ?? this.containerEmptyActive,
      waterBinState: waterBinState ?? this.waterBinState,
      waterBinLabel: waterBinLabel ?? this.waterBinLabel,
      feedBinState: feedBinState ?? this.feedBinState,
      feedBinLabel: feedBinLabel ?? this.feedBinLabel,
      feedBinPercent: feedBinPercent ?? this.feedBinPercent,
      feedBinLowActive: feedBinLowActive ?? this.feedBinLowActive,
      waterRefillFailed: waterRefillFailed ?? this.waterRefillFailed,
      sensorHealth: sensorHealth ?? this.sensorHealth,
      sensorFaultReason: sensorFaultReason ?? this.sensorFaultReason,
    );
  }
}