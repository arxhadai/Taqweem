import 'dart:convert';

import 'package:ramzan_companion/core/data/storage_service.dart';
import 'package:ramzan_companion/features/notifications/domain/alarm_event_type.dart';

class AlarmSoundManager {
  static const _storageKey = 'alarm_sounds';
  final StorageService _storage;

  AlarmSoundManager(this._storage);

  Map<String, String> _cache = {};

  Map<String, String> _loadMap() {
    final raw = _storage.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveMap(Map<String, String> map) async {
    _cache = Map.from(map);
    await _storage.setString(_storageKey, json.encode(map));
  }

  String getSoundForEvent(AlarmEventType type) {
    if (_cache.isEmpty) {
      _cache = _loadMap();
    }

    // Migration: legacy single alarm sound (key: alarm_sound)
    if (_cache.isEmpty) {
      final legacy = _storage.getString('alarm_sound');
      if (legacy != null && legacy.isNotEmpty) {
        final Map<String, String> migrated = {};
        for (final e in AlarmEventType.values) {
          migrated[e.name] = legacy;
        }
        _saveMap(migrated);
      // Normalize: 'adhan' or 'default' -> 'standard' (actual resource name)
      return (legacy == 'default' || legacy == 'adhan') ? 'standard' : legacy;
      }
    }

    final val = _cache[type.name];
    if (val == null || val.isEmpty || val == 'default') return 'standard';
    return val;
  }

  Future<void> setSoundForEvent(AlarmEventType type, String soundName) async {
    if (_cache.isEmpty) _cache = _loadMap();
    _cache[type.name] = soundName;
    await _saveMap(_cache);
  }
}
