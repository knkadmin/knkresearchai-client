import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:fa_ai_agent/services/agent_service.dart';
import '../services/browse_history_service.dart';
import '../models/browse_history.dart';
import '../services/firestore_service.dart';
import 'package:fa_ai_agent/result_advanced.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';
import 'package:fa_ai_agent/widgets/center_search_card.dart';
import 'package:fa_ai_agent/widgets/side_menu.dart';
import 'package:fa_ai_agent/widgets/settings_popup.dart';
import 'package:fa_ai_agent/main.dart';
import 'package:fa_ai_agent/widgets/search_bar.dart' show CustomSearchBar;
import 'package:quickalert/quickalert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fa_ai_agent/constants/company_data.dart';
import '../services/public_user_last_viewed_report_tracker.dart';
import '../models/user.dart' as model_user;
import '../services/subscription_service.dart';
import '../models/subscription_type.dart';
import 'package:fa_ai_agent/widgets/feedback_popup.dart';
import 'package:fa_ai_agent/widgets/legal_dialog.dart';
import 'package:fa_ai_agent/constants/legal_texts.dart';
import 'package:fa_ai_agent/pages/dashboard/components/top_navigation_bar.dart';
import 'package:fa_ai_agent/pages/dashboard/components/hero_section.dart';
import 'package:fa_ai_agent/pages/dashboard/components/mega7_section.dart';
import 'package:fa_ai_agent/pages/dashboard/components/why_choose_us_section.dart';
import 'package:fa_ai_agent/pages/dashboard/components/feedback_section.dart';
import 'package:fa_ai_agent/pages/dashboard/components/footer_section.dart';
import 'package:fa_ai_agent/pages/dashboard/components/authenticated_search_section.dart';
import 'package:fa_ai_agent/pages/dashboard/components/side_menu_section.dart';
import 'package:intl/intl.dart';
import 'package:fa_ai_agent/pages/pending_verification_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchFocused = false;
  bool _isMenuCollapsed = false;
  List<Map<String, dynamic>> searchResults = [];
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  final AgentService service = AgentService();
  final BrowseHistoryService _historyService = BrowseHistoryService();
  final PublicUserLastViewedReportTracker _cacheManager =
      PublicUserLastViewedReportTracker();
  final GlobalKey _searchBarKey = GlobalKey(debugLabel: 'search_bar');
  final GlobalKey _searchCardKey = GlobalKey(debugLabel: 'search_card');
  Widget? _reportPage;
  List<BrowseHistory> _browseHistory = [];
  bool _isHovered = false;
  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  List<Map<String, String>> _mega7Companies = [];
  late final StreamSubscription<auth.User?> _authStateSubscription;
  late final StreamSubscription<SubscriptionType> _subscriptionSubscription;
  late StreamSubscription<model_user.User?> _userDataSubscription;
  SubscriptionType _currentSubscription = SubscriptionType.free;
  bool _isTrialActive = false;
  String _trialEndDateString = "";
  double _opacity = 0.0;
  double _lastWidth = 0;
  bool _isVerificationDialogShowing = false;

  static const String _disclaimerText = LegalTexts.disclaimer;
  static const String _termsAndConditionsText = LegalTexts.termsAndConditions;
  static const String _privacyPolicyText = LegalTexts.privacyPolicy;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _checkAuth();
    _loadBrowseHistory();
    _loadMega7Companies();
    RawKeyboard.instance.addListener(_handleKeyEvent);
    _cacheManager.init();

    _scrollController.addListener(_onScroll);

    // Set up subscription listener
    _subscriptionSubscription =
        SubscriptionService().streamUserSubscription().listen((subscription) {
      if (mounted) {
        setState(() {
          _currentSubscription = subscription;
        });
      }
    });

    // Set up auth state listener
    _authStateSubscription = AuthService().authStateChanges.listen((user) {
      print('Auth state changed: ${user?.uid ?? 'null'}');
      print(
          'Pending watchlist addition: ${_cacheManager.pendingWatchlistAddition}');
      if (user != null && _cacheManager.pendingWatchlistAddition) {
        print('Handling post-registration');
        _handlePostRegistration();
      }

      if (user != null && !user.emailVerified) {
        print(
            'User signed in but email not verified, showing dialog from authStateChanges.');
        _showPendingVerificationDialogIfNeeded();
      } else {
        setState(() {
          _isVerificationDialogShowing = false;
        });
        print('User email verified, no verification dialog needed.');
      }
      // Listen to user data for trial status when auth state changes
      if (user != null) {
        _userDataSubscription =
            FirestoreService().streamUserData(user.uid).listen((userData) {
          if (mounted && userData != null) {
            final now = DateTime.now();
            final trialEnds = userData.trialEndDate;
            bool trialCurrentlyActive = trialEnds != null &&
                trialEnds.isAfter(now) &&
                !userData.hasUsedFreeTrial;

            setState(() {
              _isTrialActive = trialCurrentlyActive;
              if (trialCurrentlyActive && trialEnds != null) {
                _trialEndDateString =
                    DateFormat('MMM dd, yyyy').format(trialEnds);
              } else {
                _trialEndDateString = "";
              }
            });
          } else if (mounted) {
            setState(() {
              _isTrialActive = false;
              _trialEndDateString = "";
            });
          }
        });
      } else {
        // User logged out, reset trial state
        if (mounted) {
          setState(() {
            _isTrialActive = false;
            _trialEndDateString = "";
          });
        }
        _userDataSubscription.cancel(); // Cancel subscription if user logs out
      }
    });

    // Check for route parameters first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GoRouterState.of(context);
      if (state.uri.path.startsWith('/report/')) {
        final ticker = state.uri.path.split('/report/')[1];
        _navigateToReport(ticker, ticker);
      }
      // Start fade in animation
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  Future<void> _showPendingVerificationDialogIfNeeded() async {
    if (!mounted || _isVerificationDialogShowing) return;

    final authUser = AuthService().currentUser;
    if (authUser != null && !authUser.emailVerified) {
      // Additionally, check Firestore document as a secondary source of truth if necessary
      // For now, relying on authUser.emailVerified directly after reload from Firebase Auth
      // final firestoreService = FirestoreService();
      // final userData = await firestoreService.getUserData(authUser.uid);
      // bool isFirestoreVerified = userData?.verified ?? false;
      // if(isFirestoreVerified) { /* User is verified in Firestore, maybe a delay in Firebase Auth update? */ return; }

      setState(() {
        _isVerificationDialogShowing = true;
      });
      print('Showing pending verification dialog.');
      showDialog(
        context: context,
        barrierDismissible: false, // User must interact with the dialog
        builder: (BuildContext dialogContext) {
          return PendingVerificationDialog(
            onVerified: () {
              print('Verification successful callback triggered from dialog.');
              // Reload auth state / user data or navigate as needed
              // For now, just close dialog and let auth listeners handle the rest
              if (mounted) {
                // Navigator.pop(dialogContext); // Dialog pops itself on success now
                _checkAuth(); // Re-check auth to update UI or navigate
                setState(() {
                  _isVerificationDialogShowing = false;
                });
              }
            },
          );
        },
      ).then((_) {
        // This .then() is called when the dialog is popped.
        if (mounted) {
          print('Verification dialog closed.');
          setState(() {
            _isVerificationDialogShowing = false;
          });
          // Re-check auth status after dialog is closed, in case verification happened or user signed out
          _checkAuth();
        }
      });
    }
  }

  Future<void> _checkAuth() async {
    final user = AuthService().currentUser;
    if (user != null) {
      await user.reload(); // Ensure fresh user state from Firebase Auth
      final refreshedUser = AuthService().currentUser; // Get reloaded user

      final firestoreService = FirestoreService();
      try {
        final idToken = await refreshedUser?.getIdToken(true);
        if (idToken != null) {
          await firestoreService.updateUserToken(idToken);
          print('User token updated successfully in Firestore');
        } else {
          print('Failed to get user ID token');
        }
      } catch (e) {
        print('Error updating user token: $e');
      }
    } else {
      // User is null (not logged in)
      print('_checkAuth: User is null.');
      // Ensure dialog isn't showing if user somehow becomes null while it was up
      if (_isVerificationDialogShowing && mounted) {
        // Consider Navigator.of(context, rootNavigator: true).pop(); if dialog needs explicit closing
        print('User became null, verification dialog should close if open.');
      }
    }
  }

  Future<void> _handlePostRegistration() async {
    try {
      // Get the last viewed report from cache
      final lastViewedReport = _cacheManager.getLastViewedReport();
      print('Last viewed report from cache: $lastViewedReport');

      // Clear the cache
      await _cacheManager.clearLastViewedReport();
      print('Cleared last viewed report cache');

      // Reset the pending flag
      _cacheManager.pendingWatchlistAddition = false;

      // Navigate to dashboard first
      if (context.mounted) {
        context.go('/');

        // Wait for a short delay to ensure dashboard is loaded
        await Future.delayed(const Duration(milliseconds: 500));

        // If we have a last viewed report, navigate to it
        if (lastViewedReport != null) {
          print('Navigating to last viewed report: $lastViewedReport');
          _navigateToReport(lastViewedReport, lastViewedReport);

          // Wait for a short delay to ensure report is loaded
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Finally, navigate to pricing page
        print('Navigating to pricing page');
        context.push('/pricing');
      }
    } catch (e) {
      print('Error in post-registration flow: $e');
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  void _loadBrowseHistory() {
    _historyService.getHistory().listen((history) {
      setState(() {
        _browseHistory = history;
      });
    });
  }

  Future<void> _loadMega7Companies() async {
    final companies = await CompanyData.getMega7Companies();
    if (mounted) {
      setState(() {
        _mega7Companies = companies;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _debounce?.cancel();
    _overlayEntry?.remove();
    searchController.dispose();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _authStateSubscription.cancel();
    _subscriptionSubscription.cancel();
    _userDataSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSearchResults() {
    _hideSearchResults();

    final searchKey = _searchFocusNode.hasFocus
        ? (_searchBarKey.currentContext != null
            ? _searchBarKey
            : _searchCardKey)
        : _searchCardKey;

    final searchBarBox =
        searchKey.currentContext?.findRenderObject() as RenderBox?;
    if (searchBarBox == null) return;

    final position = searchBarBox.localToGlobal(Offset.zero);
    final size = searchBarBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideSearchResults,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            Positioned(
              top: position.dy + size.height + 4,
              left: position.dx,
              width: size.width,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final name = searchResults[index]["name"] ?? "";
                      final symbol = searchResults[index]["symbol"] ?? "";
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                searchResults = [];
                                searchController.text = "";
                              });
                              _hideSearchResults();
                              _navigateToReport(symbol, name);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              symbol,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1E3A8A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (searchResults[index]
                                                        ["exchange"] !=
                                                    null &&
                                                searchResults[index]["exchange"]
                                                    .isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  searchResults[index]
                                                      ["exchange"],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (searchResults[index]["sector"] !=
                                                null &&
                                            searchResults[index]["sector"]
                                                .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              searchResults[index]["sector"],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        if (searchResults[index]
                                                    ["regularMarketPrice"] !=
                                                null &&
                                            searchResults[index]
                                                    ["regularMarketPrice"] !=
                                                0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '\$${searchResults[index]["regularMarketPrice"].toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                if (searchResults[index][
                                                            "regularMarketChange"] !=
                                                        null &&
                                                    searchResults[index][
                                                            "regularMarketChange"] !=
                                                        0)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            left: 8),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: (searchResults[
                                                                          index]
                                                                      [
                                                                      "regularMarketChange"] >=
                                                                  0
                                                              ? Colors.green
                                                              : Colors.red)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      '${searchResults[index]["regularMarketChange"] >= 0 ? '+' : ''}${searchResults[index]["regularMarketChangePercent"].toStringAsFixed(2)}%',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: searchResults[
                                                                        index][
                                                                    "regularMarketChange"] >=
                                                                0
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
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
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
    if (_isSearchFocused && searchResults.isNotEmpty) {
      _showSearchResults();
    }
  }

  void _hideSearchResults() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (query.isNotEmpty) {
        fetchCompanyReport(query);
      } else {
        setState(() {
          searchResults = [];
        });
        _hideSearchResults();
      }
    });
  }

  void fetchCompanyReport(String query) async {
    if (query.isEmpty) return;

    setState(() {
      searchResults = [];
    });

    final data = await service.searchTickerSymbol(query);
    if (data["quotes"] != null) {
      final validExchanges = [
        "NASDAQ",
        "NYSE",
        "NYSEArca",
        "OTC",
        "NYQ",
        "NMS",
      ];
      setState(() {
        searchResults = (data["quotes"] as List)
            .where((item) =>
                item.containsKey("name") &&
                item.containsKey("symbol") &&
                item.containsKey("stockExchange") &&
                item.containsKey("exchangeShortName") &&
                validExchanges.contains(item["exchangeShortName"]))
            .map((item) => {
                  "name": item["name"],
                  "symbol": item["symbol"],
                  "exchange": item["stockExchange"] ?? "",
                })
            .toList();
      });

      if (_isSearchFocused) {
        _showSearchResults();
      }
    }
  }

  void _navigateToReport(String symbol, String name) async {
    try {
      // Check if we're already viewing this company's report
      if (_reportPage is ResultAdvancedPage) {
        final currentReport = _reportPage as ResultAdvancedPage;
        if (currentReport.tickerCode.toUpperCase() == symbol.toUpperCase()) {
          return; // Already viewing this company's report
        }
      }

      // Update URL to /report with ticker
      context.go('/report/${symbol.toUpperCase()}');

      setState(() {
        searchResults = [];
        searchController.text = "";
        _isSearchFocused = false;
        _reportPage = const Scaffold(
          body: Center(
            child: ThinkingAnimation(
              size: 24,
              color: Color(0xFF1E3A8A),
            ),
          ),
        );
      });
      _hideSearchResults();

      // Update browse history if user is signed in
      final user = AuthService().currentUser;
      if (user != null) {
        _historyService
            .addHistory(
          companyName: name,
          companyTicker: symbol,
        )
            .catchError((error) {
          print('Error updating history: $error');
        });
      }

      // Fetch company data and create report page
      final data = await service.searchTickerSymbol(symbol);
      if (data["quotes"] != null && (data["quotes"] as List).isNotEmpty) {
        final quote = (data["quotes"] as List).first;
        final companyName = quote["name"] ?? symbol;
        final sector = quote["stockExchange"];
        if (mounted) {
          setState(() {
            _reportPage = ResultAdvancedPage(
              key: ValueKey(symbol),
              tickerCode: symbol.toUpperCase(),
              companyName: companyName,
              language: Language.english,
              sector: sector ?? '',
            );
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _reportPage = ResultAdvancedPage(
              key: ValueKey(symbol),
              tickerCode: symbol.toUpperCase(),
              companyName: symbol.toUpperCase(),
              language: Language.english,
              sector: '',
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportPage = Scaffold(
            key: ValueKey('error_${DateTime.now().millisecondsSinceEpoch}'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $e',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      }
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.meta) {
        if (RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.meta)) {
          // Handle Meta key up event
        }
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      // Cancel all user-related listeners
      // Ensure _authStateSubscription, _subscriptionSubscription, and _userDataSubscription are accessible
      // and cancel them if they are not null and have not been cancelled already.
      await _authStateSubscription.cancel();
      await _subscriptionSubscription.cancel();
      // _userDataSubscription might be null if user was never fully logged in or data stream failed
      // so check before cancelling.
      // Note: The previous logic for _userDataSubscription.cancel() was inside the authStateChanges listener's else block.
      // It should be robustly handled here during a manual sign-out.
      // However, direct re-cancellation might throw if already cancelled.
      // A common pattern is to use a flag or check if the subscription is paused/cancelled.
      // For simplicity here, we assume they are active or cancellation is idempotent.
      // Proper state management of subscriptions is crucial in complex apps.

      // It's good practice to nullify subscriptions after cancelling if they might be checked elsewhere
      // e.g., if ( _userDataSubscription != null ) { await _userDataSubscription.cancel(); _userDataSubscription = null; }

      _browseHistory = []; // Clear browse history

      // Sign out from Auth
      await AuthService().signOut();

      if (mounted) {
        setState(() {
          _reportPage = null;
          searchController.clear();
          searchResults = [];
          _isMenuCollapsed = true;
          _isTrialActive = false; // Reset trial status on sign out
          _trialEndDateString = "";
          _isVerificationDialogShowing = false; // Ensure dialog flag is reset
        });
        // Clear the route and go to home
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onScroll() {
    // Handle scroll events here
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Only update menu state if width actually changed
          if (constraints.maxWidth != _lastWidth) {
            _lastWidth = constraints.maxWidth;
            if (constraints.maxWidth < 850 && !_isMenuCollapsed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isMenuCollapsed = true;
                  });
                }
              });
            }
          }

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // Main Content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  margin: EdgeInsets.only(
                      left: user != null &&
                              !_isMenuCollapsed &&
                              constraints.maxWidth >= 850
                          ? 280
                          : 0),
                  child: Column(
                    children: [
                      if (_isTrialActive && user != null)
                        TrialBanner(trialEndDateString: _trialEndDateString),
                      TopNavigationBar(
                        user: user,
                        isMenuCollapsed: _isMenuCollapsed,
                        onMenuToggle: () => setState(
                            () => _isMenuCollapsed = !_isMenuCollapsed),
                        currentSubscription: _currentSubscription,
                        onSignOut: _handleSignOut,
                        reportPage: _reportPage,
                        searchBarKey: _searchBarKey,
                        searchController: searchController,
                        searchFocusNode: _searchFocusNode,
                        onSearchChanged: _onSearchChanged,
                        onClearSearch: () {
                          searchController.clear();
                          searchResults = [];
                          setState(() {});
                        },
                        onClearReportView: () {
                          setState(() {
                            _reportPage = null;
                            searchController.clear();
                            searchResults = [];
                          });
                        },
                      ),
                      // Main Content
                      Expanded(
                        child: Stack(
                          children: [
                            _reportPage ??
                                SizedBox(
                                  width: double.infinity,
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 1200,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (user == null) ...[
                                              HeroSection(
                                                searchController:
                                                    searchController,
                                                searchFocusNode:
                                                    _searchFocusNode,
                                                onSearchChanged:
                                                    _onSearchChanged,
                                                onNavigateToReport:
                                                    _navigateToReport,
                                                searchResults: searchResults,
                                                onHideSearchResults:
                                                    _hideSearchResults,
                                                searchCardKey: _searchCardKey,
                                                disclaimerText: _disclaimerText,
                                              ),
                                              Mega7Section(
                                                mega7Companies: _mega7Companies,
                                                onNavigateToReport:
                                                    _navigateToReport,
                                              ),
                                              const WhyChooseUsSection(),
                                              FeedbackSection(
                                                feedbackController:
                                                    feedbackController,
                                                emailController:
                                                    emailController,
                                                onSendFeedback: () async {
                                                  if (feedbackController
                                                      .text.isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                            'Please describe your issue in the description field.'),
                                                        backgroundColor:
                                                            Colors.red,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        margin: const EdgeInsets
                                                            .all(16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  try {
                                                    service.sendFeedback(
                                                        emailController.text,
                                                        feedbackController
                                                            .text);
                                                    emailController.text = "";
                                                    feedbackController.text =
                                                        "";

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                            'Thank you for your feedback!'),
                                                        backgroundColor:
                                                            Colors.green,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        margin: const EdgeInsets
                                                            .all(16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                            'Failed to send feedback. Please try again later.'),
                                                        backgroundColor:
                                                            Colors.red,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        margin: const EdgeInsets
                                                            .all(16),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                              FooterSection(
                                                termsAndConditionsText:
                                                    _termsAndConditionsText,
                                                privacyPolicyText:
                                                    _privacyPolicyText,
                                              ),
                                            ] else ...[
                                              AuthenticatedSearchSection(
                                                searchController:
                                                    searchController,
                                                searchFocusNode:
                                                    _searchFocusNode,
                                                onSearchChanged:
                                                    _onSearchChanged,
                                                onNavigateToReport:
                                                    _navigateToReport,
                                                searchResults: searchResults,
                                                onHideSearchResults:
                                                    _hideSearchResults,
                                                searchCardKey: _searchCardKey,
                                                disclaimerText: _disclaimerText,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            // Conditional Dimming Overlay with Animation
                            IgnorePointer(
                              ignoring: !_isSearchFocused ||
                                  _reportPage ==
                                      null, // Ignore pointer when not focused or no report
                              child: AnimatedOpacity(
                                opacity: _isSearchFocused && _reportPage != null
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(
                                    milliseconds:
                                        300), // Adjust duration as needed
                                curve: Curves
                                    .easeInOut, // Optional: Add an animation curve
                                child: Container(
                                  color: Colors.black.withOpacity(
                                      0.5), // Semi-transparent black
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Semi-transparent mask for floating menu
                if (user != null &&
                    constraints.maxWidth < 850 &&
                    !_isMenuCollapsed)
                  GestureDetector(
                    onTap: () => setState(() => _isMenuCollapsed = true),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                // Side Menu
                if (user != null)
                  SideMenuSection(
                    isMenuCollapsed: _isMenuCollapsed,
                    isHovered: _isHovered,
                    onMenuCollapse: (value) =>
                        setState(() => _isMenuCollapsed = value),
                    onHoverChange: (value) =>
                        setState(() => _isHovered = value),
                    onNewSearch: () {
                      setState(() {
                        _reportPage = null;
                        searchController.clear();
                        searchResults = [];
                      });
                      _hideSearchResults();
                      // Navigate to root route
                      context.go('/');
                    },
                    onNavigateToReport: _navigateToReport,
                    browseHistory: _browseHistory,
                    searchController: searchController,
                    searchResults: searchResults,
                    onHideSearchResults: _hideSearchResults,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TrialBanner extends StatelessWidget {
  final String trialEndDateString;

  const TrialBanner({Key? key, required this.trialEndDateString})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.grey[850]!, // Lighter grey for the shine
            Colors.black,
          ],
          stops: const [0.0, 0.5, 1.0], // Center stop for the shine
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'You are currently on a 7-day free trial of the Starter Plan, ending on $trialEndDateString. Enjoy full access!',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
