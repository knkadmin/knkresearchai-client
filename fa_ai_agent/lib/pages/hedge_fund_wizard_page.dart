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
import '../widgets/hedge_fund_wizard/history_dialog.dart';

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
  bool _isMenuCollapsed = true;
  bool _isHovered = false;
  List<Map<String, dynamic>> _questionHistory = [];
  StreamSubscription? _historySubscription;

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
    _setupHistoryListener();
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

  void _setupHistoryListener() {
    _historySubscription?.cancel();
    _historySubscription = _service.getQuestionHistory().listen((history) {
      if (mounted) {
        setState(() {
          _questionHistory = history.map((item) {
            return {
              ...item,
              'id': item['id'] ?? '',
            };
          }).toList();
        });
      }
    }, onError: (error) {
      print('Error getting history: $error');
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
    _historySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 300;
    final isVerySmallScreen = screenWidth < 500;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Main Content
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
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
                    const Spacer(),
                    if (_isMenuCollapsed)
                      TextButton.icon(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.white.withOpacity(0.1);
                              }
                              return Colors.transparent;
                            },
                          ),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(8)),
                        ),
                        icon: const Icon(Icons.history, color: Colors.white),
                        label: const Text(
                          'History',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          setState(() {
                            _isMenuCollapsed = false;
                          });
                        },
                      ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: _messages.isEmpty
                        ? _buildInitialView()
                        : _buildChatView(),
                  ),
                ),
              ],
            ),
          ),
          // Semi-transparent mask
          if (!_isMenuCollapsed)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMenuCollapsed = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOutExpo,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          // Side Menu
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutExpo,
            right: isSmallScreen
                ? (_isMenuCollapsed ? -screenWidth : 0)
                : (_isMenuCollapsed ? -300 : 0),
            width: isSmallScreen ? screenWidth : 300,
            height: MediaQuery.of(context).size.height,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutExpo,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: isSmallScreen
                    ? BorderRadius.circular(12)
                    : BorderRadius.zero,
                boxShadow: isSmallScreen
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: isSmallScreen
                    ? BorderRadius.circular(12)
                    : BorderRadius.zero,
                child: Column(
                  children: [
                    // Menu Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isMenuCollapsed = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // History List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _questionHistory.length,
                        itemBuilder: (context, index) {
                          final item = _questionHistory[index];
                          final timestamp = item['createdDate'];
                          DateTime date;
                          if (timestamp is Timestamp) {
                            date = timestamp.toDate();
                          } else {
                            try {
                              date = DateTime.parse(timestamp.toString());
                            } catch (e) {
                              print('Error parsing date: $e');
                              date = DateTime.now();
                            }
                          }
                          return MouseRegion(
                            onEnter: (_) => setState(() => _isHovered = true),
                            onExit: (_) => setState(() => _isHovered = false),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => HistoryDialog(
                                      question: item['question'],
                                      answer: item['result'] ?? '',
                                      createdDate:
                                          (item['createdDate'] as Timestamp)
                                              .toDate(),
                                      documentId: item['id'],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['question'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getTimeAgo(date),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
                          'For optimal results, please structure your queries with relevant context or hypothesis followed by your specific question.',
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
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 8.0, bottom: 32.0),
                    itemCount: _messages.length + (_isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isProcessing) {
                        return const TypingIndicator();
                      }
                      final message = _messages[index];
                      final isNew = index >= _lastMessageCount - 1;

                      // Determine if the current message is the AI response with markdown
                      // Removed index check - assuming _currentUuid applies to any visible AI message
                      final bool isShareableAiMessage =
                          !message.isUser && message.isMarkdown;

                      return AnimatedMessage(
                        isNew: isNew,
                        child: ChatMessage(
                          key: message.key,
                          text: message.text,
                          isUser: message.isUser,
                          isMarkdown: message.isMarkdown,
                          onSharePressed:
                              isShareableAiMessage // Pass handler if it's a shareable AI message
                                  ? () {
                                      // Find the history item corresponding to the current UUID
                                      final historyItem =
                                          _questionHistory.firstWhere(
                                        (item) =>
                                            item['sessionId'] == _currentUuid,
                                      );

                                      showDialog(
                                        context: context,
                                        builder: (context) => HistoryDialog(
                                          question:
                                              historyItem['question'] ?? '',
                                          answer: historyItem['result'] ?? '',
                                          createdDate:
                                              (historyItem['createdDate']
                                                      as Timestamp)
                                                  .toDate(),
                                          documentId: historyItem['id'] ?? '',
                                        ),
                                      );
                                    }
                                  : null, // No share button for user messages or non-markdown AI messages
                        ),
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
