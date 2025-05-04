import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/hedge_fund_wizard_service.dart';
import 'package:uuid/uuid.dart';
import '../widgets/hedge_fund_wizard/chat_message.dart';
import '../services/auth_service.dart';
import '../widgets/hedge_fund_wizard/history_dialog.dart';
import '../models/subscription_type.dart';
import '../services/firestore_service.dart';
import '../widgets/hedge_fund_wizard/hedge_fund_wizard_nav_bar.dart';
import '../widgets/hedge_fund_wizard/hedge_fund_wizard_initial_view.dart';
import '../widgets/hedge_fund_wizard/hedge_fund_wizard_chat_view.dart';
import '../widgets/hedge_fund_wizard/futuristic_mesh_background.dart';

class HedgeFundWizardPage extends StatefulWidget {
  const HedgeFundWizardPage({super.key});

  @override
  State<HedgeFundWizardPage> createState() => _HedgeFundWizardPageState();
}

class _HedgeFundWizardPageState extends State<HedgeFundWizardPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final HedgeFundWizardService _service = HedgeFundWizardService();
  final AuthService _authService = AuthService();
  bool _isProcessing = false;
  bool _showInsufficientBalance = false;
  String _currentUuid = const Uuid().v4();
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  StreamSubscription? _responseSubscription;
  StreamSubscription? _creditsSubscription;
  double? _userCredits;
  int _lastMessageCount = 0;
  bool _showInitialCard = false;
  bool _isMenuCollapsed = true;
  bool _isHovered = false;
  bool _isCreditsMenuOpen = false;
  List<Map<String, dynamic>> _questionHistory = [];
  StreamSubscription? _historySubscription;
  bool _isStarterPlan = false;
  StreamSubscription? _subscriptionSubscription;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flashController,
        curve: Curves.easeInOut,
      ),
    );
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
    _setupCreditsListener();
    _setupSubscriptionListener();
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

  void _setupCreditsListener() {
    _creditsSubscription?.cancel();
    _creditsSubscription = _authService.userDocumentStream.listen((snapshot) {
      if (mounted && snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('credits')) {
          setState(() {
            _userCredits = data['credits'] as double;
          });
        } else {
          setState(() {
            _userCredits = null;
          });
        }
      } else if (mounted) {
        setState(() {
          _userCredits = null;
        });
      }
    }, onError: (error) {
      print('Error getting user credits: $error');
      if (mounted) {
        setState(() {
          _userCredits = null;
        });
      }
    });
  }

  void _setupSubscriptionListener() {
    final user = AuthService().currentUser;
    if (user == null) return;

    _subscriptionSubscription =
        FirestoreService().streamUserData(user.uid).listen((userData) {
      if (mounted) {
        setState(() {
          _isStarterPlan =
              userData?.subscription.type == SubscriptionType.starter;
        });
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty || _isProcessing) return;

    // Check if user has sufficient credits
    if (_userCredits != null && _userCredits! <= 0) {
      setState(() {
        _isProcessing = false;
        _showInsufficientBalance = true;
        _messages.add(ChatMessage(
          text: text,
          isUser: true,
        ));
      });
      // Flash the credits button
      _flashController.forward().then((_) => _flashController.reverse());
      return;
    }

    setState(() {
      _isProcessing = true;
      _showInsufficientBalance = false;
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
    _flashController.dispose();
    _messageController.dispose();
    _responseSubscription?.cancel();
    _historySubscription?.cancel();
    _creditsSubscription?.cancel();
    _subscriptionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 300;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 3D Mesh Background
          Positioned.fill(
            child: FuturisticMeshBackground(
              isProcessing: _isProcessing,
            ),
          ),
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F172A).withOpacity(0.6),
                    const Color(0xFF0F172A).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                HedgeFundWizardNavBar(
                  isMenuCollapsed: _isMenuCollapsed,
                  userCredits: _userCredits,
                  isStarterPlan: _isStarterPlan,
                  onMenuToggle: () {
                    setState(() {
                      _isMenuCollapsed = false;
                    });
                  },
                  flashAnimation: _flashAnimation,
                ),
                Expanded(
                  child: Center(
                    child: _messages.isEmpty
                        ? HedgeFundWizardInitialView(
                            messageController: _messageController,
                            isProcessing: _isProcessing,
                            onSubmitted: _handleSubmitted,
                          )
                        : HedgeFundWizardChatView(
                            messages: _messages,
                            isProcessing: _isProcessing,
                            showInsufficientBalance: _showInsufficientBalance,
                            lastMessageCount: _lastMessageCount,
                            messageController: _messageController,
                            onSubmitted: _handleSubmitted,
                            questionHistory: _questionHistory,
                            currentUuid: _currentUuid,
                          ),
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                          color: Colors.black.withValues(alpha: 0.1),
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
                            color: Colors.white.withValues(alpha: 0.05),
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
                      child: _questionHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No history to show',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.25),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
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
                                  onEnter: (_) =>
                                      setState(() => _isHovered = true),
                                  onExit: (_) =>
                                      setState(() => _isHovered = false),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => HistoryDialog(
                                            question: item['question'],
                                            answer: item['result'] ?? '',
                                            createdDate: (item['createdDate']
                                                    as Timestamp)
                                                .toDate(),
                                            documentId: item['id'],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.05),
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
                                                color: Colors.white
                                                    .withValues(alpha: 0.3),
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
}
