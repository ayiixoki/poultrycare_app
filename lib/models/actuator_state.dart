// ============================================================
// lib/models/actuator_state.dart
// ============================================================
// Data model that maps to the Firebase Realtime Database node:
//   /actuators/
//
// Separate from SensorData — this node holds live relay/servo
// states written directly by the Pi's control loop, using
// camelCase keys (unlike sensor_data, which uses snake_case).
// ============================================================

class ActuatorState {
  final bool heatingLamp;
  final bool exhaustFan;
  final bool feedServo;
  final bool waterServo;

  const ActuatorState({
    this.heatingLamp = false,
    this.exhaustFan = false,
    this.feedServo = false,
    this.waterServo = false,
  });

  factory ActuatorState.fromMap(Map<dynamic, dynamic> map) {
    return ActuatorState(
      heatingLamp: map['heatingLamp'] as bool? ?? false,
      exhaustFan: map['exhaustFan'] as bool? ?? false,
      feedServo: map['feedServo'] as bool? ?? false,
      waterServo: map['waterServo'] as bool? ?? false,
    );
  }
}