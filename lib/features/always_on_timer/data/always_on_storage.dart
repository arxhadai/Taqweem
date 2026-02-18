import 'package:hive_ce/hive.dart';
import 'package:ramzan_companion/features/always_on_timer/domain/models/always_on_timer_settings.dart';

class AlwaysOnStorage {
  static const String boxName = 'always_on_timer_settings';
  static const String settingsKey = 'settings';

  final Box<AlwaysOnTimerSettings> _box;

  AlwaysOnStorage(this._box);

  static Future<AlwaysOnStorage> init() async {
    final box = await Hive.openBox<AlwaysOnTimerSettings>(boxName);
    return AlwaysOnStorage(box);
  }

  AlwaysOnTimerSettings getSettings() {
    return _box.get(settingsKey, defaultValue: AlwaysOnTimerSettings())!;
  }

  Future<void> saveSettings(AlwaysOnTimerSettings settings) async {
    await _box.put(settingsKey, settings);
  }
}
