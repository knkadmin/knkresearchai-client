import 'package:flutter/material.dart';
import 'dart:math' as math;

class ThinkingAnimation extends StatefulWidget {
  const ThinkingAnimation({
    super.key,
    this.size = 16.0,
    this.color = const Color(0xFF1E3A8A),
  });

  final double size;
  final Color color;

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  final math.Random _random = math.Random();
  late List<int> _dotOrder;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Initialize random dot order
    _dotOrder = List.generate(3, (index) => index)..shuffle(_random);

    // Create three animations with different delays for the dots
    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            _dotOrder[index] * 0.2, // Use random order for delays
            0.6 + _dotOrder[index] * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    // Reshuffle dot order when animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dotOrder.shuffle(_random);
          _animations = List.generate(3, (index) {
            return Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  _dotOrder[index] * 0.2,
                  0.6 + _dotOrder[index] * 0.2,
                  curve: Curves.easeInOut,
                ),
              ),
            );
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: widget.size * 0.25,
              height: widget.size * 0.25,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: widget.color
                    .withOpacity(0.3 + _animations[index].value * 0.7),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
