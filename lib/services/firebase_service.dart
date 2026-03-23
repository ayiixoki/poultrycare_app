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
  FirebaseService._internal();

  // ── Firebase database reference (root) ───────────────────────────────────
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://poultrycare-app-default-rtdb.asia-southeast1.firebasedatabase.app',
);

  // ── Convenience getters for frequently-used references ───────────────────
  DatabaseReference get _sensorRef => _db.ref(AppConstants.dbSensorData);
  DatabaseReference get _schedulesRef => _db.ref(AppConstants.dbSchedules);
  DatabaseReference get _logsRef => _db.ref(AppConstants.dbLogs);
  DatabaseReference get _settingsRef => _db.ref(AppConstants.dbSettings);

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
      };
    }
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Writes updated settings back to Firebase.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _settingsRef.update(settings);
  }
}