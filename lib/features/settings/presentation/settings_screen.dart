import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/features/notifications/presentation/notification_scheduler.dart';
import 'package:ramzan_companion/features/prayer_times/domain/prayer_enums.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_provider.dart';
import 'package:ramzan_companion/features/settings/presentation/providers/settings_state.dart';
import 'package:ramzan_companion/features/notifications/data/alarm_sound_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ramzan_companion/core/providers/storage_provider.dart';
import 'package:ramzan_companion/features/notifications/domain/alarm_event_type.dart';
import 'package:ramzan_companion/core/models/prayer_timing_models.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/screens/always_on_timer_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Notifications
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Master switch for all alerts'),
            value: settings.isNotificationsEnabled,
            onChanged: (val) => notifier.toggleNotifications(val),
            secondary: const Icon(Icons.notifications_active),
          ),

          if (settings.isNotificationsEnabled) ...[
            const Divider(),
            _buildSectionHeader('Sehri Alerts'),
            _buildAlarmTypeSelector(
              context,
              'Sehri Alert Type',
              settings.sehriAlarmType,
              (val) => notifier.updateSehriAlarmType(val),
            ),
            _buildAlarmTypeSelector(
              context,
              'Sehri Reminder Type',
              settings.sehriReminderType,
              (val) => notifier.updateSehriReminderType(val),
            ),
            _buildPreAlarmSelector(
              context,
              'Sehri Reminders (Minutes Before)',
              settings.sehriPreAlarms,
              (val) => notifier.updateSehriPreAlarms(val),
            ),
            const Divider(),
            _buildSectionHeader('Iftar Alerts'),
            _buildAlarmTypeSelector(
              context,
              'Iftar Alert Type',
              settings.iftarAlarmType,
              (val) => notifier.updateIftarAlarmType(val),
            ),
            _buildAlarmTypeSelector(
              context,
              'Iftar Reminder Type',
              settings.iftarReminderType,
              (val) => notifier.updateIftarReminderType(val),
            ),
            _buildPreAlarmSelector(
              context,
              'Iftar Reminders (Minutes Before)',
              settings.iftarPreAlarms,
              (val) => notifier.updateIftarPreAlarms(val),
            ),
            const Divider(),
            _buildSectionHeader('Sound & Vibration'),
            ListTile(
              title: const Text('Test Alarm (Fires in 10s)'),
              subtitle: const Text(
                'Verify if alarms are working on your device',
              ),
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              onTap: () async {
                final scheduler = ref.read(notificationServiceProvider);
                final now = DateTime.now();
                await scheduler.scheduleNotification(
                  id: 9999,
                  title: 'Test Alarm',
                  body: 'If you see this, alarms are working!',
                  scheduledDate: now.add(const Duration(seconds: 10)),
                  vibration: settings.vibrationEnabled,
                  isAlarm: true,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Test alarm scheduled for 10 seconds from now',
                      ),
                    ),
                  );
                }
              },
            ),
            // Per-event alarm sound configuration
            Builder(builder: (context) {
              final soundManager = AlarmSoundManager(ref.read(storageServiceProvider));
              final Map<AlarmEventType, AudioPlayer> players = {};
              Widget buildTile(String title, AlarmEventType type) {
                final current = soundManager.getSoundForEvent(type);
                return ListTile(
                  title: Text(title),
                  subtitle: Text(current.toUpperCase()),
                  leading: const Icon(Icons.music_note),
                  trailing: TextButton(
                    child: const Text('Preview'),
                    onPressed: () async {
                      try {
                        // Toggle stop if already playing
                        final existing = players[type];
                        if (existing != null) {
                          await existing.stop();
                          await existing.release();
                          players.remove(type);
                          return;
                        }

                        String soundName = soundManager.getSoundForEvent(type);
                        String assetPath;
                        if (soundName == 'standard' || soundName == 'athan') {
                          assetPath = 'assets/sounds/athan.mp3';
                        } else {
                          assetPath = 'assets/sounds/$soundName.mp3';
                        }

                        final player = AudioPlayer();
                        players[type] = player;
                        await player.play(AssetSource(assetPath.replaceFirst('assets/', '')));

                        // Stop after 6 seconds automatically
                        Future.delayed(const Duration(seconds: 6), () async {
                          if (players[type] == player) {
                            await player.stop();
                            await player.release();
                            players.remove(type);
                          }
                        });
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Preview failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                  onTap: () async {
                    final String? result = await showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Alarm Sound'),
                        children: ['athan', 'nature', 'beep']
                            .map(
                              (e) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, e),
                                child: Text(e.toUpperCase()),
                              ),
                            )
                            .toList(),
                      ),
                    );
                    if (result != null) {
                      await soundManager.setSoundForEvent(type, result);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Saved $result for $title')),
                        );
                      }
                    }
                  },
                );
              }

              return Column(
                children: [
                  buildTile('Prayer Alarm', AlarmEventType.prayer),
                  buildTile('Sehri Start', AlarmEventType.sehriStart),
                  buildTile('Iftar Start', AlarmEventType.iftarStart),
                  buildTile('Sehri Reminder', AlarmEventType.sehriReminder),
                  buildTile('Iftar Reminder', AlarmEventType.iftarReminder),
                ],
              );
            }),
            SwitchListTile(
              title: const Text('Vibration'),
              value: settings.vibrationEnabled,
              onChanged: (val) => notifier.toggleVibration(val),
            ),
          ],
          const Divider(),

          _buildSectionHeader('Timing Mode & Mosque Adjustment'),
          ListTile(
            title: const Text('Operating Mode'),
            subtitle: Text(_formatEnum(settings.timingMode)),
            leading: const Icon(Icons.settings_suggest_outlined),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final TimingMode? result = await showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Select Timing Mode'),
                  children: TimingMode.values
                      .map(
                        (e) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, e),
                          child: Text(_formatEnum(e)),
                        ),
                      )
                      .toList(),
                ),
              );
              if (result != null) {
                notifier.updateTimingMode(result);
              }
            },
          ),

          if (settings.timingMode == TimingMode.calculationWithOffset) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Adjustments (Minutes +/-)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
              final val = settings.offsets[prayer] ?? 0;
              return ListTile(
                title: Text(prayer),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        final newMap = Map<String, int>.from(settings.offsets);
                        newMap[prayer] = (val - 1).clamp(-60, 60);
                        notifier.updateOffsets(newMap);
                      },
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        val > 0 ? '+$val' : '$val',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        final newMap = Map<String, int>.from(settings.offsets);
                        newMap[prayer] = (val + 1).clamp(-60, 60);
                        notifier.updateOffsets(newMap);
                      },
                    ),
                  ],
                ),
              );
            }),
          ],

          if (settings.timingMode == TimingMode.mosqueManual) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Manual Mosque Times',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
              final time = settings.manualTimes[prayer] ?? DateTime.now();
              return ListTile(
                title: Text(prayer),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(time),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      final newTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        picked.hour,
                        picked.minute,
                      );
                      final newMap = Map<String, DateTime>.from(
                        settings.manualTimes,
                      );
                      newMap[prayer] = newTime;
                      notifier.updateManualTimes(newMap);
                    }
                  },
                  child: Text(
                    TimeOfDay.fromDateTime(time).format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],

          // Theme
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  notifier.updateTheme(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),

          const Divider(),
          _buildSectionHeader('Troubleshooting'),
          ListTile(
            leading: const Icon(Icons.battery_alert, color: Colors.blue),
            title: const Text('Battery Optimization'),
            subtitle: const Text('Ensure alarms work in background'),
            onTap: () async {
              await ref
                  .read(notificationServiceProvider)
                  .requestBatteryExemption();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Battery settings opened')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('Check Permissions'),
            subtitle: const Text('Verify notification & alarm setup'),
            onTap: () async {
              final ok = await ref
                  .read(notificationServiceProvider)
                  .checkPermissions();
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Permission Status'),
                    content: Text(
                      ok
                          ? 'All permissions are correctly granted!'
                          : 'Some permissions are missing (Notifications or Exact Alarms). Please check your system settings.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          const Divider(),
          _buildSectionHeader('Features'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Always-On Timer'),
            subtitle: const Text('Countdown & AMOLED display settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AlwaysOnTimerSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Prayer Calculation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // Hijri Date Offset
          ListTile(
            title: const Text('Hijri Date Offset'),
            subtitle: Text(
              settings.hijriOffset == 0
                  ? 'No adjustment'
                  : '${settings.hijriOffset > 0 ? "+" : ""}${settings.hijriOffset} day(s)',
            ),
            leading: const Icon(Icons.calendar_today_outlined),
            trailing: DropdownButton<int>(
              value: settings.hijriOffset,
              onChanged: (int? val) {
                if (val != null) notifier.updateHijriOffset(val);
              },
              items: [-2, -1, 0, 1, 2]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e == 0 ? '0' : (e > 0 ? '+$e' : '$e')),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Calculation Method
          ListTile(
            title: const Text('Method'),
            subtitle: Text(_formatEnum(settings.calculationMethod)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final PrayerCalculationMethod? result = await showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Select Method'),
                  children: PrayerCalculationMethod.values
                      .map(
                        (e) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, e),
                          child: Text(_formatEnum(e)),
                        ),
                      )
                      .toList(),
                ),
              );
              if (result != null) {
                notifier.updateCalculationMethod(result);
              }
            },
          ),

          // Madhab
          ListTile(
            title: const Text('Madhab (Asr Time)'),
            subtitle: Text(_formatEnum(settings.madhab)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final Madhab? result = await showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Select Madhab'),
                  children: Madhab.values
                      .map(
                        (e) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, e),
                          child: Text(_formatEnum(e)),
                        ),
                      )
                      .toList(),
                ),
              );
              if (result != null) {
                notifier.updateMadhab(result);
              }
            },
          ),

          // Sect
          ListTile(
            title: const Text('Sect'),
            subtitle: Text(_formatEnum(settings.sect)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final Sect? result = await showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Select Sect'),
                  children: Sect.values
                      .map(
                        (e) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, e),
                          child: Text(_formatEnum(e)),
                        ),
                      )
                      .toList(),
                ),
              );
              if (result != null) {
                notifier.updateSect(result);
              }
            },
          ),

          // Transparency Notice for Bahawalpur Alignment
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Prayer times are calculated using the Karachi method. '
              'Local alignment adjustments are applied based on selected sect:\n'
              '• Sunni (Hanafi) → Matches IUB mosque timing\n'
              '• Ahl-e-Hadis → Matches Hamariweb timing\n'
              '• Shia → Uses sect-based angular adjustments',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue, // Using a distinct color for sections
        ),
      ),
    );
  }

  Widget _buildAlarmTypeSelector(
    BuildContext context,
    String title,
    AlarmType current,
    Function(AlarmType) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(_formatEnum(current)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        final AlarmType? result = await showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text('Select $title'),
            children: AlarmType.values
                .map(
                  (e) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, e),
                    child: Text(_formatEnum(e)),
                  ),
                )
                .toList(),
          ),
        );
        if (result != null) {
          onChanged(result);
        }
      },
    );
  }

  Widget _buildPreAlarmSelector(
    BuildContext context,
    String title,
    List<int> current,
    Function(List<int>) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        current.isEmpty ? 'None' : current.map((e) => '$e min').join(', '),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        final List<int> options = [5, 10, 15, 30, 45, 60, 90, 120];
        final List<int> selected = List.from(current);

        await showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(title),
                  content: SingleChildScrollView(
                    child: Column(
                      children: options.map((option) {
                        final isSelected = selected.contains(option);
                        return CheckboxListTile(
                          title: Text('$option minutes before'),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selected.add(option);
                              } else {
                                selected.remove(option);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                );
              },
            );
          },
        );
        // Update after dialog closes (or could be live, but close makes sense)
        // Sort the list
        selected.sort();
        onChanged(selected);
      },
    );
  }

  String _formatEnum(Object value) {
    if (value is TimingMode) {
      switch (value) {
        case TimingMode.calculation:
          return 'Auto (GPS Calculation)';
        case TimingMode.calculationWithOffset:
          return 'Auto + Minutes Adjustment';
        case TimingMode.mosqueManual:
          return 'Full Manual (Mosque Mode)';
      }
    }
    if (value is AlarmType) {
      switch (value) {
        case AlarmType.off:
          return 'Disabled';
        case AlarmType.notification:
          return 'Quiet Notification';
        case AlarmType.alarm:
          return 'Fullscreen Alarm';
      }
    }
    return value.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
  }
}
