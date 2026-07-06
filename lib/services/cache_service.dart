import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';

class CacheService {
  static const String sensorKey = 'sensor_cache';

  static Future<void> save(SensorData data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      sensorKey,
      jsonEncode(data.toMap()),
    );
  }

  static Future<SensorData?> load() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(sensorKey);

    if (json == null) return null;

    return SensorData.fromMap(jsonDecode(json));
  }
}