import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/image_viewer.dart';

class ChartImage extends StatefulWidget {
  final Widget image;

  const ChartImage({
    super.key,
    required this.image,
  });

  @override
  State<ChartImage> createState() => _ChartImageState();
}

class _ChartImageState extends State<ChartImage> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(0.0, 0.0, 0.0)
          ..scale(isHovered ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? 0.2 : 0.1),
              blurRadius: isHovered ? 8 : 4,
              offset: Offset(0, isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ImageViewer.show(context, widget.image as Image),
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.transparent,
            child: widget.image,
          ),
        ),
      ),
    );
  }
}
