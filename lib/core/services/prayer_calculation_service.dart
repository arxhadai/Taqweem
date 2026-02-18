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

    // Sect specific adjustments (as in original code)
    if (sect == app_enums.Sect.shia) {
      params.fajrAngle = 16.0;
      params.maghribAngle = 4.0;
      params.ishaAngle = 14.0;
      params.adjustments.fajr = -10;
    }

    final dateComponents = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    return {
      'Fajr': prayerTimes.fajr,
      'Sunrise': prayerTimes.sunrise,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
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
}
