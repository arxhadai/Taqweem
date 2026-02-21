import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ramzan_companion/core/services/prayer_engine.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/notifications/data/alarm_scheduler_service.dart';
import 'package:ramzan_companion/features/notifications/presentation/notification_scheduler.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/features/notifications/data/alarm_sound_manager.dart';
import 'package:ramzan_companion/core/providers/storage_provider.dart';

final prayerEngineServiceProvider = Provider((ref) => PrayerEngineService(ref));

class PrayerEngineService {
  final Ref _ref;
  final PrayerEngine _engine = PrayerEngine();
  Position? _lastPosition;

  PrayerEngineService(this._ref);

  Future<void> refreshPrayerTimes() async {
    debugPrint('PrayerEngineService: Refreshing prayer times...');

    final settings = _ref.read(settingsProvider);
    final locationAsync = _ref.read(currentLocationProvider);
    final position = locationAsync.value;

    if (position == null) {
      debugPrint('PrayerEngineService: Cannot refresh, location is null');
      return;
    }

    // Step 7: Location Change Detection (> 50km)
    if (_lastPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance < 50000) {
        // Less than 50km, skip mandatory recalculation unless it's a new day
        // But the requirement says "IF user moves > 50km ... Recalculate immediately"
        // It doesn't say NOT to recalculate if less.
        // Usually we want to recalculate for precision anyway if it's a refresh.
      }
    }
    _lastPosition = position;

    final soundManager = AlarmSoundManager(_ref.read(storageServiceProvider));
    final alarmScheduler = AlarmSchedulerService(
      _ref.read(notificationServiceProvider),
      soundManager,
    );

    // Step 5: Recalculate for next 10 days
    final now = DateTime.now();
    for (int i = 0; i < 10; i++) {
      final date = now.add(Duration(days: i));

      final finalTimes = _engine.getFinalPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        date: date,
        method: settings.calculationMethod,
        madhab: settings.madhab,
        sect: settings.sect,
        timingMode: settings.timingMode,
        offsets: settings.offsets,
        manualTimes: settings.manualTimes,
      );

      // Save/Cache if needed (usually we just schedule alarms)
      // Requirement Step 6: Alarm Integration
      await alarmScheduler.scheduleAll(
        finalPrayerTimes: finalTimes,
        settings: settings,
        dayOffset: i,
      );
    }

    debugPrint('PrayerEngineService: Refresh complete and alarms rescheduled.');
  }

  // To be called from location listener
  void onLocationChanged(Position pos) {
    if (_lastPosition == null) {
      _lastPosition = pos;
      refreshPrayerTimes();
      return;
    }

    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );

    if (distance > 50000) {
      debugPrint('PrayerEngineService: User moved > 50km, triggering refresh');
      refreshPrayerTimes();
    }
  }
}
