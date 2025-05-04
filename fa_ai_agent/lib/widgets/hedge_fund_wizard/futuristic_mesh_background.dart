import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math';
import 'dart:async';

class FuturisticMeshBackground extends StatefulWidget {
  final bool isProcessing;
  const FuturisticMeshBackground({super.key, required this.isProcessing});

  @override
  State<FuturisticMeshBackground> createState() =>
      _FuturisticMeshBackgroundState();
}

class _FuturisticMeshBackgroundState extends State<FuturisticMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<MeshPoint> _points = [];
  final int _gridSize = 12;
  final double _pointSize = 2.5;
  final double _lineWidth = 0.5;
  final Random _random = Random();
  final List<double> _pointBrightness = [];
  final List<double> _pointSizes = [];
  final List<double> _flashIntensities = [];
  final List<double> _randomOffsets = [];
  late Timer _flashTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Initialize mesh points with random positions, brightness, sizes, and movement offsets
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        _points.add(MeshPoint(
          x: i.toDouble() + _random.nextDouble() * 0.8 - 0.4,
          y: j.toDouble() + _random.nextDouble() * 0.8 - 0.4,
          z: 0.0,
        ));
        _pointBrightness.add(0.2 + _random.nextDouble() * 0.4);
        _pointSizes.add(2.0 + _random.nextDouble() * 2.0);
        _flashIntensities.add(0.0);
        _randomOffsets.add(_random.nextDouble() * 2 * math.pi);
      }
    }

    // Start flash timer
    _flashTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (widget.isProcessing && mounted) {
        setState(() {
          // Randomly select some points to flash
          for (int i = 0; i < _points.length; i++) {
            if (_random.nextDouble() < 0.1) {
              // 10% chance to flash
              _flashIntensities[i] = 1.0;
            } else {
              _flashIntensities[i] = math.max(0.0, _flashIntensities[i] - 0.1);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flashTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: MeshPainter(
            points: _points,
            gridSize: _gridSize,
            pointSize: _pointSize,
            lineWidth: _lineWidth,
            animationValue: _controller.value,
            pointBrightness: _pointBrightness,
            pointSizes: _pointSizes,
            flashIntensities: _flashIntensities,
            randomOffsets: _randomOffsets,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class MeshPoint {
  double x;
  double y;
  double z;

  MeshPoint({required this.x, required this.y, required this.z});
}

class MeshPainter extends CustomPainter {
  final List<MeshPoint> points;
  final int gridSize;
  final double pointSize;
  final double lineWidth;
  final double animationValue;
  final List<double> pointBrightness;
  final List<double> pointSizes;
  final List<double> flashIntensities;
  final List<double> randomOffsets;

  MeshPainter({
    required this.points,
    required this.gridSize,
    required this.pointSize,
    required this.lineWidth,
    required this.animationValue,
    required this.pointBrightness,
    required this.pointSizes,
    required this.flashIntensities,
    required this.randomOffsets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // Update points position based on animation
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = point.x;
      final y = point.y;
      final time = animationValue * 2 * math.pi;
      final offset = randomOffsets[i];

      // Create complex wave patterns with smoother transitions
      final wave1 = math.sin(x * 0.08 + time + offset * 0.2) *
          math.cos(y * 0.08 + time * 0.4 + offset * 0.3);
      final wave2 = math.sin(x * 0.06 + time * 0.8 + offset * 0.1) *
          math.cos(y * 0.06 + time * 0.3 + offset * 0.2);
      final wave3 = math.sin((x + y) * 0.12 + time * 0.5 + offset * 0.15) *
          math.cos((x - y) * 0.12 + time * 0.4 + offset * 0.25);

      // Add subtle random movement with increased intensity
      final randomMovement =
          math.sin(time * 0.3 + offset) * 0.2; // Increased from 0.1 to 0.2

      // Combine waves with increased amplitudes
      point.z = (wave1 * 1.0 + wave2 * 0.8 + wave3 * 0.6 + randomMovement) *
          1.2; // Increased amplitudes and overall multiplier
    }

    // Create a list of connections between points
    final List<({int p1, int p2})> connections = [];

    // Connect points that are close to each other
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final p1 = points[i];
        final p2 = points[j];
        final dx = p1.x - p2.x;
        final dy = p1.y - p2.y;
        final distance = math.sqrt(dx * dx + dy * dy);

        // Connect points that are within a certain distance
        if (distance < 2.0) {
          connections.add((p1: i, p2: j));
        }
      }
    }

    // Calculate scaling factors to fill the screen
    final scaleX = size.width / (gridSize - 1);
    final scaleY = size.height / (gridSize - 1);
    final scale = math.max(scaleX, scaleY);

    // Draw connections
    for (final connection in connections) {
      final p1 = points[connection.p1];
      final p2 = points[connection.p2];

      final x1 = p1.x * scale;
      final y1 = p1.y * scale + p1.z * 20; // Increased z-scale
      final x2 = p2.x * scale;
      final y2 = p2.y * scale + p2.z * 20; // Increased z-scale

      // Adjust line opacity based on z-position and distance
      final avgZ = (p1.z + p2.z) / 2;
      final distance = math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2));
      final lineOpacity = (0.25 + (avgZ.abs() * 0.1).clamp(0.0, 0.2)) *
          (1 - distance / (size.width * 0.3)).clamp(0.1, 1.0);
      paint.color = Colors.white.withOpacity(lineOpacity);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw points with varying size, opacity, and flash effects
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final baseSize = pointSizes[i];
      final brightness = pointBrightness[i];
      final flashIntensity = flashIntensities[i];

      final x = point.x * scale;
      final y = point.y * scale + point.z * 20;

      // Adjust point size based on both random base size and z-position
      final pointSize = baseSize * (1 + point.z.abs() * 0.2);

      // Combine base opacity with flash effect
      final baseOpacity =
          (0.35 + (point.z.abs() * 0.1).clamp(0.0, 0.2)) * brightness;
      final flashOpacity =
          flashIntensity * 0.5; // Flash adds up to 50% more opacity
      final pointOpacity = math.min(1.0, baseOpacity + flashOpacity);

      pointPaint.color = Colors.white.withOpacity(pointOpacity);

      canvas.drawCircle(Offset(x, y), pointSize, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
