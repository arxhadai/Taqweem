import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/features/always_on_timer/domain/models/always_on_timer_settings.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/providers/always_on_timer_provider.dart';
import 'package:ramzan_companion/features/always_on_timer/presentation/screens/always_on_timer_screen.dart';

class AlwaysOnTimerSettingsScreen extends ConsumerWidget {
  const AlwaysOnTimerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(alwaysOnTimerProvider);
    final settings = timerState.settings;
    final notifier = ref.read(alwaysOnTimerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Always-On Timer Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Always-On Timer'),
            subtitle: const Text('Keeps a countdown visible on screen'),
            value: settings.isEnabled,
            onChanged: (val) => notifier.toggleEnabled(val),
          ),

          if (settings.isEnabled) ...[
            const Divider(),
            _buildSectionHeader('Display Configuration'),
            ListTile(
              title: const Text('Timer Mode'),
              subtitle: Text(_formatEnum(settings.timerMode)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showEnumDialog<TimerMode>(
                context,
                'Timer Mode',
                TimerMode.values,
                (val) =>
                    notifier.updateSettings(settings.copyWith(timerMode: val)),
              ),
            ),
            ListTile(
              title: const Text('Display Mode'),
              subtitle: Text(_formatEnum(settings.displayMode)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showEnumDialog<DisplayMode>(
                context,
                'Display Mode',
                DisplayMode.values,
                (val) => notifier.updateSettings(
                  settings.copyWith(displayMode: val),
                ),
              ),
            ),

            if (settings.displayMode == DisplayMode.scheduled) ...[
              ListTile(
                title: const Text('Scheduled Start Time'),
                subtitle: Text(settings.startTime),
                trailing: const Icon(Icons.access_time, size: 16),
                onTap: () async {
                  final time = await _pickTime(context, settings.startTime);
                  if (time != null) {
                    notifier.updateSettings(settings.copyWith(startTime: time));
                  }
                },
              ),
              ListTile(
                title: const Text('Scheduled End Time'),
                subtitle: Text(settings.endTime),
                trailing: const Icon(Icons.access_time, size: 16),
                onTap: () async {
                  final time = await _pickTime(context, settings.endTime);
                  if (time != null) {
                    notifier.updateSettings(settings.copyWith(endTime: time));
                  }
                },
              ),
            ],

            const Divider(),
            _buildSectionHeader('Visual Style'),
            ListTile(
              title: const Text('Timer Style'),
              subtitle: Text(_formatEnum(settings.style)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showEnumDialog<TimerStyle>(
                context,
                'Timer Style',
                TimerStyle.values,
                (val) => notifier.updateSettings(settings.copyWith(style: val)),
              ),
            ),

            const Divider(),
            _buildSectionHeader('Device Behavior'),
            SwitchListTile(
              title: const Text('Keep Screen On'),
              subtitle: const Text(
                'Prevents device from sleeping during display',
              ),
              value: settings.keepScreenOn,
              onChanged: (val) =>
                  notifier.updateSettings(settings.copyWith(keepScreenOn: val)),
            ),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AlwaysOnTimerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Open Always-On Display'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
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
          color: Colors.amber,
        ),
      ),
    );
  }

  void _showEnumDialog<T>(
    BuildContext context,
    String title,
    List<T> values,
    Function(T) onSelected,
  ) async {
    final T? result = await showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select $title'),
        children: values
            .map(
              (e) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, e),
                child: Text(_formatEnum(e as Object)),
              ),
            )
            .toList(),
      ),
    );
    if (result != null) onSelected(result);
  }

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String _formatEnum(Object value) {
    return value.toString().split('.').last.toUpperCase();
  }
}
