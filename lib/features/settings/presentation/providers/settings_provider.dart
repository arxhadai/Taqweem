import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/core/data/storage_service.dart';
import 'package:ramzan_companion/core/providers/storage_provider.dart';
import 'package:ramzan_companion/features/notifications/presentation/notification_scheduler.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_state.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsState> {
  late StorageService _storage;

  @override
  SettingsState build() {
    _storage = ref.watch(storageServiceProvider);
    return _loadSettings();
  }

  SettingsState _loadSettings() {
    final themeStr = _storage.getString('theme_mode');
    final methodIndex = _storage.getInt('calc_method');
    final madhabIndex = _storage.getInt('madhab');
    final sectIndex = _storage.getInt('sect');
    final highLatRule = _storage.getString('high_lat_rule') ?? 'None';
    final notifsEnabled = _storage.getBool('notifications_enabled');

    final timingModeIndex = _storage.getInt('timing_mode');
    final offsets = _getMapInt('prayer_offsets');
    final manualTimes = _getMapDateTime('manual_times');

    final sehriTypeIndex = _storage.getInt('sehri_alarm_type');
    final iftarTypeIndex = _storage.getInt('iftar_alarm_type');
    final sehriRemIndex = _storage.getInt('sehri_reminder_type');
    final iftarRemIndex = _storage.getInt('iftar_reminder_type');

    final sehriPre = _getIntList('sehri_pre_alarms');
    final iftarPre = _getIntList('iftar_pre_alarms');
    final sound = _storage.getString('alarm_sound');
    final remSound = _storage.getString('reminder_sound');
    final vib = _storage.getBool('vibration_enabled');

    return SettingsState(
      themeMode: themeStr != null
          ? ThemeMode.values.firstWhere(
              (e) => e.toString() == themeStr,
              orElse: () => ThemeMode.system,
            )
          : ThemeMode.system,
      calculationMethod: methodIndex != null
          ? PrayerCalculationMethod.values[methodIndex]
          : PrayerCalculationMethod.karachi,
      madhab: madhabIndex != null ? Madhab.values[madhabIndex] : Madhab.hanafi,
      sect: sectIndex != null ? Sect.values[sectIndex] : Sect.sunni,
      highLatitudeRule: highLatRule,
      isNotificationsEnabled: notifsEnabled ?? true,
      timingMode: timingModeIndex != null
          ? TimingMode.values[timingModeIndex]
          : TimingMode.calculation,
      offsets: offsets,
      manualTimes: manualTimes,
      sehriAlarmType: sehriTypeIndex != null
          ? AlarmType.values[sehriTypeIndex]
          : AlarmType.notification,
      iftarAlarmType: iftarTypeIndex != null
          ? AlarmType.values[iftarTypeIndex]
          : AlarmType.notification,
      sehriReminderType: sehriRemIndex != null
          ? AlarmType.values[sehriRemIndex]
          : AlarmType.notification,
      iftarReminderType: iftarRemIndex != null
          ? AlarmType.values[iftarRemIndex]
          : AlarmType.notification,
      sehriPreAlarms: sehriPre,
      iftarPreAlarms: iftarPre,
      alarmSound: sound ?? 'default',
      reminderSound: remSound ?? 'default',
      vibrationEnabled: vib ?? true,
    );
  }

  Future<void> updateTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.setString('theme_mode', mode.toString());
  }

  Future<void> updateCalculationMethod(PrayerCalculationMethod method) async {
    state = state.copyWith(calculationMethod: method);
    await _storage.setInt('calc_method', method.index);
  }

  Future<void> updateMadhab(Madhab madhab) async {
    state = state.copyWith(madhab: madhab);
    await _storage.setInt('madhab', madhab.index);
  }

  Future<void> updateSect(Sect sect) async {
    state = state.copyWith(sect: sect);
    await _storage.setInt('sect', sect.index);
  }

  Future<void> updateHighLatitudeRule(String rule) async {
    state = state.copyWith(highLatitudeRule: rule);
    await _storage.setString('high_lat_rule', rule);
  }

  Future<void> updateTimingMode(TimingMode mode) async {
    state = state.copyWith(timingMode: mode);
    await _storage.setInt('timing_mode', mode.index);
  }

  Future<void> updateOffsets(Map<String, int> offsets) async {
    state = state.copyWith(offsets: offsets);
    await _saveMapInt('prayer_offsets', offsets);
  }

  Future<void> updateManualTimes(Map<String, DateTime> manualTimes) async {
    state = state.copyWith(manualTimes: manualTimes);
    await _saveMapDateTime('manual_times', manualTimes);
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (enabled) {
      await ref.read(notificationServiceProvider).requestPermissions();
    }
    state = state.copyWith(isNotificationsEnabled: enabled);
    await _storage.setBool('notifications_enabled', enabled);
  }

  Future<void> updateSehriAlarmType(AlarmType type) async {
    state = state.copyWith(sehriAlarmType: type);
    await _storage.setInt('sehri_alarm_type', type.index);
  }

  Future<void> updateIftarAlarmType(AlarmType type) async {
    state = state.copyWith(iftarAlarmType: type);
    await _storage.setInt('iftar_alarm_type', type.index);
  }

  Future<void> updateSehriReminderType(AlarmType type) async {
    state = state.copyWith(sehriReminderType: type);
    await _storage.setInt('sehri_reminder_type', type.index);
  }

  Future<void> updateIftarReminderType(AlarmType type) async {
    state = state.copyWith(iftarReminderType: type);
    await _storage.setInt('iftar_reminder_type', type.index);
  }

  Future<void> updateSehriPreAlarms(List<int> preAlarms) async {
    state = state.copyWith(sehriPreAlarms: preAlarms);
    await _saveIntList('sehri_pre_alarms', preAlarms);
  }

  Future<void> updateIftarPreAlarms(List<int> preAlarms) async {
    state = state.copyWith(iftarPreAlarms: preAlarms);
    await _saveIntList('iftar_pre_alarms', preAlarms);
  }

  Future<void> updateAlarmSound(String sound) async {
    state = state.copyWith(alarmSound: sound);
    await _storage.setString('alarm_sound', sound);
  }

  Future<void> updateReminderSound(String sound) async {
    state = state.copyWith(reminderSound: sound);
    await _storage.setString('reminder_sound', sound);
  }

  Future<void> toggleVibration(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await _storage.setBool('vibration_enabled', enabled);
  }

  List<int> _getIntList(String key) {
    final str = _storage.getString(key);
    if (str == null || str.isEmpty) return [];
    return str
        .split(',')
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e != 0)
        .toList();
  }

  Future<void> _saveIntList(String key, List<int> list) async {
    final str = list.join(',');
    await _storage.setString(key, str);
  }

  Map<String, int> _getMapInt(String key) {
    final str = _storage.getString(key);
    if (str == null || str.isEmpty) return {};
    try {
      final Map<String, int> result = {};
      final parts = str.split(';');
      for (var p in parts) {
        final kv = p.split(':');
        if (kv.length == 2) {
          result[kv[0]] = int.tryParse(kv[1]) ?? 0;
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveMapInt(String key, Map<String, int> map) async {
    final str = map.entries.map((e) => '${e.key}:${e.value}').join(';');
    await _storage.setString(key, str);
  }

  Map<String, DateTime> _getMapDateTime(String key) {
    final str = _storage.getString(key);
    if (str == null || str.isEmpty) return {};
    try {
      final Map<String, DateTime> result = {};
      final parts = str.split(';');
      for (var p in parts) {
        final kv = p.split('|');
        if (kv.length == 2) {
          result[kv[0]] = DateTime.tryParse(kv[1]) ?? DateTime.now();
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveMapDateTime(String key, Map<String, DateTime> map) async {
    final str = map.entries
        .map((e) => '${e.key}|${e.value.toIso8601String()}')
        .join(';');
    await _storage.setString(key, str);
  }
}
