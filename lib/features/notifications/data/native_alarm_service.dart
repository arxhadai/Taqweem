import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeAlarmService {
  static const _channel = MethodChannel('premium_alarm_channel');

  /// Schedules a native full-screen alarm.
  /// [alarmId] Unique ID for this alarm.
  /// [time] The DateTime when the alarm should fire.
  /// [prayerName] The name of the prayer (e.g., "Fajr").
  /// [soundPath] Optional path to a custom MP3 or bundled resource.
  Future<void> scheduleAlarm({
    required int alarmId,
    required DateTime time,
    required String prayerName,
    String? soundPath,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'alarmId': alarmId,
        'timeInMillis': time.millisecondsSinceEpoch,
        'prayerName': prayerName,
        'soundPath': soundPath,
      });
      debugPrint(
        'NativeAlarmService: Scheduled $prayerName at $time (ID: $alarmId)',
      );
    } on PlatformException catch (e) {
      debugPrint('NativeAlarmService: Failed to schedule alarm: ${e.message}');
    }
  }

  /// Cancels a previously scheduled native alarm.
  Future<void> cancelAlarm(int alarmId) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod('cancelAlarm', {'alarmId': alarmId});
      debugPrint('NativeAlarmService: Cancelled alarm ID: $alarmId');
    } on PlatformException catch (e) {
      debugPrint('NativeAlarmService: Failed to cancel alarm: ${e.message}');
    }
  }
}
