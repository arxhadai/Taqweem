import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/shared/presentation/providers/time_provider.dart';

class RamadanState {
  final bool isRamadan;
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;
  final String hijriMonthName;
  final int ramadanDay;
  final int totalDays;
  final int fastsCompleted;
  final int remaining;
  final String ashra;
  final double progress;

  const RamadanState({
    required this.isRamadan,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.hijriMonthName,
    required this.ramadanDay,
    required this.totalDays,
    required this.fastsCompleted,
    required this.remaining,
    required this.ashra,
    required this.progress,
  });

  String get hijriDateString => '$hijriDay $hijriMonthName $hijriYear AH';
}

final ramadanProvider = Provider<RamadanState>((ref) {
  final settings = ref.watch(settingsProvider);
  final date = ref.watch(currentDateProvider);
  final offset = settings.hijriOffset;

  // Apply offset to the date before converting to Hijri
  final adjustedDate = date.add(Duration(days: offset));
  final hijri = HijriCalendar.fromDate(adjustedDate);

  final isRamadan = hijri.hMonth == 9;
  final totalDays = 30; // Assume 30 unless last day detected
  final ramadanDay = isRamadan ? hijri.hDay : 0;
  final fastsCompleted = isRamadan ? (ramadanDay - 1).clamp(0, totalDays) : 0;
  final remaining = isRamadan ? totalDays - fastsCompleted : 0;
  final progress = totalDays > 0 ? fastsCompleted / totalDays : 0.0;

  String ashra;
  if (ramadanDay <= 10) {
    ashra = 'Rahmat';
  } else if (ramadanDay <= 20) {
    ashra = 'Maghfirat';
  } else {
    ashra = 'Nijat';
  }

  return RamadanState(
    isRamadan: isRamadan,
    hijriDay: hijri.hDay,
    hijriMonth: hijri.hMonth,
    hijriYear: hijri.hYear,
    hijriMonthName: hijri.longMonthName,
    ramadanDay: ramadanDay,
    totalDays: totalDays,
    fastsCompleted: fastsCompleted,
    remaining: remaining,
    ashra: ashra,
    progress: progress,
  );
});
