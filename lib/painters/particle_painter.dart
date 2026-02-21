import 'package:flutter/material.dart';
import 'dart:math' as math;

class ParticlePainter extends CustomPainter {
  final double animationValue;
  late List<Particle> particles;

  ParticlePainter(this.animationValue) {
    particles = _generateParticles();
  }

  List<Particle> _generateParticles() {
    final random = math.Random(42); // Fixed seed for consistent particles
    final List<Particle> particleList = [];

    for (int i = 0; i < 12; i++) {
      particleList.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: 2 + random.nextDouble() * 3,
          duration: 3000 + random.nextInt(2000),
          delay: random.nextInt(2000),
        ),
      );
    }

    return particleList;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final progress =
          (animationValue * 1000 - particle.delay) / particle.duration;

      if (progress >= 0 && progress <= 1) {
        // Float upward with slight horizontal drift
        final offsetY = size.height * (1 - progress);
        final offsetX = size.width * particle.x +
            math.sin(progress * math.pi * 4) * 30;

        final opacity = particle.size / 5;
        final fadeOpacity = progress < 0.3
            ? opacity * (progress / 0.3)
            : progress > 0.8
                ? opacity * (1 - (progress - 0.8) / 0.2)
                : opacity;

        canvas.drawCircle(
          Offset(offsetX, offsetY),
          particle.size,
          Paint()
            ..color = const Color(0xFFD4AF37)
                .withValues(alpha: 0.4 * fadeOpacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final int duration; // milliseconds
  final int delay; // milliseconds

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.duration,
    required this.delay,
  });
}
