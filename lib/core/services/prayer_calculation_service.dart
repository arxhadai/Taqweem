import 'package:adhan/adhan.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart'
    as app_enums;

class PrayerCalculationService {
  Map<String, DateTime> calculateRawTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required app_enums.PrayerCalculationMethod method,
    required app_enums.Madhab madhab,
    required app_enums.Sect sect,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final params = _getCalculationParameters(method);

    // Set Madhab
    params.madhab = _mapMadhab(madhab);

    // Sect-specific angular adjustments are intentionally NOT applied here for Shia.
    // We compute the base (Sunni) times first and apply Shia post-adjust offsets below

    final dateComponents = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // Get sect-based offsets for Bahawalpur alignment
    final offsets = _getSectOffsets(sect);

    // Apply offsets AFTER calculation to adjust for local alignment
    DateTime finalFajr = _applyOffset(prayerTimes.fajr, offsets['fajr']!);
    DateTime finalMaghrib = _applyOffset(prayerTimes.maghrib, offsets['maghrib']!);

    // If sect is Shia, apply sect-specific post adjustments relative to the
    // Sunni final times: Sehri = SunniFinal - 10min, Iftar = SunniFinal + 10min
    if (sect == app_enums.Sect.shia) {
      finalFajr = finalFajr.subtract(const Duration(minutes: 10));
      finalMaghrib = finalMaghrib.add(const Duration(minutes: 10));
    }

    return {
      'Fajr': finalFajr,
      'Sunrise': prayerTimes.sunrise,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': finalMaghrib,
      'Isha': prayerTimes.isha,
    };
  }

  CalculationParameters _getCalculationParameters(
    app_enums.PrayerCalculationMethod method,
  ) {
    switch (method) {
      case app_enums.PrayerCalculationMethod.karachi:
        return CalculationMethod.karachi.getParameters();
      case app_enums.PrayerCalculationMethod.makkah:
        return CalculationMethod.umm_al_qura.getParameters();
      case app_enums.PrayerCalculationMethod.egypt:
        return CalculationMethod.egyptian.getParameters();
      case app_enums.PrayerCalculationMethod.isna:
        return CalculationMethod.north_america.getParameters();
      case app_enums.PrayerCalculationMethod.mwl:
        return CalculationMethod.muslim_world_league.getParameters();
      case app_enums.PrayerCalculationMethod.tehran:
        return CalculationMethod.tehran.getParameters();
      case app_enums.PrayerCalculationMethod.custom:
        return CalculationMethod.other.getParameters();
    }
  }

  Madhab _mapMadhab(app_enums.Madhab appMadhab) {
    switch (appMadhab) {
      case app_enums.Madhab.hanafi:
        return Madhab.hanafi;
      case app_enums.Madhab.shafi:
        return Madhab.shafi;
    }
  }

  /// Centralized sect-based offset configuration for Bahawalpur alignment.
  /// Returns offsets in minutes to apply AFTER calculation.
  /// 
  /// Rules:
  /// - Hanafi: Matches IUB mosque timing in Bahawalpur
  /// - Ahl-e-Hadis: Matches Hamariweb preventive timing
  /// - Shia: Keeps existing angular adjustments (already applied above)
  Map<String, int> _getSectOffsets(app_enums.Sect selectedSect) {
    switch (selectedSect) {
      case app_enums.Sect.sunni:
        // Assuming Hanafi by default for Sunni (most common in Bahawalpur)
        return {
          'fajr': -1,       // 1 minute earlier
          'maghrib': 6,     // 6 minutes later (IUB mosque timing)
        };
      case app_enums.Sect.ahleHadis:
        return {
          'fajr': -1,       // 1 minute earlier (preventive)
          'maghrib': 1,     // 1 minute later (Hamariweb alignment)
        };
      case app_enums.Sect.shia:
        // Shia already has angular adjustments applied above
        // No additional offset needed as angular logic handles it
        return {
          'fajr': 0,        // Angular adjustments already applied
          'maghrib': 0,     // Angular adjustments already applied
        };
    }
  }

  /// Applies an offset (in minutes) to a DateTime.
  /// Offsets must be applied ONCE, after initial calculation.
  DateTime _applyOffset(DateTime time, int minutes) {
    return time.add(Duration(minutes: minutes));
  }
}
