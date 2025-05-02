import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/hedge_fund_wizard_service.dart';
import 'package:uuid/uuid.dart';
import 'package:fa_ai_agent/widgets/chat_input_field.dart';
import '../widgets/hedge_fund_wizard/gradient_border.dart';
import '../widgets/hedge_fund_wizard/chat_message.dart';
import '../widgets/hedge_fund_wizard/typing_indicator.dart';
import '../widgets/hedge_fund_wizard/animated_message.dart';
import '../widgets/hedge_fund_wizard/system_light_bulb_with_rays.dart';
import '../services/auth_service.dart';

class HedgeFundWizardPage extends StatefulWidget {
  const HedgeFundWizardPage({super.key});

  @override
  State<HedgeFundWizardPage> createState() => _HedgeFundWizardPageState();
}

class _HedgeFundWizardPageState extends State<HedgeFundWizardPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final HedgeFundWizardService _service = HedgeFundWizardService();
  bool _isProcessing = false;
  String _currentUuid = const Uuid().v4();
  StreamSubscription? _responseSubscription;
  int _lastMessageCount = 0;
  bool _showInitialCard = false;

  @override
  void initState() {
    super.initState();
    // Redirect to home if not logged in
    final user = AuthService().currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
      return;
    }
    _messageController.addListener(() {
      setState(() {});
    });
    _setupResponseListener();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showInitialCard = true;
        });
      }
    });
  }

  void _setupResponseListener() {
    _responseSubscription?.cancel();
    _responseSubscription =
        _service.getResponses(_currentUuid).listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added ||
            doc.type == DocumentChangeType.modified) {
          final data = doc.doc.data() as Map<String, dynamic>;
          if (data.containsKey('status') && data['status'] == 'queued') {
            setState(() {
              _isProcessing = true;
            });
          } else if (data.containsKey('result')) {
            setState(() {
              _isProcessing = false;
              _messages.add(ChatMessage(
                text: data['result'],
                isUser: false,
                isMarkdown: true,
              ));
              _lastMessageCount = _messages.length;
            });
          }
        }
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _messages.clear();
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _currentUuid = const Uuid().v4();
    });

    _messageController.clear();

    try {
      await _service.sendQuestion(text, _currentUuid);
      _setupResponseListener();
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('Error saving message: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _responseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  TextButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.hovered)) {
                            return Colors.white.withOpacity(0.1);
                          }
                          return Colors.transparent;
                        },
                      ),
                      padding:
                          MaterialStateProperty.all(const EdgeInsets.all(8)),
                    ),
                    icon: Row(
                      children: const [
                        Icon(Icons.chevron_left, color: Colors.white),
                        SizedBox(width: 4),
                        Icon(Icons.home, color: Colors.white),
                      ],
                    ),
                    label: const SizedBox.shrink(),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child:
                    _messages.isEmpty ? _buildInitialView() : _buildChatView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
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
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
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
                        const Color(0xFF1E293B).withOpacity(0.95),
                        const Color(0xFF0F172A).withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.7),
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
                        controller: _messageController,
                        isProcessing: _isProcessing,
                        onSubmitted: _handleSubmitted,
                        onSendPressed: () =>
                            _handleSubmitted(_messageController.text),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'To get the best results from Hedge Fund Wizard, make sure your question satisfy the following structure: Context/Hypothesis + Question',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
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
        foregroundColor: Colors.white.withOpacity(0.9),
        backgroundColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 0,
        minimumSize: const Size(double.infinity, 36),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      onPressed: () {
        _messageController.text = text;
        _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length));
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

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F172A).withOpacity(0),
                  const Color(0xFF0F172A).withOpacity(0),
                  const Color(0xFF0F172A).withOpacity(0),
                  const Color(0xFF0F172A),
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstOut,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _messages.length + (_isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isProcessing) {
                        return const TypingIndicator();
                      }
                      final message = _messages[index];
                      final isNew = index >= _lastMessageCount - 1;
                      return AnimatedMessage(
                        isNew: isNew,
                        child: message,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ChatInputField(
              controller: _messageController,
              isProcessing: _isProcessing,
              onSubmitted: _handleSubmitted,
              onSendPressed: () => _handleSubmitted(_messageController.text),
            ),
          ),
        ),
      ],
    );
  }
}
