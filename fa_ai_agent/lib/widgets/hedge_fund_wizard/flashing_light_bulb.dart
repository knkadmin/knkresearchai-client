import 'package:flutter/material.dart';

class FlashingLightBulb extends StatefulWidget {
  final double size;
  final Color color;

  const FlashingLightBulb({
    super.key,
    this.size = 56.0,
    this.color = Colors.white,
  });

  @override
  State<FlashingLightBulb> createState() => _FlashingLightBulbState();
}

class _FlashingLightBulbState extends State<FlashingLightBulb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Transform.scale(
              scale: _animation.value * 1.2,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.2),
                ),
              ),
            ),
            // Light bulb icon
            Icon(
              Icons.lightbulb_circle,
              color: widget.color,
              size: widget.size,
            ),
          ],
        );
      },
    );
  }
}
