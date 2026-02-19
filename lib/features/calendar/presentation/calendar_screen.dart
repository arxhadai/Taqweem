import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/shared/presentation/providers/time_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) {
      return;
    }
    final today = DateTime.now();
    final yearStart = DateTime(today.year, 1, 1);
    final dayOfYear = today.difference(yearStart).inDays;
    // Try to center the selected day in the viewport
    final double itemHeight = 80.0; // approximate item extent (including margin)
    final double viewport = _scrollController.position.viewportDimension;
    final double rawOffset = dayOfYear * itemHeight;
    final double centeredOffset = rawOffset - (viewport / 2) + (itemHeight / 2);
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double target = centeredOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

          // Generate list for full year (365 days)
          final yearStart = DateTime(now.year, 1, 1);
          return ListView.builder(
            controller: _scrollController,
            itemCount: 365,
            itemBuilder: (context, index) {
              final date = yearStart.add(Duration(days: index));
              final adjustedDate = date.add(Duration(days: settings.hijriOffset));
              final hijriDate = HijriCalendar.fromDate(adjustedDate);

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
