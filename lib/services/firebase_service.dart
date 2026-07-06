// ============================================================
// lib/services/firebase_service.dart
// ============================================================
// Centralizes ALL Firebase Realtime Database interactions.
// No screen should import firebase_database directly —
// everything goes through FirebaseService.
//
// USAGE (from any screen/provider):
//   final db = FirebaseService();
//   await db.toggleHeatingLamp(true);
//   Stream<SensorData> stream = db.sensorStream();
// ============================================================

import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../models/actuator_state.dart';
import '../models/feeding_schedule.dart';
import '../models/activity_log.dart';
import '../utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  // ── Singleton pattern ─────────────────────────────────────────────────────
  // Using a singleton means only ONE connection is maintained to Firebase
  // regardless of how many widgets use this service.
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal() {
    // Enable offline caching — must be called once, before any other DB calls
    _db.setPersistenceEnabled(true);
    _db.setPersistenceCacheSizeBytes(10000000); // 10MB cache
  }

  // ── Firebase database reference (root) ───────────────────────────────────
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://poultrycare-f816d-default-rtdb.asia-southeast1.firebasedatabase.app/',
);



  // ── Convenience getters for frequently-used references ───────────────────
  DatabaseReference get _sensorRef => _db.ref(AppConstants.dbSensorData);
  DatabaseReference get _actuatorsRef => _db.ref(AppConstants.dbActuators);
    DatabaseReference get _deviceTokensRef => _db.ref(AppConstants.dbDeviceTokens);
  DatabaseReference get _schedulesRef => _db.ref(AppConstants.dbSchedules);
  DatabaseReference get _logsRef => _db.ref(AppConstants.dbLogs);
  DatabaseReference get _settingsRef => _db.ref(AppConstants.dbSettings);
  DatabaseReference get _thresholdsRef => _db.ref('thresholds');
  DatabaseReference get _notifRef => _db.ref('notifications_enabled');
  DatabaseReference get _notificationsRef => _db.ref('notifications');

Stream<List<Map<String, dynamic>>> notificationsStream() {
  return _notificationsRef.limitToLast(50).onValue.map((event) {
    if (!event.snapshot.exists) return [];
    final map = event.snapshot.value as Map<dynamic, dynamic>;
    final list = map.entries.map((e) {
      final v = Map<String, dynamic>.from(e.value as Map);
      v['id'] = e.key.toString();
      return v;
    }).toList();
    list.sort((a, b) => (b['timestamp'] ?? '').toString().compareTo((a['timestamp'] ?? '').toString()));
    return list;
  });
}

  /// Marks key paths to stay cached locally even when no screen
/// is actively listening — keeps dashboard/alerts usable offline.
void enableOfflineSync() {
  _sensorRef.keepSynced(true);
  _actuatorsRef.keepSynced(true);
  _schedulesRef.keepSynced(true);
  _logsRef.keepSynced(true);
  _thresholdsRef.keepSynced(true);
}

