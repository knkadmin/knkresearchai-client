import 'package:flutter/material.dart';

class GradientBorder extends StatelessWidget {
  final Widget child;
  final double width;
  final BorderRadius borderRadius;
  final Gradient gradient;

  const GradientBorder({
    super.key,
    required this.child,
    this.width = 1.0,
    required this.borderRadius,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GradientBorderPainter(
        width: width,
        borderRadius: borderRadius,
        gradient: gradient,
      ),
      child: child,
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final double width;
  final BorderRadius borderRadius;
  final Gradient gradient;

  GradientBorderPainter({
    required this.width,
    required this.borderRadius,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(GradientBorderPainter oldDelegate) =>
      width != oldDelegate.width ||
      borderRadius != oldDelegate.borderRadius ||
      gradient != oldDelegate.gradient;
}
