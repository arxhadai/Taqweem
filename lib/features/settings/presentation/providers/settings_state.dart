import 'package:flutter/material.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';

enum AlarmType { off, notification, alarm }

class SettingsState {
  final ThemeMode themeMode;
  final PrayerCalculationMethod calculationMethod;
  final Madhab madhab;
  final Sect sect;
  final String highLatitudeRule;
  final bool isNotificationsEnabled;

  // Premium Timing Modes
  final TimingMode timingMode;
  final Map<String, int> offsets;
  final Map<String, DateTime> manualTimes;

  // Alarm Configurations
  final AlarmType sehriAlarmType;
  final AlarmType iftarAlarmType;
  final AlarmType sehriReminderType;
  final AlarmType iftarReminderType;
  final List<int> sehriPreAlarms;
  final List<int> iftarPreAlarms;
  final String alarmSound;
  final String reminderSound;
  final bool vibrationEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.calculationMethod = PrayerCalculationMethod.karachi,
    this.madhab = Madhab.hanafi,
    this.sect = Sect.sunni,
    this.highLatitudeRule = 'None',
    this.isNotificationsEnabled = true,
    this.timingMode = TimingMode.calculation,
    this.offsets = const {},
    this.manualTimes = const {},
    this.sehriAlarmType = AlarmType.notification,
    this.iftarAlarmType = AlarmType.notification,
    this.sehriReminderType = AlarmType.notification,
    this.iftarReminderType = AlarmType.notification,
    this.sehriPreAlarms = const [],
    this.iftarPreAlarms = const [],
    this.alarmSound = 'default',
    this.reminderSound = 'default',
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    PrayerCalculationMethod? calculationMethod,
    Madhab? madhab,
    Sect? sect,
    String? highLatitudeRule,
    bool? isNotificationsEnabled,
    TimingMode? timingMode,
    Map<String, int>? offsets,
    Map<String, DateTime>? manualTimes,
    AlarmType? sehriAlarmType,
    AlarmType? iftarAlarmType,
    AlarmType? sehriReminderType,
    AlarmType? iftarReminderType,
    List<int>? sehriPreAlarms,
    List<int>? iftarPreAlarms,
    String? alarmSound,
    String? reminderSound,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      sect: sect ?? this.sect,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      timingMode: timingMode ?? this.timingMode,
      offsets: offsets ?? this.offsets,
      manualTimes: manualTimes ?? this.manualTimes,
      sehriAlarmType: sehriAlarmType ?? this.sehriAlarmType,
      iftarAlarmType: iftarAlarmType ?? this.iftarAlarmType,
      sehriReminderType: sehriReminderType ?? this.sehriReminderType,
      iftarReminderType: iftarReminderType ?? this.iftarReminderType,
      sehriPreAlarms: sehriPreAlarms ?? this.sehriPreAlarms,
      iftarPreAlarms: iftarPreAlarms ?? this.iftarPreAlarms,
      alarmSound: alarmSound ?? this.alarmSound,
      reminderSound: reminderSound ?? this.reminderSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
