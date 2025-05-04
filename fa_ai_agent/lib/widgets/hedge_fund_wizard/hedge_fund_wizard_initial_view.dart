import 'package:flutter/material.dart';
import '../../widgets/chat_input_field.dart';
import 'gradient_border.dart';
import 'system_light_bulb_with_rays.dart';

class HedgeFundWizardInitialView extends StatefulWidget {
  final TextEditingController messageController;
  final bool isProcessing;
  final Function(String) onSubmitted;

  const HedgeFundWizardInitialView({
    super.key,
    required this.messageController,
    required this.isProcessing,
    required this.onSubmitted,
  });

  @override
  State<HedgeFundWizardInitialView> createState() =>
      _HedgeFundWizardInitialViewState();
}

class _HedgeFundWizardInitialViewState
    extends State<HedgeFundWizardInitialView> {
  bool _showInitialCard = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showInitialCard = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _showInitialCard
          ? ConstrainedBox(
              key: const ValueKey('initial_card'),
              constraints: const BoxConstraints(maxWidth: 600),
              child: GradientBorder(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.6),
                    Colors.orange.withValues(alpha: 0.6),
                    Colors.yellow.withValues(alpha: 0.6),
                    Colors.green.withValues(alpha: 0.6),
                    Colors.blue.withValues(alpha: 0.6),
                    Colors.indigo.withValues(alpha: 0.6),
                    Colors.purple.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E293B).withValues(alpha: 0.95),
                        const Color(0xFF0F172A).withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SystemLightBulbWithRays(
                        size: 56,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ask Hedge Fund Wizard Anything',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Examples:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildExampleButton(
                        'Given the context of US Tariffs chaos, what assets should I buy or sell?',
                      ),
                      const SizedBox(height: 10),
                      _buildExampleButton(
                        'Considering Nvidia\'s recent performance, what are your outlooks on the stock?',
                      ),
                      const SizedBox(height: 10),
                      _buildExampleButton(
                        'With China\'s focus on domestic tech, how might that impact semiconductor investments?',
                      ),
                      const SizedBox(height: 28),
                      ChatInputField(
                        controller: widget.messageController,
                        isProcessing: widget.isProcessing,
                        onSubmitted: widget.onSubmitted,
                        onSendPressed: () =>
                            widget.onSubmitted(widget.messageController.text),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'For optimal results, please structure your queries with relevant context or hypothesis followed by your specific question.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildExampleButton(String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.9),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 0,
        minimumSize: const Size(double.infinity, 36),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      onPressed: () {
        widget.messageController.text = text;
        widget.messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.messageController.text.length));
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
