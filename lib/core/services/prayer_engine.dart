import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/core/services/prayer_calculation_service.dart';
import 'package:ramzan_companion/core/services/mosque_adjustment_service.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart'
    as app_enums;

class PrayerEngine {
  final PrayerCalculationService _calculationService;
  final MosqueAdjustmentService _adjustmentService;

  PrayerEngine({
    PrayerCalculationService? calculationService,
    MosqueAdjustmentService? adjustmentService,
  }) : _calculationService = calculationService ?? PrayerCalculationService(),
       _adjustmentService = adjustmentService ?? MosqueAdjustmentService();

  Map<String, PrayerTimeModel> getFinalPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required app_enums.PrayerCalculationMethod method,
    required app_enums.Madhab madhab,
    required app_enums.Sect sect,
    required TimingMode timingMode,
    required Map<String, int> offsets,
    required Map<String, DateTime>? manualTimes,
  }) {
    // Step 1: Calculate raw times
    final rawTimes = _calculationService.calculateRawTimes(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: method,
      madhab: madhab,
      sect: sect,
    );

    // Steps 2-5: Apply adjustments and return models
    return _adjustmentService.adjustTimes(
      calculatedTimes: rawTimes,
      mode: timingMode,
      offsets: offsets,
      manualTimes: manualTimes,
    );
  }
}
