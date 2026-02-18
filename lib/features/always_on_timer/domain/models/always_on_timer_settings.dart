import 'package:hive_ce/hive.dart';

part 'always_on_timer_settings.g.dart';

@HiveType(typeId: 10)
enum TimerMode {
  @HiveField(0)
  auto,
  @HiveField(1)
  prayer,
  @HiveField(2)
  iftar,
  @HiveField(3)
  sehri,
  @HiveField(4)
  custom,
}

@HiveType(typeId: 11)
enum DisplayMode {
  @HiveField(0)
  always,
  @HiveField(1)
  scheduled,
}

@HiveType(typeId: 12)
enum TimerStyle {
  @HiveField(0)
  minimal,
  @HiveField(1)
  bold,
  @HiveField(2)
  digital,
  @HiveField(3)
  analogInspired,
}

@HiveType(typeId: 13)
class AlwaysOnTimerSettings {
  @HiveField(0)
  final bool isEnabled;

  @HiveField(1)
  final TimerMode timerMode;

  @HiveField(2)
  final DisplayMode displayMode;

  @HiveField(3)
  final TimerStyle style;

  @HiveField(4)
  final String startTime; // format "HH:mm"

  @HiveField(5)
  final String endTime; // format "HH:mm"

  @HiveField(6)
  final bool keepScreenOn;

  @HiveField(7)
  final String? customTargetTime; // format "HH:mm"

  AlwaysOnTimerSettings({
    this.isEnabled = false,
    this.timerMode = TimerMode.auto,
    this.displayMode = DisplayMode.always,
    this.style = TimerStyle.minimal,
    this.startTime = "04:00",
    this.endTime = "19:30",
    this.keepScreenOn = true,
    this.customTargetTime,
  });

  AlwaysOnTimerSettings copyWith({
    bool? isEnabled,
    TimerMode? timerMode,
    DisplayMode? displayMode,
    TimerStyle? style,
    String? startTime,
    String? endTime,
    bool? keepScreenOn,
    String? customTargetTime,
  }) {
    return AlwaysOnTimerSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      timerMode: timerMode ?? this.timerMode,
      displayMode: displayMode ?? this.displayMode,
      style: style ?? this.style,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      customTargetTime: customTargetTime ?? this.customTargetTime,
    );
  }
}
