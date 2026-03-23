// ============================================================
// lib/utils/constants.dart
// ============================================================
// App-wide constants: Firebase Realtime Database paths,
// default thresholds, and any magic numbers used in the app.
//
// Keeping all paths here prevents typos when you write to
// or read from Firebase.  If you rename a node in Firebase,
// you only change it in ONE place.
// ============================================================

class AppConstants {
  AppConstants._();

  // ── Firebase Realtime Database Paths ──────────────────────────────────────
  // Root node for all live sensor readings from the Arduino.
  static const String dbSensorData = 'sensor_data';

  // Inside sensor_data, these are the individual field keys.
  static const String dbTemperature = 'temperature';      // double  e.g. 30.5
  static const String dbHumidity = 'humidity';            // double  e.g. 65.2
  static const String dbFeedLevel = 'feed_level';         // double  e.g. 1.5 (kg)
  static const String dbFeedMax = 'feed_max';             // double  e.g. 5.0 (kg) — capacity of hopper
  static const String dbWaterLevel = 'water_level';       // String  "FULL" | "LOW" | "EMPTY"
  static const String dbHeatingLamp = 'heating_lamp';     // bool    true = ON
  static const String dbCoolingFan = 'cooling_fan';       // bool    true = ON
  static const String dbFeederActive = 'feeder_active';   // bool    true = dispensing
  static const String dbWaterActive = 'water_dispenser';  // bool    true = dispensing
  static const String dbSystemOnline = 'system_online';   // bool    true = Arduino connected
  static const String dbLastFeedTime = 'last_feed_time';  // int     Unix timestamp ms

  // Root node for feeding schedule entries.
  static const String dbSchedules = 'schedules';

  // Root node for activity log entries.
  static const String dbLogs = 'logs';

  // Root node for app/user settings stored in Firebase.
  static const String dbSettings = 'settings';

  // Settings field keys.
  static const String dbMinTemp = 'min_temp';         // double  default: 28.0 °C
  static const String dbMaxTemp = 'max_temp';         // double  default: 35.0 °C
  static const String dbAutoClimate = 'auto_climate'; // bool    auto heating/cooling
  static const String dbAutoFeeding = 'auto_feeding'; // bool    use schedules automatically

  // ── Default Threshold Values ──────────────────────────────────────────────
  /// Minimum safe temperature inside the poultry house (°C).
  static const double defaultMinTemp = 28.0;

  /// Maximum safe temperature inside the poultry house (°C).
  static const double defaultMaxTemp = 35.0;

  /// Feed level percentage below which a "Low Feed" warning is shown.
  static const double lowFeedThreshold = 0.30; // 30 %

  /// Maximum feed hopper capacity in kilograms.
  static const double feedHopperCapacity = 5.0;

  // ── Dispense Durations ────────────────────────────────────────────────────
  /// How long (seconds) the feeder motor runs per "Quick Dispense" tap.
  static const int quickDispenseSeconds = 10;

  // ── Schedule Days ────────────────────────────────────────────────────────
  /// Ordered list of day-of-week short labels used in schedule checkboxes.
  static const List<String> weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  // ── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'PoultryCare';
  static const String appTagline = 'Smart Feeding & Environmental Control';
  static const String appVersion = '1.0.0';
}