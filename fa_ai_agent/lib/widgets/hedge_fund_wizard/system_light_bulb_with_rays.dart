import 'package:flutter/material.dart';
import 'dart:math';

class SystemLightBulbWithRays extends StatelessWidget {
  final double size;
  final Color color;

  const SystemLightBulbWithRays({
    super.key,
    this.size = 56.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RaysPainter(color),
          ),
          Icon(
            Icons.lightbulb_outline,
            size: size * 0.8,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final rayPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    final rayLength = size.width * 0.55;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final start = Offset(
        center.dx + rayLength * 0.85 * cos(angle),
        center.dy + rayLength * 0.85 * sin(angle),
      );
      final end = Offset(
        center.dx + rayLength * 1.1 * cos(angle),
        center.dy + rayLength * 1.1 * sin(angle),
      );
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => color != oldDelegate.color;
}
