import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/gestures.dart';

class ImageViewer extends StatefulWidget {
  final Image? image;

  const ImageViewer({
    super.key,
    this.image,
  }) : assert(image != null, 'Either imageUrl or image must be provided');

  static void show(BuildContext context, Image image) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: ImageViewer(image: image),
        );
      },
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  final PhotoViewScaleStateController _scaleStateController =
      PhotoViewScaleStateController();
  final PhotoViewController _controller = PhotoViewController();
  Offset _position = Offset.zero;
  double _scale = 1.0;
  Offset? _startPosition;
  double? _startScale;

  @override
  void initState() {
    super.initState();
    _controller.scale = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleStateController.dispose();
    super.dispose();
  }

  void _handleScroll(PointerScrollEvent event) {
    final double delta = event.scrollDelta.dy;
    final double newScale = _controller.scale! * (1 - delta * 0.001);
    _controller.scale = newScale.clamp(0.5, 4.0);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startPosition = _position;
    _startScale = _controller.scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_startPosition != null && _startScale != null) {
      final double newScale = _startScale! * details.scale;
      _controller.scale = newScale.clamp(0.5, 4.0);

      final Offset newPosition = _startPosition! + details.focalPointDelta;
      setState(() {
        _position = newPosition;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _startPosition = null;
    _startScale = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is PointerScrollEvent) {
              _handleScroll(event);
            }
          },
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: Transform.translate(
              offset: _position,
              child: widget.image != null
                  ? PhotoView.customChild(
                      child: widget.image!,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      controller: _controller,
                      scaleStateController: _scaleStateController,
                    )
                  : PhotoView(
                      imageProvider: widget.image!.image,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      controller: _controller,
                      scaleStateController: _scaleStateController,
                    ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              hoverColor: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mouse,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Scroll to zoom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
