import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/core/data/storage_service.dart';
import 'package:ramzan_companion/core/providers/storage_provider.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'package:ramzan_companion/features/notifications/data/notification_service.dart';
import 'package:ramzan_companion/features/notifications/presentation/notification_scheduler.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_state.dart';
import 'package:geolocator/geolocator.dart';

// Mock NotificationService
class MockNotificationService extends NotificationService {
  int scheduleCallCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> cancelAll() async {
    scheduleCallCount = 0;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? sound,
    bool vibration = true,
    bool isAlarm = false,
  }) async {
    scheduleCallCount++;
  }
}

// Mock StorageService
class MockStorageService implements StorageService {
  @override
  int? getInt(String key) => null;
  @override
  bool? getBool(String key) => null;
  @override
  String? getString(String key) => null;
  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool> setString(String key, String value) async => true;
  @override
  Future<bool> remove(String key) async => true;
}

void main() {
  test(
    'NotificationScheduler schedules notifications and responds to changes (with debouncing)',
    () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(MockStorageService()),
          notificationServiceProvider.overrideWithValue(
            MockNotificationService(),
          ),
          currentLocationProvider.overrideWith(
            (ref) => Position(
              longitude: 67.0,
              latitude: 24.0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            ),
          ),
        ],
      );

      final mockService =
          container.read(notificationServiceProvider)
              as MockNotificationService;
      final scheduler = container.read(notificationSchedulerProvider);

      // Explicitly call scheduleNotifications
      scheduler.scheduleNotifications();

      // Wait for debounce (200ms + buffer)
      await Future.delayed(Duration(milliseconds: 300));

      // Initial schedule check (should be 12-14)
      expect(mockService.scheduleCallCount, greaterThanOrEqualTo(12));
      expect(mockService.scheduleCallCount, lessThanOrEqualTo(14));

      // Reset and check if it recalculates on setting change
      await container
          .read(settingsProvider.notifier)
          .updateSehriAlarmType(AlarmType.off);

      // Wait for debounce
      await Future.delayed(Duration(milliseconds: 300));

      // Sehri off -> only Iftar alarms (7 events)
      expect(mockService.scheduleCallCount, greaterThanOrEqualTo(6));
      expect(mockService.scheduleCallCount, lessThanOrEqualTo(7));

      // Test pre-alarms (multiple updates should be debounced)
      await container
          .read(settingsProvider.notifier)
          .updateSehriAlarmType(AlarmType.alarm);
      await container.read(settingsProvider.notifier).updateSehriPreAlarms([
        5,
        10,
      ]);

      // Wait for debounce
      await Future.delayed(Duration(milliseconds: 300));

      // Sehri: 1 main + 2 pre = 3 per day
      // Iftar: 1 main = 1 per day
      // Total 4 per day * 7 days = 28 events
      expect(mockService.scheduleCallCount, greaterThanOrEqualTo(24));
      expect(mockService.scheduleCallCount, lessThanOrEqualTo(28));
    },
  );
}
