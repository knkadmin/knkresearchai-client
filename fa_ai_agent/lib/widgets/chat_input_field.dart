import 'package:flutter/material.dart';
import 'dart:math';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final Function(String) onSubmitted;
  final VoidCallback onSendPressed;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSubmitted,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            padding: const EdgeInsets.all(1.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: SweepGradient(
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
              ),
              boxShadow: [
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
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D23),
                borderRadius: BorderRadius.circular(26.5),
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
                          controller: controller,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          cursorColor: Colors.white,
                          maxLength: 100,
                          enableInteractiveSelection: true,
                          selectionControls: MaterialTextSelectionControls(),
                          decoration: InputDecoration(
                            hintText: 'Ask anything',
                            hintStyle:
                                TextStyle(color: Colors.white54, fontSize: 16),
                            border: InputBorder.none,
                            counterText: '',
                            counterStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            suffixText: '${controller.text.length}/100',
                            suffixStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onSubmitted: onSubmitted,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: controller.text.isEmpty || isSending
                          ? null
                          : onSendPressed,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: controller.text.isEmpty || isSending
                              ? Colors.white24
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Icon(Icons.arrow_upward,
                                color: controller.text.isEmpty
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
