import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current system time, updating every 10 seconds to detect system clock changes.
final currentTimeProvider = StreamProvider<DateTime>((ref) {
  // Use a broadcast stream to avoid multiple timers if multiple widgets listen
  final controller = StreamController<DateTime>.broadcast();

  // Emit immediately
  controller.add(DateTime.now());

  // Periodic timer to pull the latest system time
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provides the current system date (Y-M-D), ensuring reactive updates if the system date changes.
final currentDateProvider = Provider<DateTime>((ref) {
  final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
