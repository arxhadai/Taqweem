import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/core/services/prayer_engine_service.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/notifications/data/notification_service.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref);
});

class NotificationScheduler {
  final Ref ref;
  Timer? _debounceTimer;
  bool _isScheduling = false;

  NotificationScheduler(this.ref) {
    _init();
  }

  void _init() {
    debugPrint('NotificationScheduler: Initializing...');

    // Listen to changes in settings (e.g., sound, offset, timing mode)
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.alarmSound != next.alarmSound ||
          previous?.isNotificationsEnabled != next.isNotificationsEnabled ||
          previous?.calculationMethod != next.calculationMethod ||
          previous?.timingMode != next.timingMode ||
          previous?.offsets != next.offsets ||
          previous?.manualTimes != next.manualTimes) {
        debugPrint(
          'NotificationScheduler: Settings/Timing changed, rescheduling...',
        );
        scheduleNotifications();
      }
    });

    // Listen to location changes
    ref.listen(currentLocationProvider, (previous, next) {
      next.whenData((pos) {
        if (pos != null) {
          // Let PrayerEngineService handle > 50km logic
          ref.read(prayerEngineServiceProvider).onLocationChanged(pos);
        }
      });
    });

    // Handle the initial state
    _checkAndScheduleInitial();
  }

  void _checkAndScheduleInitial() async {
    final locationAsync = ref.read(currentLocationProvider);
    if (locationAsync.hasValue && locationAsync.value != null) {
      scheduleNotifications();
    }
  }

  void scheduleNotifications() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_isScheduling) {
        scheduleNotifications();
        return;
      }
      _isScheduling = true;
      try {
        await ref.read(prayerEngineServiceProvider).refreshPrayerTimes();
      } finally {
        _isScheduling = false;
      }
    });
  }

  // Old logic removed, delegating to AlarmSchedulerService via PrayerEngineService
}
