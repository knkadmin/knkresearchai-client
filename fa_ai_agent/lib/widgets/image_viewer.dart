import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert' as convert;

class ImageViewer extends StatefulWidget {
  final String encodedImage;

  const ImageViewer({
    super.key,
    required this.encodedImage,
  });

  static void show(BuildContext context, String encodedImage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: ImageViewer(encodedImage: encodedImage),
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
  late AnimationController _bounceController;
  late Animation<Offset> _bounceAnimation;
  Offset _position = Offset.zero;
  Offset? _startPosition;
  Offset? _lastFocalPoint;
  bool _isPanning = false;

  @override
  void initState() {
    super.initState();
    _controller.scale = PhotoViewComputedScale.contained.multiplier;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _bounceController.addListener(() {
      setState(() {
        _position = _bounceAnimation.value;
      });
    });
  }

  void _handleScroll(PointerScrollEvent event) {
    const double zoomFactor = 0.25;
    final double currentScale = _controller.scale ?? 1.0;
    final double minScale = PhotoViewComputedScale.contained.multiplier;
    final double maxScale = PhotoViewComputedScale.covered.multiplier * 4;

    final double normalizedDelta = (event.scrollDelta.dy / 30).clamp(-0.3, 0.3);

    double newScale;
    if (event.scrollDelta.dy < 0) {
      newScale = currentScale * (1 + (zoomFactor * normalizedDelta.abs()));
    } else {
      newScale = currentScale * (1 - (zoomFactor * normalizedDelta.abs()));
    }

    newScale = newScale.clamp(minScale, maxScale);
    _controller.scale = newScale;

    // Reset position when zooming out to contained size
    if (newScale <= minScale) {
      _position = Offset.zero;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startPosition = _position;
    _lastFocalPoint = details.focalPoint;
    _isPanning = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isPanning || _lastFocalPoint == null || _startPosition == null)
      return;

    final double scale = _controller.scale ?? 1.0;
    if (scale <= PhotoViewComputedScale.contained.multiplier) return;

    setState(() {
      final Offset delta = details.focalPoint - _lastFocalPoint!;
      _position = _startPosition! + delta;
      _lastFocalPoint = details.focalPoint;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!_isPanning) return;
    _isPanning = false;
    _lastFocalPoint = null;

    final double scale = _controller.scale ?? 1.0;
    if (scale <= PhotoViewComputedScale.contained.multiplier) {
      _animatePositionTo(Offset.zero);
      return;
    }

    final double maxOffset =
        (scale - 1) * 150; // Increased max offset for more freedom

    // Calculate the bounded position to bounce back to
    final Offset targetPosition = Offset(
      _position.dx.clamp(-maxOffset, maxOffset),
      _position.dy.clamp(-maxOffset, maxOffset),
    );

    // Only animate if we need to bounce back
    if (_position != targetPosition) {
      _bounceAnimation = Tween<Offset>(
        begin: _position,
        end: targetPosition,
      ).animate(CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ));

      _bounceController.reset();
      _bounceController.forward();
    }
  }

  void _animatePositionTo(Offset targetPosition) {
    _bounceAnimation = Tween<Offset>(
      begin: _position,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutBack,
    ));

    _bounceController
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleStateController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decodedImage = convert.base64.decode(widget.encodedImage);
    final imageProvider = MemoryImage(decodedImage);

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
              child: PhotoView(
                imageProvider: imageProvider,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                initialScale: PhotoViewComputedScale.contained,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                controller: _controller,
                scaleStateController: _scaleStateController,
                enableRotation: false,
                enablePanAlways: false,
                gestureDetectorBehavior: HitTestBehavior.translucent,
                basePosition: Alignment.center,
                scaleStateCycle: (scaleState) {
                  switch (scaleState) {
                    case PhotoViewScaleState.initial:
                      return PhotoViewScaleState.covering;
                    case PhotoViewScaleState.covering:
                      return PhotoViewScaleState.originalSize;
                    case PhotoViewScaleState.originalSize:
                      return PhotoViewScaleState.initial;
                    case PhotoViewScaleState.zoomedIn:
                    case PhotoViewScaleState.zoomedOut:
                      return PhotoViewScaleState.initial;
                  }
                },
                loadingBuilder: (context, event) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Error loading image'),
                  );
                },
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
