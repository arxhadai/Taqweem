import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:ramzan_companion/core/data/storage_service.dart';
import 'package:ramzan_companion/core/providers/storage_provider.dart';
import 'package:ramzan_companion/core/theme/app_theme.dart';
import 'package:ramzan_companion/features/always_on_timer/data/always_on_storage.dart';
import 'package:ramzan_companion/features/always_on_timer/domain/models/always_on_timer_settings.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/providers/always_on_timer_provider.dart';
import 'package:ramzan_companion/features/notifications/data/notification_service.dart';
import 'package:ramzan_companion/features/notifications/presentation/notification_scheduler.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/shared/presentation/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(TimerModeAdapter());
  Hive.registerAdapter(DisplayModeAdapter());
  Hive.registerAdapter(TimerStyleAdapter());
  Hive.registerAdapter(AlwaysOnTimerSettingsAdapter());

  // Initialize Storage Services
  final storageService = await StorageService.init();
  final alwaysOnStorage = await AlwaysOnStorage.init();

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        alwaysOnStorageProvider.overrideWithValue(alwaysOnStorage),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Initialize notification scheduler to handle alarms
    ref.watch(notificationSchedulerProvider);

    return MaterialApp(
      title: 'Ramzan Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const MainScreen(),
    );
  }
}
