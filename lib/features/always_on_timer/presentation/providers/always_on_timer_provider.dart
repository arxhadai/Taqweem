import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/features/always_on_timer/data/always_on_storage.dart';
import 'package:ramzan_companion/features/always_on_timer/domain/models/always_on_timer_settings.dart';
import 'package:ramzan_companion/features/prayer_times/presentation/providers/prayer_times_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AlwaysOnTimerState {
  final AlwaysOnTimerSettings settings;
  final Duration remainingTime;
  final String nextEventName;
  final bool isVisible;

  AlwaysOnTimerState({
    required this.settings,
    required this.remainingTime,
    required this.nextEventName,
    required this.isVisible,
  });

  AlwaysOnTimerState copyWith({
    AlwaysOnTimerSettings? settings,
    Duration? remainingTime,
    String? nextEventName,
    bool? isVisible,
  }) {
    return AlwaysOnTimerState(
      settings: settings ?? this.settings,
      remainingTime: remainingTime ?? this.remainingTime,
      nextEventName: nextEventName ?? this.nextEventName,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

final alwaysOnStorageProvider = Provider<AlwaysOnStorage>((ref) {
  throw UnimplementedError('alwaysOnStorageProvider must be overridden');
});

final alwaysOnTimerProvider =
    NotifierProvider<AlwaysOnTimerNotifier, AlwaysOnTimerState>(
      AlwaysOnTimerNotifier.new,
    );

class AlwaysOnTimerNotifier extends Notifier<AlwaysOnTimerState> {
  Timer? _ticker;

  @override
  AlwaysOnTimerState build() {
    final storage = ref.watch(alwaysOnStorageProvider);

    ref.onDispose(() {
      _ticker?.cancel();
      WakelockPlus.disable();
    });

    _startTicker();

    return AlwaysOnTimerState(
      settings: storage.getSettings(),
      remainingTime: Duration.zero,
      nextEventName: '',
      isVisible: false,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final isVisible = _checkVisibility(now);

    if (!isVisible) {
      if (state.isVisible) {
        state = state.copyWith(isVisible: false);
      }
      return;
    }

    final nextEvent = _calculateNextEvent(now);
    if (nextEvent != null) {
      state = state.copyWith(
        isVisible: true,
        remainingTime: nextEvent.time.difference(now),
        nextEventName: nextEvent.name,
      );
    } else {
      if (state.isVisible) {
        state = state.copyWith(isVisible: false);
      }
    }

    _updateWakelock();
  }

  bool _checkVisibility(DateTime now) {
    if (!state.settings.isEnabled) return false;
    if (state.settings.displayMode == DisplayMode.always) return true;

    // Scheduled logic
    final startParts = state.settings.startTime.split(':');
    final endParts = state.settings.endTime.split(':');

    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (endTime.isBefore(startTime)) {
      return now.isAfter(startTime) || now.isBefore(endTime);
    }
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  _Event? _calculateNextEvent(DateTime now) {
    if (state.settings.timerMode == TimerMode.custom &&
        state.settings.customTargetTime != null) {
      final parts = state.settings.customTargetTime!.split(':');
      var target = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      return _Event('Custom', target);
    }

    final prayerTimesAsync = ref.read(currentPrayerTimesProvider);
    final prayerTimes = prayerTimesAsync.value;
    if (prayerTimes == null) return null;

    switch (state.settings.timerMode) {
      case TimerMode.iftar:
        return _Event('Iftar', prayerTimes['Maghrib']!.finalTime);
      case TimerMode.sehri:
        return _Event('Sehri', prayerTimes['Fajr']!.finalTime);
      case TimerMode.prayer:
        final sortedTimes = prayerTimes.entries
            .where((e) => e.key != 'Sunrise')
            .toList();
        sortedTimes.sort(
          (a, b) => a.value.finalTime.compareTo(b.value.finalTime),
        );

        for (var entry in sortedTimes) {
          if (entry.value.finalTime.isAfter(now)) {
            return _Event(entry.key, entry.value.finalTime);
          }
        }
        return null;
      case TimerMode.auto:
        final fajr = prayerTimes['Fajr']!.finalTime;
        final maghrib = prayerTimes['Maghrib']!.finalTime;
        if (now.isBefore(fajr)) {
          return _Event('Sehri', fajr);
        } else if (now.isBefore(maghrib)) {
          return _Event('Iftar', maghrib);
        } else {
          return null;
        }
      case TimerMode.custom:
        return null;
    }
  }

  Future<void> updateSettings(AlwaysOnTimerSettings settings) async {
    state = state.copyWith(settings: settings);
    final storage = ref.read(alwaysOnStorageProvider);
    await storage.saveSettings(settings);
    _tick(); // Force update
  }

  void _updateWakelock() {
    if (state.isVisible && state.settings.keepScreenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void toggleEnabled(bool value) {
    updateSettings(state.settings.copyWith(isEnabled: value));
  }
}

class _Event {
  final String name;
  final DateTime time;
  _Event(this.name, this.time);
}
