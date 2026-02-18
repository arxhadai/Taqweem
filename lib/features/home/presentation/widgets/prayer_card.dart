import 'package:flutter/material.dart';

class PrayerCard extends StatelessWidget {
  final String name;
  final String time;
  final bool isNext;
  final bool isPast;

  const PrayerCard({
    super.key,
    required this.name,
    required this.time,
    this.isNext = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isNext ? 4 : 1,
      color: isNext ? colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(
          Icons.access_time,
          color: isNext ? colorScheme.primary : (isPast ? Colors.grey : null),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            color: isPast ? Colors.grey : null,
          ),
        ),
        trailing: Text(
          time,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            color: isPast ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}
