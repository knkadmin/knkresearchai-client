import 'package:flutter/material.dart';
import 'dart:math';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final VoidCallback onSendPressed;
  final bool isProcessing;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onSendPressed,
    this.isProcessing = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    widget.controller.addListener(() => setState(() {}));

    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });

    if (widget.isProcessing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ChatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = widget.isProcessing;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final bool isGlowing = widget.isProcessing;
              return Container(
                padding: const EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: !isGlowing
                      ? Border.all(
                          color: _hasFocus
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white.withOpacity(0.2),
                          width: 1.0)
                      : null,
                  gradient: isGlowing
                      ? SweepGradient(
                          center: Alignment.center,
                          colors: [
                            Colors.red.withOpacity(0.5),
                            Colors.orange.withOpacity(0.5),
                            Colors.yellow.withOpacity(0.5),
                            Colors.green.withOpacity(0.5),
                            Colors.blue.withOpacity(0.5),
                            Colors.indigo.withOpacity(0.5),
                            Colors.purple.withOpacity(0.5),
                            Colors.red.withOpacity(0.5),
                          ],
                          transform:
                              GradientRotation(_controller.value * 2 * pi),
                        )
                      : null,
                  boxShadow: isGlowing
                      ? [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFF5856D6).withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF2D55).withOpacity(0.2),
                            blurRadius: 5,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: TextSelectionTheme(
                        data: TextSelectionThemeData(
                          selectionColor: Colors.white.withOpacity(0.3),
                          selectionHandleColor: Colors.white,
                        ),
                        child: TextField(
                          focusNode: _focusNode,
                          controller: widget.controller,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          cursorColor: Colors.white,
                          maxLength: 250,
                          enableInteractiveSelection: true,
                          selectionControls: MaterialTextSelectionControls(),
                          decoration: InputDecoration(
                            hintText: 'Ask anything',
                            hintStyle:
                                TextStyle(color: Colors.white54, fontSize: 16),
                            border: InputBorder.none,
                            counterText: '${widget.controller.text.length}/250',
                            counterStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onSubmitted: (text) {
                            if (!widget.isProcessing) {
                              widget.onSubmitted(text);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap:
                          widget.controller.text.isEmpty || widget.isProcessing
                              ? null
                              : widget.onSendPressed,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.controller.text.isEmpty ||
                                  widget.isProcessing
                              ? Colors.white24
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: widget.isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Icon(Icons.arrow_upward,
                                color: widget.controller.text.isEmpty ||
                                        widget.isProcessing
                                    ? Colors.white54
                                    : Colors.black,
                                size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
