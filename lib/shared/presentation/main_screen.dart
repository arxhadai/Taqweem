import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramzan_companion/features/calendar/presentation/calendar_screen.dart';
import 'package:ramzan_companion/features/home/presentation/home_screen.dart';
import 'package:ramzan_companion/features/home/presentation/ramadan_home_screen.dart';
import 'package:ramzan_companion/features/home/presentation/providers/ramadan_provider.dart';
import 'package:ramzan_companion/features/notifications/presentation/notification_scheduler.dart';
import 'package:ramzan_companion/features/qibla/presentation/qibla_screen.dart';
import 'package:ramzan_companion/features/settings/presentation/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initNotificationListener();
  }

  void _initNotificationListener() {
    // Listen for alarms and show in-app dialog if active
    ref.read(notificationServiceProvider).notificationStream.listen((response) {
      if (mounted) {
        final id = response.id;
        final payload = response.payload;
        if (id != null && id >= 1000 && id < 3000 && payload != null) {
          final parts = payload.split('|');
          if (parts.length >= 2) {
            _showAlarmDialog(parts[0], parts[1], id);
          }
        }
      }
    });
  }

  void _showAlarmDialog(String title, String body, int id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.alarm, color: Colors.orange),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationServiceProvider)
                  .flutterLocalNotificationsPlugin
                  .cancel(id: id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'STOP',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ramadan = ref.watch(ramadanProvider);
    final homeScreen = ramadan.isRamadan
        ? const RamadanHomeScreen()
        : const HomeScreen();

    final screens = <Widget>[
      homeScreen,
      const CalendarScreen(),
      const QiblaScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Qibla',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
