import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:ramzan_companion/features/location/presentation/providers/location_provider.dart';
import 'dart:math' as math;

class QiblaCompassWidget extends ConsumerWidget {
  const QiblaCompassWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: FlutterQiblah.androidDeviceSensorSupport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error.toString()}"));
        }

        if (snapshot.data == true) {
          return _QiblaCompassContent(ref: ref);
        } else {
          return const Center(child: Text("Your device is not supported"));
        }
      },
    );
  }
}

class _QiblaCompassContent extends StatelessWidget {
  final WidgetRef ref;
  const _QiblaCompassContent({required this.ref});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final qiblahDirection = snapshot.data;
        if (qiblahDirection == null) {
          return const Center(child: Text("Waiting for compass data..."));
        }

        // Calculate alignment color (if within 3 degrees of Kaaba)
        final bool isAligned =
            (qiblahDirection.qiblah.abs() < 3) ||
            ((360 - qiblahDirection.qiblah).abs() < 3);
        final needleColor = isAligned ? Colors.green : Colors.red;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ref
                  .watch(currentCityProvider)
                  .when(
                    data: (city) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        city ?? 'Location not found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
              Text(
                "${qiblahDirection.direction.toInt()}°",
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                width: 300,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CompassPainter(
                          angle: qiblahDirection.direction,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Transform.rotate(
                        angle: (qiblahDirection.qiblah * (math.pi / 180) * -1),
                        alignment: Alignment.center,
                        child: CustomPaint(
                          painter: NeedlePainter(color: needleColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isAligned
                    ? "Aligned with Kaaba"
                    : "Align the arrow with the Kaaba",
                style: TextStyle(
                  color: isAligned ? Colors.green : Colors.grey,
                  fontWeight: isAligned ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CompassPainter extends CustomPainter {
  final double angle;
  CompassPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    var center = Offset(size.width / 2, size.height / 2);
    var radius = math.min(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);

    // Draw Kaaba indicator at 0 radians (top)
    final textPainter = TextPainter(
      text: const TextSpan(text: '🕋', style: TextStyle(fontSize: 24)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - radius - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class NeedlePainter extends CustomPainter {
  final Color color;
  NeedlePainter({this.color = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    var center = Offset(size.width / 2, size.height / 2);
    var radius = math.min(size.width / 2, size.height / 2);

    // Main arrow
    path.moveTo(center.dx, center.dy - radius + 30);
    path.lineTo(center.dx - 15, center.dy);
    path.lineTo(center.dx + 15, center.dy);
    path.close();

    canvas.drawPath(path, paint);

    // Bottom half of needle (optional, for aesthetics)
    var bottomPath = Path();
    bottomPath.moveTo(center.dx, center.dy + radius - 30);
    bottomPath.lineTo(center.dx - 10, center.dy);
    bottomPath.lineTo(center.dx + 10, center.dy);
    bottomPath.close();
    canvas.drawPath(bottomPath, Paint()..color = color.withValues(alpha: 0.5));

    canvas.drawCircle(center, 8, paint..color = Colors.black);
    canvas.drawCircle(center, 4, paint..color = Colors.white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
