import 'package:flutter/material.dart';
import 'dart:math';

class LightBulbIcon extends StatelessWidget {
  final double size;
  final Color color;

  const LightBulbIcon({
    super.key,
    this.size = 56.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LightBulbPainter(color: color),
    );
  }
}

class _LightBulbPainter extends CustomPainter {
  final Color color;
  _LightBulbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    // Draw glow
    final glowPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, size.width * 0.38, glowPaint);

    // Draw light rays
    final rayPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    final rayLength = size.width * 0.38;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final start = Offset(
        center.dx + rayLength * 0.7 * cos(angle),
        center.dy + rayLength * 0.7 * sin(angle),
      );
      final end = Offset(
        center.dx + rayLength * 1.15 * cos(angle),
        center.dy + rayLength * 1.15 * sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }

    // Outline
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bulbRect = Rect.fromCircle(
      center: center,
      radius: size.width * 0.32,
    );
    // Bulb outline
    canvas.drawArc(bulbRect, 0.8, 1.55 * pi, false, stroke);

    // Filament (bright yellow)
    final filament = Path();
    filament.moveTo(size.width * 0.4, size.height * 0.55);
    filament.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.62,
      size.width * 0.6,
      size.height * 0.55,
    );
    final filamentPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(filament, filamentPaint);

    // Bulb base (vertical lines)
    final baseTop = size.height * 0.68;
    final baseBottom = size.height * 0.85;
    final baseLeft = size.width * 0.38;
    final baseRight = size.width * 0.62;
    canvas.drawLine(
      Offset(baseLeft, baseTop),
      Offset(baseLeft, baseBottom),
      stroke,
    );
    canvas.drawLine(
      Offset(baseRight, baseTop),
      Offset(baseRight, baseBottom),
      stroke,
    );
    // Base horizontal lines
    final baseLinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;
    for (int i = 0; i < 3; i++) {
      final y = baseTop + (i + 1) * (baseBottom - baseTop) / 4;
      canvas.drawLine(
        Offset(baseLeft, y),
        Offset(baseRight, y),
        baseLinePaint,
      );
    }
    // Bulb bottom arc
    canvas.drawArc(
      Rect.fromLTRB(
        baseLeft,
        baseBottom - size.height * 0.04,
        baseRight,
        baseBottom + size.height * 0.04,
      ),
      0,
      pi,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(_LightBulbPainter oldDelegate) =>
      color != oldDelegate.color;
}
