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
import '../models/user.dart';
import '../services/subscription_service.dart';
import '../models/subscription_type.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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
  SubscriptionType _currentSubscription = SubscriptionType.free;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _checkAuth();
    _loadBrowseHistory();
    _loadMega7Companies();
    RawKeyboard.instance.addListener(_handleKeyEvent);
    _cacheManager.init();

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

  Future<void> _checkAuth() async {
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        // Get the user's ID token
        final idToken = await user.getIdToken();

        if (idToken != null) {
          // Update token in Firestore
          final firestoreService = FirestoreService();
          await firestoreService.updateUserToken(idToken);

          print('User token updated successfully in Firestore');
        } else {
          print('Failed to get user ID token');
        }
      } catch (e) {
        print('Error updating user token: $e');
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

      // If there's history and no report is currently being shown, navigate to the most recent report
      if (history.isNotEmpty && _reportPage == null) {
        final mostRecentReport = history.first;
        _navigateToReport(
            mostRecentReport.companyTicker, mostRecentReport.companyName);
      }
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
                item.containsKey("shortname") &&
                item.containsKey("symbol") &&
                item.containsKey("exchange") &&
                validExchanges.contains(item["exchange"]))
            .map((item) => {
                  "name": item["shortname"],
                  "symbol": item["symbol"],
                  "sector": item["sector"] ?? "",
                  "exchange": item["exchange"] ?? "",
                  "marketCap": item["marketCap"] ?? 0,
                  "regularMarketPrice":
                      item["regularMarketPrice"] ?? item["currentPrice"] ?? 0,
                  "regularMarketChange":
                      item["regularMarketChange"] ?? item["change"] ?? 0,
                  "regularMarketChangePercent":
                      item["regularMarketChangePercent"] ??
                          item["changePercent"] ??
                          0,
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
        final companyName = quote["shortname"] ?? symbol;
        final sector = quote["sector"];
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
      await AuthService().signOut();
      if (mounted) {
        setState(() {
          _reportPage = null;
          searchController.clear();
          searchResults = [];
          _isMenuCollapsed = true;
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userEmail = user?.email ?? '';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Main Content
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              margin: EdgeInsets.only(
                  left: user != null && !_isMenuCollapsed ? 280 : 0),
              child: Column(
                children: [
                  // Top Navigation Bar
                  Container(
                    height: 65,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Logo
                        Row(
                          children: [
                            if (user == null)
                              IconButton(
                                onPressed: () async {
                                  print('Clearing public report cache...');
                                  await _cacheManager.clearLastViewedReport();
                                  print(
                                      'Public report cache cleared successfully');
                                  setState(() {
                                    _reportPage = null;
                                    searchController.clear();
                                    searchResults = [];
                                  });
                                  _hideSearchResults();
                                  context.go('/');
                                },
                                icon: const Icon(
                                  Icons.home,
                                  size: 24,
                                  color: Color(0xFF1E293B),
                                ),
                                tooltip: 'Home',
                              )
                            else if (_isMenuCollapsed)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isMenuCollapsed = false;
                                  });
                                },
                                icon: const Icon(
                                  Icons.menu,
                                  size: 24,
                                  color: Color(0xFF1E293B),
                                ),
                                tooltip: 'Expand Menu',
                              ),
                            const SizedBox(width: 12),
                            const Text(
                              'KNK Research',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        // Middle: Search Bar (only show when report is open)
                        if (_reportPage != null)
                          Expanded(
                            child: Center(
                              child: CustomSearchBar(
                                key: _searchBarKey,
                                controller: searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _onSearchChanged,
                                hintText: 'Search for a company...',
                                onClear: () {
                                  searchController.clear();
                                  searchResults = [];
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        // Right: Action Buttons
                        Row(
                          children: [
                            if (user == null) ...[
                              // Sign Up Button
                              SizedBox(
                                height: 40,
                                child: OutlinedButton(
                                  onPressed: () {
                                    context.go('/signup');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E2C3D),
                                    side: const BorderSide(
                                      color: Color(0xFF1E2C3D),
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Sign In Button
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.go('/signin');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E2C3D),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Membership Badge - Only show for paid plans
                              if (_currentSubscription.isPaid)
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1E3A8A)
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium,
                                        size: 16,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_currentSubscription.value.toUpperCase()} PLAN',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // User Menu
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.05),
                                    width: 1,
                                  ),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: user?.photoURL != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            user!.photoURL!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            cacheWidth: 80,
                                            cacheHeight: 80,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                  Icons.person_outline,
                                                  size: 24,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              print(
                                                  'Error loading dropdown profile image: $error');
                                              return Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                  Icons.person_outline,
                                                  size: 24,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.person_outline,
                                            size: 24,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                  position: PopupMenuPosition.under,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 4,
                                  color: Colors.white,
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      enabled: false,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          if (user?.photoURL != null)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Image.network(
                                                user!.photoURL!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                cacheWidth: 80,
                                                cacheHeight: 80,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Icon(
                                                      Icons.person_outline,
                                                      size: 24,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  print(
                                                      'Error loading dropdown profile image: $error');
                                                  return Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF1F5F9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Icon(
                                                      Icons.person_outline,
                                                      size: 24,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                                size: 24,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  userEmail,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'upgrade',
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.workspace_premium,
                                            size: 20,
                                            color: Color(0xFF1E293B),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Upgrade Plan',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'settings',
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.settings,
                                            size: 20,
                                            color: Color(0xFF1E293B),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Settings',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'signout',
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.logout,
                                            size: 20,
                                            color: Color(0xFF1E293B),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Sign Out',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (String value) async {
                                    if (value == 'signout') {
                                      _handleSignOut();
                                    } else if (value == 'upgrade') {
                                      if (context.mounted) {
                                        context.push('/pricing');
                                      }
                                    } else if (value == 'settings') {
                                      if (context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => SettingsPopup(
                                            onLogout: _handleSignOut,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: _reportPage ??
                        Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (user == null) ...[
                                  // Combined Header and Search Section
                                  Container(
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF1E2C3D),
                                          Color(0xFF2E4B6F),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        const SizedBox(height: 100),
                                        const Text(
                                          "AI-Powered Financial Analyst",
                                          style: TextStyle(
                                            fontSize: 64,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 80),
                                          height: 50,
                                          child: const Text(
                                            "Delivering in-depth research to empower informed investment decisions and optimize returns.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.normal,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 40),
                                        Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 800),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Card(
                                            elevation: 20,
                                            shadowColor: Colors.black26,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              child: CenterSearchCard(
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
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 60),
                                      ],
                                    ),
                                  ),
                                  // Mag 7 Section for non-authenticated users
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 40),
                                    child: Column(
                                      children: [
                                        const Text(
                                          "Quick Start with Mag 7 Companies for FREE. No Signup Required.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E2C3D),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        Container(
                                          width: 900,
                                          child: Center(
                                            child: Wrap(
                                              spacing: 12,
                                              runSpacing: 12,
                                              alignment: WrapAlignment.center,
                                              children: _mega7Companies
                                                  .map((company) {
                                                final companyName = company
                                                    .values
                                                    .toList()
                                                    .first;
                                                final ticker =
                                                    company.keys.toList().first;
                                                return Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _navigateToReport(
                                                            ticker,
                                                            companyName),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                    hoverColor:
                                                        const Color(0xFF2E4B6F)
                                                            .withOpacity(0.1),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: const Color(
                                                              0xFF2E4B6F),
                                                          width: 1.5,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(25),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.05),
                                                            blurRadius: 10,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            ticker,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Color(
                                                                  0xFF2E4B6F),
                                                            ),
                                                          ),
                                                          Container(
                                                            height: 20,
                                                            width: 1,
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12),
                                                            color: const Color(
                                                                    0xFF2E4B6F)
                                                                .withOpacity(
                                                                    0.3),
                                                          ),
                                                          Text(
                                                            companyName,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[800],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Search Card for authenticated users
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: CenterSearchCard(
                                      searchController: searchController,
                                      searchFocusNode: _searchFocusNode,
                                      onSearchChanged: _onSearchChanged,
                                      onNavigateToReport: _navigateToReport,
                                      searchResults: searchResults,
                                      onHideSearchResults: _hideSearchResults,
                                      searchCardKey: _searchCardKey,
                                    ),
                                  ),
                                ],
                                if (user == null) ...[
                                  const SizedBox(height: 32),
                                  // Why Choose Us Section
                                  Container(
                                    width: double.infinity,
                                    color: const Color(0xFFF8F9FA),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 80),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        gradientTitle(
                                            "Why choose AI agent with us?", 32),
                                        const SizedBox(height: 60),
                                        Center(
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 40),
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                showcaseCard(
                                                  "Quick Insights",
                                                  "Understand a U.S.-listed company in just 2 minutes",
                                                  "Get a comprehensive overview of any U.S.-listed company in just two minutes, including business model, financials, and market performance.",
                                                  Icons.speed,
                                                ),
                                                const SizedBox(width: 24),
                                                showcaseCard(
                                                  "Instant Updates",
                                                  "Refresh reports in just 30 seconds",
                                                  "No need to search for updates manually—simply refresh the report and get the latest company news and market changes in 30 seconds.",
                                                  Icons.update,
                                                ),
                                                const SizedBox(width: 24),
                                                showcaseCard(
                                                  "Comprehensive View",
                                                  "Full industry landscape & competitor analysis",
                                                  "Easily see where a company fits within its industry, from upstream and downstream supply chains to key competitors, all in one clear report.",
                                                  Icons.view_comfy,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Feedback Form Section
                                  Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 700,
                                        color: Colors.black,
                                      ),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                              maxWidth: 900),
                                          color: Colors.black,
                                          padding: const EdgeInsets.all(80),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 10),
                                              const Text(
                                                "We would like to hear your feedback.",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 40),
                                              const Text(
                                                'Issue description (* Required)',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              TextField(
                                                controller: feedbackController,
                                                maxLines: 5,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Please tell us what you were trying to achieve and what unexpected results or false information you noticed from AI agent reports.',
                                                  hintStyle: const TextStyle(
                                                      color: Colors.grey),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide(
                                                        color: Colors
                                                            .grey.shade800),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide(
                                                        color: Colors
                                                            .grey.shade300),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              const Text(
                                                'Your email',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              TextField(
                                                controller: emailController,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText: 'Enter your email',
                                                  hintStyle: const TextStyle(
                                                      color: Colors.grey),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide(
                                                        color: Colors
                                                            .grey.shade800),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    borderSide: BorderSide(
                                                        color: Colors
                                                            .grey.shade300),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 30),
                                              Container(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (feedbackController
                                                        .text.isEmpty) {
                                                      QuickAlert.show(
                                                        context: context,
                                                        type: QuickAlertType
                                                            .error,
                                                        title:
                                                            "Your message is empty",
                                                        text:
                                                            'Please describe your issue in the description.',
                                                        showConfirmBtn: true,
                                                      );
                                                      return;
                                                    }
                                                    service.sendFeedback(
                                                        emailController.text,
                                                        feedbackController
                                                            .text);
                                                    emailController.text = "";
                                                    feedbackController.text =
                                                        "";
                                                    setState(() {
                                                      QuickAlert.show(
                                                        context: context,
                                                        type: QuickAlertType
                                                            .success,
                                                        title: "Thank you",
                                                        text:
                                                            'Your feedback is on its way to our mailbox.',
                                                        showConfirmBtn: true,
                                                      );
                                                    });
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStateProperty
                                                            .resolveWith<Color>(
                                                      (Set<MaterialState>
                                                          states) {
                                                        if (states.contains(
                                                            MaterialState
                                                                .hovered)) {
                                                          return Colors.white60;
                                                        }
                                                        return Colors.white;
                                                      },
                                                    ),
                                                  ),
                                                  child: Container(
                                                    width: 100,
                                                    height: 40,
                                                    child: const Center(
                                                      child: Text(
                                                        'Send',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    width: double.infinity,
                                    color: Colors.black,
                                    child: const Text(
                                      "© 2025 KNK research",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            // Side Menu (only show if user is signed in)
            if (user != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: _isMenuCollapsed ? -280 : 0,
                top: 0,
                bottom: 0,
                width: 280,
                child: SideMenu(
                  isMenuCollapsed: _isMenuCollapsed,
                  isHovered: _isHovered,
                  onMenuCollapse: (value) =>
                      setState(() => _isMenuCollapsed = value),
                  onHoverChange: (value) => setState(() => _isHovered = value),
                  onNewSearch: () {
                    setState(() {
                      _reportPage = null;
                      searchController.clear();
                      searchResults = [];
                    });
                    _hideSearchResults();
                  },
                  onNavigateToReport: _navigateToReport,
                  browseHistory: _browseHistory,
                  searchController: searchController,
                  searchResults: searchResults,
                  onHideSearchResults: _hideSearchResults,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketCard(String title, String value, String change,
      bool isPositive, String detail) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E2C3D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2C3D),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 20,
                ),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gradientTitle(String text, double fontSize) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF1E2C3D), Color(0xFF2E4B6F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget showcaseCard(
      String title, String subtitle, String description, IconData iconName) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        width: 350,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2C3D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconName,
                color: const Color(0xFF1E2C3D),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2C3D),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E2C3D),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
