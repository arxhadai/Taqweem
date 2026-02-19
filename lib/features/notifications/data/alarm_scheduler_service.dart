import 'package:flutter/foundation.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/features/notifications/data/notification_service.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_state.dart';

class AlarmSchedulerService {
  final NotificationService _notificationService;

  AlarmSchedulerService(this._notificationService);

  Future<void> scheduleAll({
    required Map<String, PrayerTimeModel> finalPrayerTimes,
    required SettingsState settings,
    required int dayOffset,
  }) async {
    final now = DateTime.now();

    // We handle Sehri (Fajr) and Iftar (Maghrib)
    final fajrModel = finalPrayerTimes['Fajr'];
    final maghribModel = finalPrayerTimes['Maghrib'];

    if (fajrModel != null && settings.sehriAlarmType != AlarmType.off) {
      if (fajrModel.finalTime.isAfter(now)) {
        final baseId = 1000 + (dayOffset * 100);
        final isSehriAlarm = settings.sehriAlarmType == AlarmType.alarm;
        
        debugPrint(
          'AlarmSchedulerService: Scheduling Sehri alarm - type: ${settings.sehriAlarmType}, isAlarm: $isSehriAlarm',
        );
        
        await _notificationService.scheduleNotification(
          id: baseId,
          title: 'Sehri Time Ends',
          body: 'Sehri time has ended. Please stop eating.',
          scheduledDate: fajrModel.finalTime,
          sound: settings.alarmSound,
          vibration: settings.vibrationEnabled,
          isAlarm: isSehriAlarm,
        );

        // Pre-alarms
        for (int min in settings.sehriPreAlarms) {
          final preTime = fajrModel.finalTime.subtract(Duration(minutes: min));
          if (preTime.isBefore(now)) continue;

          await _notificationService.scheduleNotification(
            id: baseId + min,
            title: 'Sehri Ending Soon',
            body: '$min minutes left until Sehri ends.',
            scheduledDate: preTime,
            sound: settings.reminderSound,
            vibration: settings.vibrationEnabled,
            isAlarm: settings.sehriReminderType == AlarmType.alarm,
          );
        }
      }
    }

    if (maghribModel != null && settings.iftarAlarmType != AlarmType.off) {
      if (maghribModel.finalTime.isAfter(now)) {
        final baseId = 2000 + (dayOffset * 100);
        final isIftarAlarm = settings.iftarAlarmType == AlarmType.alarm;
        
        debugPrint(
          'AlarmSchedulerService: Scheduling Iftar alarm - type: ${settings.iftarAlarmType}, isAlarm: $isIftarAlarm',
        );
        
        await _notificationService.scheduleNotification(
          id: baseId,
          title: 'Iftar Time',
          body: 'It is time for Iftar. Acceptance of your fast.',
          scheduledDate: maghribModel.finalTime,
          sound: settings.alarmSound,
          vibration: settings.vibrationEnabled,
          isAlarm: isIftarAlarm,
        );

        // Pre-alarms
        for (int min in settings.iftarPreAlarms) {
          final preTime = maghribModel.finalTime.subtract(
            Duration(minutes: min),
          );
          if (preTime.isBefore(now)) continue;

          await _notificationService.scheduleNotification(
            id: baseId + min,
            title: 'Iftar Approaching',
            body: '$min minutes left until Iftar.',
            scheduledDate: preTime,
            sound: settings.reminderSound,
            vibration: settings.vibrationEnabled,
            isAlarm: settings.iftarReminderType == AlarmType.alarm,
          );
        }
      }
    }
  }
}
