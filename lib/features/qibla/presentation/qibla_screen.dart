import 'package:flutter/material.dart';
import 'widgets/qibla_compass_widget.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla Direction')),
      body: const QiblaCompassWidget(),
    );
  }
}
