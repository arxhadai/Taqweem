import 'package:flutter/foundation.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/features/notifications/data/notification_service.dart';
import 'package:ramzan_companion/features/notifications/domain/alarm_event_type.dart';
import 'package:ramzan_companion/features/notifications/data/alarm_sound_manager.dart';
// removed unused imports
import 'package:ramzan_companion/features/settings/presentation/providers/settings_state.dart';

class AlarmSchedulerService {
  final NotificationService _notificationService;
  final AlarmSoundManager? _soundManager;

  AlarmSchedulerService(this._notificationService, [this._soundManager]);

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
        
        final soundName = _soundManager?.getSoundForEvent(AlarmEventType.sehriStart) ?? settings.alarmSound;
        debugPrint('DEBUG [AlarmSchedulerService] Sehri START: soundName=$soundName, eventType=${AlarmEventType.sehriStart.name}');
        await _notificationService.scheduleNotification(
          id: baseId,
          title: 'Sehri Time Ends',
          body: 'Sehri time has ended. Please stop eating.',
          scheduledDate: fajrModel.finalTime,
          sound: soundName,
          eventType: AlarmEventType.sehriStart,
          vibration: settings.vibrationEnabled,
          isAlarm: isSehriAlarm,
        );

        // Pre-alarms
        for (int min in settings.sehriPreAlarms) {
          final preTime = fajrModel.finalTime.subtract(Duration(minutes: min));
          if (preTime.isBefore(now)) continue;

          final reminderSoundName = _soundManager?.getSoundForEvent(AlarmEventType.sehriReminder) ?? settings.reminderSound;
          await _notificationService.scheduleNotification(
            id: baseId + min,
            title: 'Sehri Ending Soon',
            body: '$min minutes left until Sehri ends.',
            scheduledDate: preTime,
            sound: reminderSoundName,
            eventType: AlarmEventType.sehriReminder,
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
        
        final soundName = _soundManager?.getSoundForEvent(AlarmEventType.iftarStart) ?? settings.alarmSound;
        await _notificationService.scheduleNotification(
          id: baseId,
          title: 'Iftar Time',
          body: 'It is time for Iftar. Acceptance of your fast.',
          scheduledDate: maghribModel.finalTime,
          sound: soundName,
          eventType: AlarmEventType.iftarStart,
          vibration: settings.vibrationEnabled,
          isAlarm: isIftarAlarm,
        );

        // Pre-alarms
        for (int min in settings.iftarPreAlarms) {
          final preTime = maghribModel.finalTime.subtract(
            Duration(minutes: min),
          );
          if (preTime.isBefore(now)) continue;

          final reminderSoundName = _soundManager?.getSoundForEvent(AlarmEventType.iftarReminder) ?? settings.reminderSound;
          await _notificationService.scheduleNotification(
            id: baseId + min,
            title: 'Iftar Approaching',
            body: '$min minutes left until Iftar.',
            scheduledDate: preTime,
            sound: reminderSoundName,
            eventType: AlarmEventType.iftarReminder,
            vibration: settings.vibrationEnabled,
            isAlarm: settings.iftarReminderType == AlarmType.alarm,
          );
        }
      }
    }
  }
}
