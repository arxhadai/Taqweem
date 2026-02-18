import 'package:flutter_test/flutter_test.dart';
import 'package:ramzan_companion/features/prayer_times/data/prayer_time_service.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';

void main() {
  group('PrayerTimeService Tests', () {
    final service = PrayerTimeService();
    // Coordinates for Karachi, Pakistan
    const double karachiLat = 24.8607;
    const double karachiLng = 67.0011;
    final date = DateTime(2024, 3, 12); // 1st Ramadan 1445 approx

    test('Sunni Hanafi Calculation (Karachi)', () {
      final times = service.getPrayerTimes(
        latitude: karachiLat,
        longitude: karachiLng,
        date: date,
        method: PrayerCalculationMethod.karachi,
        madhab: Madhab.hanafi,
        sect: Sect.sunni,
      );

      expect(times.fajr, isNotNull);
      expect(times.maghrib, isNotNull);

      // Basic logic check
      expect(times.fajr.isBefore(times.sunrise), true);
      expect(times.sunrise.isBefore(times.dhuhr), true);
      expect(times.dhuhr.isBefore(times.asr), true);
      expect(times.asr.isBefore(times.maghrib), true);
      expect(times.maghrib.isBefore(times.isha), true);
    });

    test('Shia vs Sunni Difference (Same Method)', () {
      // Calculate Sunni times first
      final sunniTimes = service.getPrayerTimes(
        latitude: karachiLat,
        longitude: karachiLng,
        date: date,
        method: PrayerCalculationMethod.karachi,
        madhab: Madhab.hanafi,
        sect: Sect.sunni,
      );

      // Calculate Shia times with SAME base method
      // Our logic should force Jafari angles regardless of base method if sect is Shia
      final shiaTimes = service.getPrayerTimes(
        latitude: karachiLat,
        longitude: karachiLng,
        date: date,
        method: PrayerCalculationMethod.karachi,
        madhab: Madhab.hanafi,
        sect: Sect.shia,
      );

      // Verify Fajr is different
      // Sunni Karachi Fajr Angle: 18.0
      // Shia Override Fajr Angle: 16.0
      // Lower angle means sun is closer to horizon -> Later time (closer to sunrise)
      expect(
        shiaTimes.fajr.isAfter(sunniTimes.fajr),
        true,
        reason: 'Shia Fajr should be later than Sunni Fajr (16 deg vs 18 deg)',
      );

      // Verify Maghrib is different
      // Sunni Karachi Maghrib: Sunset + minutes adjustment usually
      // Shia Override Maghrib Angle: 4.0 degrees below horizon
      // 4 degrees below horizon is definitely later than sunset/immediate maghrib
      expect(
        shiaTimes.maghrib.isAfter(sunniTimes.maghrib),
        true,
        reason:
            'Shia Maghrib should be later than Sunni Maghrib (4 deg vs Sunset)',
      );
    });
  });
}
