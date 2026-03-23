// ============================================================
// lib/models/activity_log.dart
// ============================================================
// Represents a single log entry stored under:
//   /logs/{logId}/
//
// Logs are written by BOTH the Arduino (sensor events) and
// the mobile app (manual commands like "Dispense Feed").
// ============================================================

/// Categorizes log entries — used to choose icon/color in the UI.
enum LogType {
  feeding,    // Scheduled or manual feed dispense
  alert,      // Temperature out of range, empty feed, etc.
  info,       // Informational — schedule changes, app reconnected
  climate,    // Heating lamp / cooling fan events
  water,      // Water dispense events
}

class ActivityLog {
  /// Firebase push-key ID.
  final String id;

  /// Category of the log entry — determines icon and badge color.
  final LogType type;

  /// Short title shown in bold, e.g. "Morning Feed Completed"
  final String title;

  /// Full description of the event.
  final String message;

  /// Unix timestamp in milliseconds when the event occurred.
  final int timestamp;

  /// Whether this log entry has been read/seen by the user.
  final bool isRead;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  // ── Factory: build from Firebase map ─────────────────────────────────────
  factory ActivityLog.fromMap(String id, Map<dynamic, dynamic> map) {
    // Map the stored string back to the LogType enum.
    LogType parseType(String? raw) {
      switch (raw) {
        case 'feeding':  return LogType.feeding;
        case 'alert':    return LogType.alert;
        case 'climate':  return LogType.climate;
        case 'water':    return LogType.water;
        default:         return LogType.info;
      }
    }

    return ActivityLog(
      id: id,
      type: parseType(map['type'] as String?),
      title: map['title'] as String? ?? 'Event',
      message: map['message'] as String? ?? '',
      timestamp: (map['timestamp'] as int?) ?? 0,
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  // ── Convert to Firebase map ───────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    String typeStr;
    switch (type) {
      case LogType.feeding:  typeStr = 'feeding';  break;
      case LogType.alert:    typeStr = 'alert';    break;
      case LogType.climate:  typeStr = 'climate';  break;
      case LogType.water:    typeStr = 'water';    break;
      default:               typeStr = 'info';
    }
    return {
      'type': typeStr,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'is_read': isRead,
    };
  }

  /// Returns the timestamp as a readable "Today · HH:mm AM/PM" string.
  String get timeLabel {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(dt.year, dt.month, dt.day);

    final timeStr = _formatTime(dt);
    if (logDay == today) return 'Today · $timeStr';

    final yesterday = today.subtract(const Duration(days: 1));
    if (logDay == yesterday) return 'Yesterday · $timeStr';

    return '${dt.day}/${dt.month}/${dt.year} · $timeStr';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}