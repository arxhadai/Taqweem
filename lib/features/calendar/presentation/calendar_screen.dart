import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/shared/presentation/providers/time_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentDateProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final settings = ref.watch(settingsProvider);
    final engine = ref.watch(prayerEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ramadan Timetable'),
            Text(
              settings.sect.getFiqaLabel(settings.madhab),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: locationAsync.when(
        data: (location) {
          if (location == null) {
            return const Center(child: Text('Location not available'));
          }

          // Generate list for next 30 days
          return ListView.builder(
            itemCount: 30,
            itemBuilder: (context, index) {
              final date = now.add(Duration(days: index));
              final hijriDate = HijriCalendar.fromDate(date);

              final prayerTimes = engine.getFinalPrayerTimes(
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

              final isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;

              return Card(
                elevation: isToday ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isToday
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                color: isToday
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : null,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM').format(date),
                            style: TextStyle(
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            '${hijriDate.hDay} ${hijriDate.longMonthName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Sehri: ${DateFormat.jm().format(prayerTimes['Fajr']?.finalTime ?? now)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Iftar: ${DateFormat.jm().format(prayerTimes['Maghrib']?.finalTime ?? now)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
