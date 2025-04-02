import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(seconds: 15),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  bool _isOverflowing = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _checkOverflow();
      }
    });
  }

  void _checkOverflow() {
    if (_isDisposed) return;

    final textStyle = widget.style;
    final text = widget.text;
    final fontSize = textStyle.fontSize ?? 18.0;
    final fontFamily = textStyle.fontFamily;
    final fontWeight = textStyle.fontWeight ?? FontWeight.normal;

    // Approximate text width based on character count and font size
    final approximateWidth = text.length * fontSize * 0.6;

    if (approximateWidth > 200) {
      // Check against container width
      if (!_isDisposed) {
        setState(() {
          _isOverflowing = true;
        });
        // Add a small delay before starting the animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && mounted) {
            _startMarquee();
          }
        });
      }
    }
  }

  void _startMarquee() {
    if (!_scrollController.hasClients || _isDisposed) return;

    _scrollController
        .animateTo(
      _scrollController.position.maxScrollExtent,
      duration: widget.duration,
      curve: Curves.linear,
    )
        .then((_) {
      if (!_isDisposed && mounted) {
        _scrollController.jumpTo(0);
        _startMarquee();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOverflowing) {
      return Text(
        widget.text,
        style: widget.style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            widget.text,
            style: widget.style,
          ),
          const SizedBox(width: 20), // Add some space between repetitions
          Text(
            widget.text,
            style: widget.style,
          ),
        ],
      ),
    );
  }
}