/// Streams whether the PHONE has an active connection to Firebase.
Stream<bool> connectionStream() {
  return _db.ref('.info/connected').onValue.map((event) {
    return event.snapshot.value as bool? ?? false;
  });
}

  // ==========================================================================
  // SENSOR DATA — Real-time stream
  // ==========================================================================

  /// Returns a continuous Stream of [SensorData] that updates whenever
  /// the Arduino writes new sensor readings to Firebase.
  ///
  /// Usage in a StreamBuilder:
  ///   stream: FirebaseService().sensorStream()
  Stream<SensorData> sensorStream() {
    return _sensorRef.onValue.map((event) {
      // If the node doesn't exist yet, return empty/default SensorData.
      if (!event.snapshot.exists) return const SensorData();
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return SensorData.fromMap(map);
    });
  }

    /// Returns a continuous Stream of [ActuatorState] that updates whenever
  /// the Pi's control loop changes a relay/servo state.
  Stream<ActuatorState> actuatorsStream() {
    return _actuatorsRef.onValue.map((event) {
      if (!event.snapshot.exists) return const ActuatorState();
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return ActuatorState.fromMap(map);
    });
  }

  // ==========================================================================
  // DEVICE CONTROLS — Write commands back to Firebase
  // The Arduino listens to these paths and reacts accordingly.
  // ==========================================================================

  /// Turns the heating lamp ON (true) or OFF (false).
  Future<void> setHeatingLamp(bool isOn) async {
    await _sensorRef.child(AppConstants.dbHeatingLamp).set(isOn);
    // Log the manual override in the activity log.
    await addLog(ActivityLog(
      id: '',
      type: LogType.climate,
      title: isOn ? 'Heating Lamp ON' : 'Heating Lamp OFF',
      message: isOn
          ? 'Heating lamp was manually activated via mobile app.'
          : 'Heating lamp was manually deactivated via mobile app.',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Turns the cooling fan ON (true) or OFF (false).
  Future<void> setCoolingFan(bool isOn) async {
    await _sensorRef.child(AppConstants.dbCoolingFan).set(isOn);
    await addLog(ActivityLog(
      id: '',
      type: LogType.climate,
      title: isOn ? 'Cooling Fan ON' : 'Cooling Fan OFF',
      message: isOn
          ? 'Cooling fan was manually activated via mobile app.'
          : 'Cooling fan was manually deactivated via mobile app.',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Triggers an immediate ("quick") feed dispense for [seconds] seconds.
  /// The Arduino monitors feeder_active and runs the motor while true.
  Future<void> quickDispense(int seconds) async {
    // Set feeder to active.
    await _sensorRef.child(AppConstants.dbFeederActive).set(true);
    // Write the dispense duration so the Arduino knows when to stop.
    await _sensorRef.child('dispense_seconds').set(seconds);

    await addLog(ActivityLog(
      id: '',
      type: LogType.feeding,
      title: 'Manual Feed Dispense',
      message: 'Quick dispense triggered (${seconds}s) via mobile app.',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

    /// Triggers a manual feed dispense of a specific gram amount.
  Future<void> quickDispenseGrams(double grams) async {
    await _sensorRef.child(AppConstants.dbFeederActive).set(true);
    await _sensorRef.child('manual_dispense_grams').set(grams);

    await addLog(ActivityLog(
      id: '',
      type: LogType.feeding,
      title: 'Manual Feed Dispense',
      message: 'Quick dispense triggered (${grams.toStringAsFixed(0)}g) via mobile app.',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Sets the water dispenser valve ON or OFF.
  Future<void> setWaterDispenser(bool isOn) async {
    await _sensorRef.child(AppConstants.dbWaterActive).set(isOn);
    await addLog(ActivityLog(
      id: '',
      type: LogType.water,
      title: isOn ? 'Water Dispenser ON' : 'Water Dispenser OFF',
      message: isOn
          ? 'Water dispenser opened via mobile app.'
          : 'Water dispenser closed via mobile app.',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  // ==========================================================================
  // FEEDING SCHEDULES — CRUD operations
  // ==========================================================================

  /// Returns a stream of all feeding schedules, sorted by time.
  Stream<List<FeedingSchedule>> schedulesStream() {
    return _schedulesRef.onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final map = event.snapshot.value as Map<dynamic, dynamic>;
      final schedules = map.entries.map((e) {
        return FeedingSchedule.fromMap(
          e.key.toString(),
          e.value as Map<dynamic, dynamic>,
        );
      }).toList();

      // Sort schedules by time string (HH:mm) so they appear in order.
      schedules.sort((a, b) => a.time.compareTo(b.time));
      return schedules;
    });
  }

  /// Adds a new feeding schedule to Firebase.
  /// Firebase auto-generates the push key (unique ID).
  Future<void> addSchedule(FeedingSchedule schedule) async {
    final newRef = _schedulesRef.push();
    await newRef.set(schedule.toMap());
  }

  /// Updates an existing schedule by its Firebase push key [id].
  Future<void> updateSchedule(FeedingSchedule schedule) async {
    await _schedulesRef.child(schedule.id).update(schedule.toMap());
  }

  /// Deletes a schedule by its Firebase push key [id].
  Future<void> deleteSchedule(String id) async {
    await _schedulesRef.child(id).remove();
  }

  /// Toggles just the enabled/disabled state of a schedule.
  /// More efficient than updating the whole object.
  Future<void> toggleSchedule(String id, bool enabled) async {
    await _schedulesRef.child(id).update({'enabled': enabled});
  }

  Future<Map<String, dynamic>> getThresholds() async {
  final snap = await _thresholdsRef.get();
  if (!snap.exists) return {};
  return Map<String, dynamic>.from(snap.value as Map);
}

Future<void> saveThreshold(String key, double value) async {
  await _thresholdsRef.update({key: value});
}

Future<bool> getNotificationsEnabled() async {
  final snap = await _notifRef.get();
  return snap.exists ? (snap.value as bool) : true;
}

Future<void> setNotificationsEnabled(bool value) async {
  await _notifRef.set(value);
}

/// Registers this device's FCM token so the Pi can send it push alerts.
/// Stored as a map (token -> true) so multiple devices/phones can each
/// have their own entry without overwriting each other.
Future<void> saveDeviceToken(String token) async {
  await _deviceTokensRef.child(token).set(true);
}

  // ==========================================================================
  // ACTIVITY LOGS — write only (read is a stream)
  // ==========================================================================

  /// Appends a new log entry.  The [log.id] is ignored — Firebase generates one.
  Future<void> addLog(ActivityLog log) async {
    final newRef = _logsRef.push();
    await newRef.set(log.toMap());
  }

  /// Returns a stream of the latest 50 log entries, newest first.
  Stream<List<ActivityLog>> logsStream() {
    // limitToLast(50) fetches only the 50 most recent entries.
    return _logsRef.limitToLast(50).onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final map = event.snapshot.value as Map<dynamic, dynamic>;
      final logs = map.entries.map((e) {
        return ActivityLog.fromMap(
          e.key.toString(),
          e.value as Map<dynamic, dynamic>,
        );
      }).toList();

      // Sort newest first.
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    });
  }

  Stream<Map<String, dynamic>> thresholdsStream() {
    return _db.ref('thresholds').onValue.map((event) {
      if (!event.snapshot.exists) {
        return {
          'tempMax': AppConstants.defaultMaxTemp,
          'tempMin': AppConstants.defaultMinTemp,
          'feedLow': 30.0,
          'waterLow': 30.0,
          'humMax': 70.0,
        };
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Marks all unread log entries as read.
  Future<void> markAllLogsRead() async {
    final snap = await _logsRef.get();
    if (!snap.exists) return;

    final map = snap.value as Map<dynamic, dynamic>;
    final updates = <String, dynamic>{};
    for (final e in map.entries) {
      final entry = e.value as Map<dynamic, dynamic>;
      if (entry['is_read'] == false) {
        updates['${e.key}/is_read'] = true;
      }
    }
    if (updates.isNotEmpty) await _logsRef.update(updates);
  }

  // ==========================================================================
  // SETTINGS — read and write
  // ==========================================================================

  /// Reads app settings once (not a stream) as a simple Map.
  Future<Map<String, dynamic>> getSettings() async {
    final snap = await _settingsRef.get();
    if (!snap.exists) {
      // Return defaults if nothing is stored yet.
      return {
        'min_temp': AppConstants.defaultMinTemp,
        'max_temp': AppConstants.defaultMaxTemp,
        'auto_climate': true,
        'auto_feeding': true,
        //'manual_dispense_grams': 200.0,
      };
    }
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Writes updated settings back to Firebase.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _settingsRef.update(settings);
  }
}

