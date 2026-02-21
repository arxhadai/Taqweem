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
    String? eventType,
    String? soundName,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('NativeAlarmService: Skipping - not on Android platform');
      return;
    }

    try {
      debugPrint(
        'NativeAlarmService: About to schedule alarm for $prayerName at $time (ID: $alarmId, soundPath: $soundPath)',
      );
      
      final Map<String, dynamic> payload = {
        'alarmId': alarmId,
        'timeInMillis': time.millisecondsSinceEpoch,
        'prayerName': prayerName,
      };
      if (eventType != null) payload['eventType'] = eventType;
      if (soundName != null) payload['soundName'] = soundName;
      if (soundPath != null && (soundName == null)) payload['soundPath'] = soundPath;

      debugPrint('DEBUG [NativeAlarmService] MethodChannel payload keys: ${payload.keys.toList()}, soundName=$soundName');
      await _channel.invokeMethod('scheduleAlarm', payload);
      debugPrint(
        'NativeAlarmService: Successfully invoked native scheduleAlarm for $prayerName at $time (ID: $alarmId)',
      );
    } on PlatformException catch (e) {
      debugPrint('NativeAlarmService: PlatformException - Failed to schedule alarm: ${e.message}');
    } catch (e) {
      debugPrint('NativeAlarmService: Exception - Failed to schedule alarm: $e');
    }
  }

  /// Checks if the app has permission to schedule exact alarms (Android 12+).
  Future<bool> checkExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final bool result =
          await _channel.invokeMethod('checkExactAlarmPermission') ?? true;
      return result;
    } on PlatformException catch (e) {
      debugPrint(
        'NativeAlarmService: Failed to check exact alarm permission: ${e.message}',
      );
      return false;
    }
  }

  /// Requests the user to disable battery optimizations for the app.
  Future<void> requestBatteryOptimization() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } on PlatformException catch (e) {
      debugPrint(
        'NativeAlarmService: Failed to request battery optimization: ${e.message}',
      );
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
