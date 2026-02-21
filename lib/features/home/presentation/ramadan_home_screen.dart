import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/features/home/presentation/providers/ramadan_provider.dart';
import 'package:ramzan_companion/features/home/presentation/providers/dua_overlay_provider.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/shared/presentation/providers/time_provider.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/screens/always_on_timer_screen.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_state.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/widgets/ramadan_dua_overlay.dart';
import 'package:ramzan_companion/data/duas.dart';

class RamadanHomeScreen extends ConsumerWidget {
  const RamadanHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
    final prayerTimesAsync = ref.watch(currentPrayerTimesProvider);
    final ramadan = ref.watch(ramadanProvider);
    final settings = ref.watch(settingsProvider);
    final duaOverlayState = ref.watch(duaOverlayProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Ramzan Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Always-On Timer',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlwaysOnTimerScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          prayerTimesAsync.when(
            data: (prayerTimes) {
              if (prayerTimes == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Unable to get location.'),
                    ],
                  ),
                );
              }

              // Determine next prayer
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

              // Countdown logic: During Ramadan
              // 1. Before Fajr: Show countdown to Fajr (Sehri ends at Fajr)
              // 2. After Fajr, before Maghrib: Show countdown to Maghrib (Iftar)
              // 3. After Maghrib: Show countdown to tomorrow's Fajr (Sehri starts)
              final DateTime? fajrTime = prayerTimes['Fajr']?.finalTime;
              final DateTime? maghribTime = prayerTimes['Maghrib']?.finalTime;

              String countdownLabel;
              DateTime countdownTarget;
              String countdownPrayerName;
              String countdownPrayerTime;
              bool showFiqaInCountdown = false;

              // Check if we're before Fajr (Sehri time) or after Fajr (Iftar/next Sehri time)
              if (fajrTime != null && now.isBefore(fajrTime)) {
                // Before Fajr: countdown to Fajr (when Sehri ends)
                countdownLabel = 'Time until Sehri Ends';
                countdownTarget = fajrTime;
                countdownPrayerName = 'Fajr';
                countdownPrayerTime = DateFormat.jm().format(fajrTime);
                showFiqaInCountdown = true;
                
                // Check if we should show Sehri dua overlay
                // Show dua if we're within 5 minutes before Sehri starts and not recently dismissed
                if (fajrTime.subtract(const Duration(minutes: 5)).isBefore(now) && now.isBefore(fajrTime)) {
                  if (ref.read(duaOverlayProvider.notifier).canShowOverlay(DuaOverlayState.sehriActive)) {
                    Future.microtask(() {
                      ref.read(duaOverlayProvider.notifier).setActive(DuaOverlayState.sehriActive);
                    });
                  }
                }
              } else if (maghribTime != null && now.isBefore(maghribTime)) {
                // After Fajr, before Maghrib: countdown to Maghrib (Iftar)
                countdownLabel = 'Time until Iftar';
                countdownTarget = maghribTime;
                countdownPrayerName = 'Maghrib';
                countdownPrayerTime = DateFormat.jm().format(maghribTime);
                showFiqaInCountdown = false;
                
                // Check if we should show Iftar dua overlay
                // Show dua if we're within 5 minutes before Iftar and not recently dismissed
                if (maghribTime.subtract(const Duration(minutes: 5)).isBefore(now) && now.isBefore(maghribTime)) {
                  if (ref.read(duaOverlayProvider.notifier).canShowOverlay(DuaOverlayState.iftarActive)) {
                    Future.microtask(() {
                      ref.read(duaOverlayProvider.notifier).setActive(DuaOverlayState.iftarActive);
                    });
                  }
                }
              } else {
                // After Maghrib: countdown to tomorrow's Fajr (when Sehri starts)
                countdownLabel = 'Time until Sehri Starts';
                final fajrTomorrow = fajrTime != null
                    ? fajrTime.add(const Duration(days: 1))
                    : now.add(const Duration(hours: 24));
                countdownTarget = fajrTomorrow;
                countdownPrayerName = 'Fajr';
                countdownPrayerTime = fajrTime != null
                    ? DateFormat.jm().format(fajrTime)
                    : 'Unknown';
                showFiqaInCountdown = true;
              }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Date Card
                _DateCard(
                  now: now,
                  ramadan: ramadan,
                  settings: settings,
                  cityProvider: ref.watch(currentCityProvider),
                ),

                const SizedBox(height: 16),

                // 2. Countdown Card
                _CountdownCard(
                  label: countdownLabel,
                  targetTime: countdownTarget,
                  prayerName: countdownPrayerName,
                  prayerTime: countdownPrayerTime,
                  fiqaLabel: settings.sect.getFiqaLabel(settings.madhab),
                  showFiqa: showFiqaInCountdown,
                ),

                const SizedBox(height: 16),

                // 3. Ramadan Status Card
                _RamadanStatusCard(ramadan: ramadan),

                const SizedBox(height: 16),

                // 4. Next Prayer Mini Card
                if (nextPrayerModel != null)
                  _NextPrayerCard(
                    prayerName: nextPrayerName,
                    prayerTime: nextPrayerModel.finalTime,
                    now: now,
                  ),
              ],
            ),
          );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading prayer times.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Dua Overlay - layered on top
          if (duaOverlayState == DuaOverlayState.sehriActive)
            RamadanDuaOverlay(
              dua: Duas.sehri,
              hijriDate: ramadan.hijriDateString,
              currentTime: DateFormat.jm().format(now),
              currentRoza: ramadan.ramadanDay,
              totalRoza: ramadan.totalDays,
              onDismiss: () {
                ref.read(duaOverlayProvider.notifier).dismiss();
              },
            ),
          if (duaOverlayState == DuaOverlayState.iftarActive)
            RamadanDuaOverlay(
              dua: Duas.iftar,
              hijriDate: ramadan.hijriDateString,
              currentTime: DateFormat.jm().format(now),
              currentRoza: ramadan.ramadanDay,
              totalRoza: ramadan.totalDays,
              onDismiss: () {
                ref.read(duaOverlayProvider.notifier).dismiss();
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Home - already here
              break;
            case 1:
              // Calendar
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Placeholder(), // Replace with CalendarScreen
                ),
              );
              break;
            case 2:
              // Qibla direction
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Placeholder(), // Replace with QiblaScreen
                ),
              );
              break;
            case 3:
              // Settings
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Placeholder(), // Replace with SettingsScreen
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compass_calibration),
            label: 'Qibla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─── DATE CARD ──────────────────────────────────────────────────────────────

