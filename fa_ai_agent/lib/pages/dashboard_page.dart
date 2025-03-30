import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../agent_service.dart';
import '../services/browse_history_service.dart';
import '../models/browse_history.dart';
import 'watchlist_page.dart';
import 'membership_page.dart';
import 'resources_page.dart';
import 'package:fa_ai_agent/agent_service.dart';
import 'package:fa_ai_agent/main.dart';
import 'package:fa_ai_agent/pages/watchlist_page.dart';
import 'package:fa_ai_agent/pages/membership_page.dart';
import 'package:fa_ai_agent/pages/resources_page.dart';
import 'package:fa_ai_agent/result_advanced.dart';
import 'package:fa_ai_agent/widgets/thinking_animation.dart';
import 'package:fa_ai_agent/widgets/search_result_item.dart';
import 'package:fa_ai_agent/widgets/company_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  bool _isMenuCollapsed = false;
  List<Map<String, dynamic>> searchResults = [];
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  final AgentService service = AgentService();
  final BrowseHistoryService _historyService = BrowseHistoryService();
  final GlobalKey _searchBarKey = GlobalKey(debugLabel: 'search_bar');
  final GlobalKey _searchCardKey = GlobalKey(debugLabel: 'search_card');
  Widget? _reportPage;
  List<BrowseHistory> _browseHistory = [];
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _checkAuth();
    _loadBrowseHistory();
    _loadMostRecentReport();
  }

  Future<void> _checkAuth() async {
    final user = AuthService().currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }
  }

  void _loadBrowseHistory() {
    _historyService.getHistory().listen((history) {
      setState(() {
        _browseHistory = history;
      });
    });
  }

  Future<void> _loadMostRecentReport() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final history = await _historyService.getMostRecentHistory();
    if (history != null) {
      _navigateToReport(history.companyTicker, history.companyName);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _debounce?.cancel();
    _overlayEntry?.remove();
    searchController.dispose();
    super.dispose();
  }

  void _showSearchResults() {
    _hideSearchResults();

    // Determine which search field is focused and use its key
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
                      return SearchResultItem(
                        name: name,
                        symbol: symbol,
                        onTap: () {
                          print("Tapped on $symbol");
                          final encodedTicker = Uri.encodeComponent(symbol);
                          print("Navigating to /report/$encodedTicker");

                          // Hide results and reset search
                          setState(() {
                            searchResults = [];
                            searchController.text = "";
                          });

                          // Navigate
                          _navigateToReport(symbol, name);
                        },
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
      setState(() {
        searchResults = (data["quotes"] as List)
            .where((item) =>
                item.containsKey("shortname") && item.containsKey("symbol"))
            .map((item) => {
                  "name": item["shortname"],
                  "symbol": item["symbol"],
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
      // Clear search results and hide dropdown immediately
      setState(() {
        searchResults = [];
        searchController.text = "";
        _isSearchFocused = false;
      });
      _hideSearchResults();

      // Set the report page immediately
      setState(() {
        _reportPage = FutureBuilder(
          future: service.searchTickerSymbol(symbol),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: ThinkingAnimation(
                    size: 24,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
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
                        'Error loading report: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data as Map<String, dynamic>;
            if (data["quotes"] != null && (data["quotes"] as List).isNotEmpty) {
              final quote = (data["quotes"] as List).first;
              final companyName = quote["shortname"] ?? symbol;
              final sector = quote["sector"];
              return ResultAdvancedPage(
                tickerCode: symbol.toUpperCase(),
                companyName: companyName,
                language: Language.english,
                sector: sector ?? '',
              );
            }

            // Fallback to using symbol as company name if lookup fails
            return ResultAdvancedPage(
              tickerCode: symbol.toUpperCase(),
              companyName: symbol.toUpperCase(),
              language: Language.english,
              sector: '',
            );
          },
        );
      });

      // Update history in parallel
      _historyService
          .addHistory(
        companyName: name,
        companyTicker: symbol,
      )
          .catchError((error) {
        // Log error but don't block the UI
        print('Error updating history: $error');
      });
    } catch (e) {
      // Handle any errors that occur during navigation
      if (mounted) {
        setState(() {
          _reportPage = Scaffold(
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            margin: EdgeInsets.only(left: _isMenuCollapsed ? 0 : 280),
            child: Column(
              children: [
                SafeArea(
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
                            // Left side: Menu and Title
                            Row(
                              children: [
                                if (_isMenuCollapsed)
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.05),
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.menu,
                                        size: 24,
                                        color: Color(0xFF1E293B),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isMenuCollapsed = false;
                                        });
                                      },
                                    ),
                                  ),
                                if (_isMenuCollapsed) const SizedBox(width: 12),
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
                            // Center: Search Bar (only show when report page is loaded)
                            if (_reportPage != null)
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 500,
                                    child: TextField(
                                      key: _searchBarKey,
                                      controller: searchController,
                                      focusNode: _searchFocusNode,
                                      onChanged: _onSearchChanged,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1E293B),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search company or ticker...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        suffixIcon: searchController
                                                .text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(Icons.clear,
                                                    color: Colors.grey[600]),
                                                onPressed: () {
                                                  searchController.clear();
                                                  setState(() {
                                                    searchResults = [];
                                                  });
                                                  _hideSearchResults();
                                                },
                                              )
                                            : Icon(Icons.search,
                                                color: Colors.grey[600]),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // Right: Profile Button
                            Container(
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
                                icon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF1E293B),
                                  size: 20,
                                ),
                                position: PopupMenuPosition.under,
                                offset: const Offset(0, 8),
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
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Icon(
                                                  Icons.person_outline,
                                                  size: 40,
                                                  color: Color(0xFF1E293B),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                print(
                                                    'Error loading dropdown profile image: $error');
                                                return const Icon(
                                                  Icons.person_outline,
                                                  size: 40,
                                                  color: Color(0xFF1E293B),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.person_outline,
                                            size: 40,
                                            color: Color(0xFF1E293B),
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
                                    try {
                                      await AuthService().signOut();
                                      if (context.mounted) {
                                        context.go('/');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Error signing out: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Stack(
                    children: [
                      if (_reportPage != null)
                        _reportPage!
                      else
                        Column(
                          children: [
                            const Spacer(flex: 2),
                            Center(
                              child: Container(
                                width: 600,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.analytics_outlined,
                                      size: 48,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Search for a US-listed Company',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Enter a company name or ticker symbol to get started',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    // Search Field in Main Card
                                    TextField(
                                      key: _searchCardKey,
                                      controller: searchController,
                                      focusNode: _searchFocusNode,
                                      onChanged: _onSearchChanged,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1E293B),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search company or ticker...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        suffixIcon: searchController
                                                .text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(Icons.clear,
                                                    color: Colors.grey[600]),
                                                onPressed: () {
                                                  searchController.clear();
                                                  setState(() {
                                                    searchResults = [];
                                                  });
                                                  _hideSearchResults();
                                                },
                                              )
                                            : Icon(Icons.search,
                                                color: Colors.grey[600]),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide.none,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey[300],
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            'or',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey[300],
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    const Text(
                                      'Quick Start with Mega 7 Companies',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        CompanyButton(
                                            name: 'Alphabet',
                                            symbol: 'GOOGL',
                                            onTap: () => _navigateToReport(
                                                'GOOGL', 'Alphabet')),
                                        CompanyButton(
                                            name: 'Amazon',
                                            symbol: 'AMZN',
                                            onTap: () => _navigateToReport(
                                                'AMZN', 'Amazon')),
                                        CompanyButton(
                                            name: 'Apple',
                                            symbol: 'AAPL',
                                            onTap: () => _navigateToReport(
                                                'AAPL', 'Apple')),
                                        CompanyButton(
                                            name: 'Meta',
                                            symbol: 'META',
                                            onTap: () => _navigateToReport(
                                                'META', 'Meta')),
                                        CompanyButton(
                                            name: 'Microsoft',
                                            symbol: 'MSFT',
                                            onTap: () => _navigateToReport(
                                                'MSFT', 'Microsoft')),
                                        CompanyButton(
                                            name: 'Nvidia',
                                            symbol: 'NVDA',
                                            onTap: () => _navigateToReport(
                                                'NVDA', 'Nvidia')),
                                        CompanyButton(
                                            name: 'Tesla',
                                            symbol: 'TSLA',
                                            onTap: () => _navigateToReport(
                                                'TSLA', 'Tesla')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(flex: 3),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Side Menu
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: 280,
            transform: Matrix4.translationValues(
              _isMenuCollapsed ? -280 : 0,
              0,
              0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(
                right: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Side Menu Header
                Container(
                  height: 65,
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.menu_open,
                            color: Color(0xFF1E293B),
                          ),
                          onPressed: () {
                            setState(() {
                              _isMenuCollapsed = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Report History List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _isHovered = true),
                          onExit: (_) => setState(() => _isHovered = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isHovered
                                  ? const Color(0xFFF8FAFC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isHovered
                                    ? const Color(0xFF2563EB).withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                width: _isHovered ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isHovered
                                      ? const Color(0xFF2563EB).withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: _isHovered ? 8 : 4,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _reportPage = null;
                                    searchController.clear();
                                    searchResults = [];
                                  });
                                  _hideSearchResults();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'New Search',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.add,
                                        size: 20,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: const Text(
                          'View History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _browseHistory.length,
                          itemBuilder: (context, index) {
                            final history = _browseHistory[index];
                            final timeAgo = _getTimeAgo(history.viewedDate);

                            return StatefulBuilder(
                              builder: (context, setState) {
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) =>
                                      setState(() => _isHovered = true),
                                  onExit: (_) =>
                                      setState(() => _isHovered = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isHovered
                                          ? const Color(0xFFF8FAFC)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isHovered
                                            ? const Color(0xFF2563EB)
                                                .withOpacity(0.1)
                                            : Colors.black.withOpacity(0.05),
                                        width: _isHovered ? 1.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isHovered
                                              ? const Color(0xFF2563EB)
                                                  .withOpacity(0.1)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: _isHovered ? 8 : 4,
                                          offset: const Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          _navigateToReport(
                                              history.companyTicker,
                                              history.companyName);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      history.companyName,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF1E293B),
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFF1F5F9),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        history.companyTicker,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                timeAgo,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
