import 'package:ramzan_companion/core/models/prayer_timing_models.dart';

class MosqueAdjustmentService {
  Map<String, PrayerTimeModel> adjustTimes({
    required Map<String, DateTime> calculatedTimes,
    required TimingMode mode,
    required Map<String, int> offsets,
    required Map<String, DateTime>? manualTimes,
  }) {
    final Map<String, PrayerTimeModel> adjusted = {};

    calculatedTimes.forEach((prayerName, calculatedTime) {
      DateTime finalTime = calculatedTime;
      int offset = 0;

      // Rule 4: Sunrise is always calculated and ignores manual overrides
      if (prayerName == 'Sunrise') {
        adjusted[prayerName] = PrayerTimeModel(
          calculated: calculatedTime,
          offsetMinutes: 0,
          finalTime: calculatedTime,
          prayerName: prayerName,
        );
        return;
      }

      switch (mode) {
        case TimingMode.calculation:
          finalTime = calculatedTime;
          break;
        case TimingMode.calculationWithOffset:
          offset = offsets[prayerName] ?? 0;
          // Validate offset bounds: Min -60, Max +60
          if (offset < -60) offset = -60;
          if (offset > 60) offset = 60;
          finalTime = calculatedTime.add(Duration(minutes: offset));
          break;
        case TimingMode.mosqueManual:
          if (manualTimes != null && manualTimes.containsKey(prayerName)) {
            finalTime = manualTimes[prayerName]!;
          } else {
            finalTime = calculatedTime; // Fallback to calculation
          }
          break;
      }

      adjusted[prayerName] = PrayerTimeModel(
        calculated: calculatedTime,
        offsetMinutes: offset,
        finalTime: finalTime,
        prayerName: prayerName,
      );
    });

    return adjusted;
  }
}
