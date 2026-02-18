import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ramzan_companion/features/always_on_timer/domain/models/always_on_timer_settings.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/providers/always_on_timer_provider.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/widgets/timer_styles.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';

class AlwaysOnTimerScreen extends ConsumerWidget {
  const AlwaysOnTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(alwaysOnTimerProvider);
    final settings = ref.watch(settingsProvider);
    final prayerTimesAsync = ref.watch(currentPrayerTimesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              // Top Clock (Minimalist)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    DateFormat.jm().format(DateTime.now()),
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timerState.isVisible) ...[
                      TimerStyleDisplay(
                        duration: timerState.remainingTime,
                        label: timerState.nextEventName,
                        useBold: timerState.settings.style == TimerStyle.bold,
                        useDigital:
                            timerState.settings.style == TimerStyle.digital,
                        useAnalog:
                            timerState.settings.style ==
                            TimerStyle.analogInspired,
                      ),
                    ] else
                      const Text(
                        'No active countdown',
                        style: TextStyle(color: Colors.white24),
                      ),
                  ],
                ),
              ),
              // Bottom Info: Sehri/Iftar Times + Fiqa Label
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    prayerTimesAsync.when(
                      data: (times) => times != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildInfoColumn(
                                    'SEHRI',
                                    DateFormat.jm().format(
                                      times['Fajr']?.finalTime ??
                                          DateTime.now(),
                                    ),
                                  ),
                                  _buildInfoColumn(
                                    'IFTAR',
                                    DateFormat.jm().format(
                                      times['Maghrib']?.finalTime ??
                                          DateTime.now(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      settings.sect.getFiqaLabel(settings.madhab),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ref
                        .watch(currentCityProvider)
                        .when(
                          data: (city) => Text(
                            city ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
