import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/shared/presentation/providers/time_provider.dart';
import 'widgets/countdown_widget.dart';
import 'widgets/prayer_card.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/screens/always_on_timer_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
    final prayerTimesAsync = ref.watch(currentPrayerTimesProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ramzan Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Always-On Timer',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlwaysOnTimerScreen()),
              );
            },
          ),
        ],
      ),
      body: prayerTimesAsync.when(
        data: (prayerTimes) {
          if (prayerTimes == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Unable to get location.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      // ignore: unused_result
                      ref.refresh(currentPrayerTimesProvider);
                    },
                    child: const Text('Retry Location'),
                  ),
                ],
              ),
            );
          }

          // In the new system, prayerTimes is a Map<String, PrayerTimeModel>
          // Find next prayer logic
          final sortedTimes = prayerTimes.entries
              .where((e) => e.key != 'Sunrise')
              .toList();
          sortedTimes.sort(
            (a, b) => a.value.finalTime.compareTo(b.value.finalTime),
          );

          PrayerTimeModel? nextPrayerModel;
          String nextPrayerName = '';

          for (var entry in sortedTimes) {
            if (entry.value.finalTime.isAfter(now)) {
              nextPrayerModel = entry.value;
              nextPrayerName = entry.key;
              break;
            }
          }

          final adjustedDate = now.add(Duration(days: settings.hijriOffset));
          final hijriDate = HijriCalendar.fromDate(adjustedDate);
          final hijriString =
              '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}';

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(now),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hijriString,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.jm().format(now),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ref
                        .watch(currentCityProvider)
                        .when(
                          data: (city) => Text(
                            city ?? 'Location not found',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, _) => const Center(
                            child: Text('Error loading location'),
                          ),
                        ),
                    const SizedBox(height: 8),
                    Text(
                      settings.sect.getFiqaLabel(settings.madhab),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Countdown
              if (nextPrayerModel != null) ...[
                CountdownWidget(
                  targetTime: nextPrayerModel.finalTime,
                  label: nextPrayerName,
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Text("No more prayers for today"),
                const SizedBox(height: 24),
              ],

              // Prayer Times List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildPrayerCard(
                      context,
                      'Fajr (Sehri Ends)',
                      prayerTimes['Fajr']?.finalTime ?? now,
                      nextPrayerName == 'Fajr',
                    ),
                    _buildPrayerCard(
                      context,
                      'Sunrise',
                      prayerTimes['Sunrise']?.finalTime ?? now,
                      false,
                    ),
                    _buildPrayerCard(
                      context,
                      'Dhuhr',
                      prayerTimes['Dhuhr']?.finalTime ?? now,
                      nextPrayerName == 'Dhuhr',
                    ),
                    _buildPrayerCard(
                      context,
                      'Asr',
                      prayerTimes['Asr']?.finalTime ?? now,
                      nextPrayerName == 'Asr',
                    ),
                    _buildPrayerCard(
                      context,
                      'Maghrib (Iftar)',
                      prayerTimes['Maghrib']?.finalTime ?? now,
                      nextPrayerName == 'Maghrib',
                    ),
                    _buildPrayerCard(
                      context,
                      'Isha',
                      prayerTimes['Isha']?.finalTime ?? now,
                      nextPrayerName == 'Isha',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'Error loading prayer times.\nPlease ensure location is enabled.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    // ignore: unused_result
                    ref.refresh(currentPrayerTimesProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(
    BuildContext context,
    String name,
    DateTime time,
    bool isNext,
  ) {
    final now = DateTime.now();
    final isPast = time.isBefore(now);

    return PrayerCard(
      name: name,
      time: DateFormat.jm().format(time),
      isNext: isNext,
      isPast: isPast && !isNext,
    );
  }
}
