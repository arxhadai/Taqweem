import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/core/services/prayer_engine.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/shared/presentation/providers/time_provider.dart';

final prayerEngineProvider = Provider((ref) => PrayerEngine());

final currentPrayerTimesProvider =
    FutureProvider<Map<String, PrayerTimeModel>?>((ref) async {
      final locationAsyncValue = ref.watch(currentLocationProvider);
      final location = locationAsyncValue.value;

      if (location == null) return null;

      final settings = ref.watch(settingsProvider);
      final engine = ref.watch(prayerEngineProvider);

      // Watch currentDateProvider to re-calculate if the system date changes
      final date = ref.watch(currentDateProvider);

      return engine.getFinalPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        date: date,
        method: settings.calculationMethod,
        madhab: settings.madhab,
        sect: settings.sect,
        timingMode: settings.timingMode,
        offsets: settings.offsets,
        manualTimes: settings.manualTimes,
      );
    });
