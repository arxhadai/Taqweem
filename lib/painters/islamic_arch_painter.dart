import 'package:flutter/material.dart';

class IslamicArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final startY = size.height * 0.8;
    final archWidth = size.width * 0.6;
    final archHeight = size.height * 0.6;

    // Main arch curve (Islamic pointed arch)
    final path = Path();

    // Start from left base
    path.moveTo(centerX - archWidth / 2, startY);

    // Left curve of arch
    path.quadraticBezierTo(
      centerX - archWidth / 3,
      startY - archHeight,
      centerX,
      startY - archHeight - 20,
    );

    // Right curve of arch
    path.quadraticBezierTo(
      centerX + archWidth / 3,
      startY - archHeight,
      centerX + archWidth / 2,
      startY,
    );

    canvas.drawPath(path, paint);

    // Draw decorative circles along arch (geometric pattern)
    const dotCount = 7;
    for (int i = 0; i < dotCount; i++) {
      final t = i / (dotCount - 1);
      final x = centerX - archWidth / 2 + t * archWidth;
      final y = startY - (archHeight * 0.3) - (t < 0.5 ? (t * t) : ((1 - t) * (1 - t))) * (archHeight * 0.3);

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.4)
          ..style = PaintingStyle.fill,
      );
    }

    // Draw vertical ornamental lines
    const lineCount = 5;
    for (int i = 0; i < lineCount; i++) {
      final x = centerX - archWidth / 2 + (i * archWidth / (lineCount - 1));
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + 15),
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.2)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(IslamicArchPainter oldDelegate) => false;
}