class _DateCard extends StatelessWidget {
  final DateTime now;
  final RamadanState ramadan;
  final SettingsState settings;
  final AsyncValue<String?> cityProvider;

  const _DateCard({
    required this.now,
    required this.ramadan,
    required this.settings,
    required this.cityProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(now),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ramadan.hijriDateString,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                const SizedBox(width: 4),
                cityProvider.when(
                  data: (city) => Text(
                    city ?? 'Location not found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => const Text('Error'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  settings.sect.getFiqaLabel(settings.madhab).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COUNTDOWN CARD ─────────────────────────────────────────────────────────

class _CountdownCard extends StatefulWidget {
  final String label;
  final DateTime targetTime;
  final String prayerName;
  final String prayerTime;
  final String fiqaLabel;
  final bool showFiqa;

  const _CountdownCard({
    required this.label,
    required this.targetTime,
    required this.prayerName,
    required this.prayerTime,
    this.fiqaLabel = '',
    this.showFiqa = false,
  });

  @override
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeLeft();
    });
  }

  @override
  void didUpdateWidget(covariant _CountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTime != widget.targetTime) {
      _calculateTimeLeft();
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.targetTime.isAfter(now)) {
      setState(() {
        _timeLeft = widget.targetTime.difference(now);
      });
    } else {
      setState(() {
        _timeLeft = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A7B6E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${hours.toString().padLeft(2, '0')} : ${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D5A52),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mosque_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.prayerName,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.prayerTime,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.jm().format(DateTime.now()),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RAMADAN STATUS CARD ────────────────────────────────────────────────────

class _RamadanStatusCard extends StatelessWidget {
  final RamadanState ramadan;

  const _RamadanStatusCard({required this.ramadan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ashra of ${ramadan.ashra}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Day ${ramadan.ramadanDay}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' of ${ramadan.totalDays}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SegmentedProgressBar(
              progress: ramadan.progress,
              ramadanDay: ramadan.ramadanDay,
              totalDays: ramadan.totalDays,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'COMPLETED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${ramadan.fastsCompleted}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'REMAINING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${ramadan.remaining}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NEXT PRAYER MINI CARD ──────────────────────────────────────────────────

class _NextPrayerCard extends StatelessWidget {
  final String prayerName;
  final DateTime prayerTime;
  final DateTime now;

  const _NextPrayerCard({
    required this.prayerName,
    required this.prayerTime,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final diff = prayerTime.difference(now);
    final relativeText = diff.inMinutes > 0
        ? 'In ${diff.inMinutes} mins'
        : 'Now';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getPrayerIcon(prayerName),
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT PRAYER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  prayerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat.jm().format(prayerTime),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  relativeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String name) {
    switch (name) {
      case 'Fajr':
        return Icons.nightlight_round;
      case 'Dhuhr':
        return Icons.wb_sunny;
      case 'Asr':
        return Icons.wb_sunny_outlined;
      case 'Maghrib':
        return Icons.wb_twilight;
      case 'Isha':
        return Icons.nightlight;
      default:
        return Icons.access_time;
    }
  }
}

// ─── SEGMENTED PROGRESS BAR ────────────────────────────────────────────────

class _SegmentedProgressBar extends StatelessWidget {
  final double progress;
  final int ramadanDay;
  final int totalDays;

  const _SegmentedProgressBar({
    required this.progress,
    required this.ramadanDay,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define three shades of green for the three ashras
    const Color ashra1Color = Color(0xFF4CAF50); // Light Green
    const Color ashra2Color = Color(0xFF2E7D32); // Medium Green
    const Color ashra3Color = Color(0xFF1B5E20); // Dark Green

    const double segmentHeight = 12;
    const double borderRadius = 8;

    // Calculate progress for each segment (30 days, 10 per ashra)
    final double seg1Full = 10 / totalDays;
    final double seg2Full = 10 / totalDays;
    final double seg3Full = 10 / totalDays;

    double seg1Progress = progress.clamp(0, seg1Full);
    double seg2Progress =
        progress > seg1Full ? (progress - seg1Full).clamp(0, seg2Full) : 0;
    double seg3Progress =
        progress > (seg1Full + seg2Full)
            ? (progress - seg1Full - seg2Full).clamp(0, seg3Full)
            : 0;

    if (seg1Full > 0) seg1Progress = seg1Progress / seg1Full;
    if (seg2Full > 0) seg2Progress = seg2Progress / seg2Full;
    if (seg3Full > 0) seg3Progress = seg3Progress / seg3Full;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: segmentHeight,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    bottomLeft: Radius.circular(borderRadius),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    bottomLeft: Radius.circular(borderRadius),
                  ),
                  child: LinearProgressIndicator(
                    value: seg1Progress,
                    minHeight: segmentHeight,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(ashra1Color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Container(
                height: segmentHeight,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: LinearProgressIndicator(
                  value: seg2Progress,
                  minHeight: segmentHeight,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(ashra2Color),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Container(
                height: segmentHeight,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  child: LinearProgressIndicator(
                    value: seg3Progress,
                    minHeight: segmentHeight,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(ashra3Color),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 0),
      ],
    );
  }
}
