import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'native_alarm_service.dart';
import 'package:ramzan_companion/features/notifications/domain/alarm_event_type.dart';

class NotificationService {
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  final NativeAlarmService _nativeAlarmService = NativeAlarmService();

  final _notificationStreamController =
      StreamController<fln.NotificationResponse>.broadcast();

  Stream<fln.NotificationResponse> get notificationStream =>
      _notificationStreamController.stream;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Local timezone set to $timeZoneName');
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to set local timezone: $e. Falling back to UTC.',
      );
      // Keep default or fallback logic
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse response) async {
            _notificationStreamController.add(response);
          },
    );

    // Create the static Adhan Alarm channel once
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      debugPrint('NotificationService: Creating silent Adhan channel...');
      const channel = fln.AndroidNotificationChannel(
        'adhan_alarm_channel',
        'Adhan Alarm',
        description: 'Visual alerts for prayer times',
        importance: fln.Importance.max,
        playSound: false, // Requirement: All playback happens in AlarmActivity
        enableVibration: false,
        enableLights: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<void> requestPermissions() async {
    debugPrint('NotificationService: Requesting permissions...');

    // For Android 13+ support
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      debugPrint(
        'NotificationService: Android 13 notification permission status: $status',
      );
    }

    final iosPerms = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    debugPrint('NotificationService: iOS permissions granted: $iosPerms');

    final androidPerms = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    debugPrint(
      'NotificationService: Android plugin permissions granted: $androidPerms',
    );

    final exactAlarmPerms = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
    debugPrint(
      'NotificationService: Android exact alarm permissions granted: $exactAlarmPerms',
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? sound,
    AlarmEventType? eventType,
    bool vibration = true,
    bool isAlarm = false,
  }) async {
    const String channelId = 'adhan_alarm_channel';
    const String channelName = 'Adhan Alarm';

    // 1. PREMIUM ALARM (Native AlarmActivity)
    if (isAlarm && defaultTargetPlatform == TargetPlatform.android) {
      // Determine sound resource path
      // New behaviour: if caller provided eventType and sound is the soundName,
      // pass both to native. This keeps backward compatibility if only soundPath used.
      if (eventType != null && sound != null) {
        debugPrint('DEBUG [NotificationService] Scheduling NATIVE ALARM: eventType=${eventType.name}, soundName=$sound, id=$id');
        await _nativeAlarmService.scheduleAlarm(
          alarmId: id,
          time: scheduledDate,
          prayerName: title,
          eventType: eventType.name,
          soundName: sound,
        );
      } else {
        String? soundPath;
        const String packageName = "com.ramzan.companion.ramzan_companion";

        if (sound == 'athan') {
          soundPath = "android.resource://$packageName/raw/athan";
        } else if (sound == 'nature') {
          soundPath = "android.resource://$packageName/raw/nature";
        } else if (sound == 'beep') {
          soundPath = "android.resource://$packageName/raw/beep";
        } else if (sound != null && sound != 'default') {
          // Custom path or untracked
          soundPath = sound;
        } else {
          // Default bundled adhan
          soundPath = "android.resource://$packageName/raw/athan";
        }

        await _nativeAlarmService.scheduleAlarm(
          alarmId: id,
          time: scheduledDate,
          prayerName: title,
          soundPath: soundPath,
        );
      }
      // IMPORTANT: When using native alarm, don't schedule Flutter notification
      // The native alarm will show its own notification via AlarmReceiver
      debugPrint('NotificationService: Native alarm scheduled for ID $id - skipping Flutter notification');
      return;
    }

    // 2. VISUAL NOTIFICATION (for notification-only mode)
    final fln.AndroidNotificationDetails
    androidPlatformChannelSpecifics = fln.AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Visual prayer alerts',
      importance: fln.Importance.max,
      priority: fln.Priority.max,
      enableVibration: vibration,
      playSound: true, // Play sound for notification-only mode
      fullScreenIntent: false,
      ongoing: false,
      category: fln.AndroidNotificationCategory.alarm,
      visibility: fln.NotificationVisibility.public,
    );

    debugPrint(
      'NotificationService: Scheduling NOTIFICATION-ONLY id: $id at $scheduledDate',
    );
    
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        payload: '$title|$body',
        notificationDetails: fln.NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: fln.DarwinNotificationDetails(
            sound: 'athan.aiff',
          ),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );
      debugPrint('NotificationService: Successfully scheduled notification $id');
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule event $id: $e');
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelRange(int start, int end) async {
    for (int i = start; i <= end; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: i);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _nativeAlarmService.cancelAlarm(i);
      }
    }
  }

  Future<bool> checkPermissions() async {
    // Check Notification Permission
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      final requested = await Permission.notification.request();
      if (!requested.isGranted) return false;
    }

    // Check Exact Alarm (Android 12+) using Native Service for reliability
    if (defaultTargetPlatform == TargetPlatform.android) {
      final hasExact = await _nativeAlarmService.checkExactAlarmPermission();
      if (!hasExact) return false;
    }

    return true;
  }

  Future<void> requestBatteryExemption() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _nativeAlarmService.requestBatteryOptimization();
    }
  }
}
