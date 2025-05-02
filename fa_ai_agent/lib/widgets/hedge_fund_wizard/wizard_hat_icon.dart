import 'package:flutter/material.dart';
import 'dart:math';

class WizardHatIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WizardHatIcon({
    super.key,
    this.size = 56.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: WizardHatPainter(color: color),
    );
  }
}

class WizardHatPainter extends CustomPainter {
  final Color color;

  WizardHatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final brimPath = Path();
    // Wide, wavy, asymmetrical brim
    brimPath.moveTo(size.width * 0.08, size.height * 0.65);
    brimPath.quadraticBezierTo(
      size.width * 0.0,
      size.height * 0.55,
      size.width * 0.18,
      size.height * 0.58,
    );
    brimPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.62,
      size.width * 0.5,
      size.height * 0.6,
    );
    brimPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.57,
      size.width * 0.82,
      size.height * 0.62,
    );
    brimPath.quadraticBezierTo(
      size.width * 1.0,
      size.height * 0.7,
      size.width * 0.92,
      size.height * 0.75,
    );
    brimPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.8,
      size.width * 0.5,
      size.height * 0.75,
    );
    brimPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.7,
      size.width * 0.08,
      size.height * 0.65,
    );
    brimPath.close();

    // Band
    final bandPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final bandPath = Path();
    bandPath.moveTo(size.width * 0.22, size.height * 0.62);
    bandPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.66,
      size.width * 0.78,
      size.height * 0.65,
    );
    bandPath.lineTo(size.width * 0.78, size.height * 0.68);
    bandPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.72,
      size.width * 0.22,
      size.height * 0.68,
    );
    bandPath.close();

    // Cone - long, wrinkled, dramatically bent
    final conePath = Path();
    conePath.moveTo(size.width * 0.35, size.height * 0.62);
    conePath.cubicTo(
      size.width * 0.38,
      size.height * 0.45,
      size.width * 0.45,
      size.height * 0.25,
      size.width * 0.55,
      size.height * 0.18,
    );
    conePath.cubicTo(
      size.width * 0.7,
      size.height * 0.12,
      size.width * 0.7,
      size.height * 0.32,
      size.width * 0.62,
      size.height * 0.38,
    );
    conePath.cubicTo(
      size.width * 0.8,
      size.height * 0.1,
      size.width * 0.3,
      size.height * 0.05,
      size.width * 0.6,
      size.height * 0.13,
    );
    conePath.cubicTo(
      size.width * 0.8,
      size.height * 0.18,
      size.width * 0.7,
      size.height * 0.45,
      size.width * 0.65,
      size.height * 0.62,
    );
    conePath.close();

    // Draw brim, band, and cone
    canvas.drawPath(brimPath, paint);
    canvas.drawPath(bandPath, bandPaint);
    canvas.drawPath(conePath, paint);

    // Wrinkle lines (details)
    final wrinklePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = size.width * 0.025
      ..style = PaintingStyle.stroke;
    final wrinkle1 = Path();
    wrinkle1.moveTo(size.width * 0.48, size.height * 0.55);
    wrinkle1.quadraticBezierTo(
      size.width * 0.52,
      size.height * 0.5,
      size.width * 0.54,
      size.height * 0.45,
    );
    final wrinkle2 = Path();
    wrinkle2.moveTo(size.width * 0.56, size.height * 0.4);
    wrinkle2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.37,
      size.width * 0.62,
      size.height * 0.33,
    );
    final wrinkle3 = Path();
    wrinkle3.moveTo(size.width * 0.5, size.height * 0.3);
    wrinkle3.quadraticBezierTo(
      size.width * 0.54,
      size.height * 0.28,
      size.width * 0.58,
      size.height * 0.25,
    );
    canvas.drawPath(wrinkle1, wrinklePaint);
    canvas.drawPath(wrinkle2, wrinklePaint);
    canvas.drawPath(wrinkle3, wrinklePaint);
  }

  @override
  bool shouldRepaint(WizardHatPainter oldDelegate) =>
      color != oldDelegate.color;
}
