import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../agent_service.dart';
import '../services/browse_history_service.dart';
import '../models/browse_history.dart';
import 'package:fa_ai_agent/result_advanced.dart';
import 'package:fa_ai_agent/widgets/thinking_animation.dart';
import 'package:fa_ai_agent/widgets/center_search_card.dart';
import 'package:fa_ai_agent/widgets/side_menu.dart';
import 'package:fa_ai_agent/main.dart';

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
    RawKeyboard.instance.addListener(_handleKeyEvent);
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
    RawKeyboard.instance.removeListener(_handleKeyEvent);
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
      setState(() {
        searchResults = (data["quotes"] as List)
            .where((item) =>
                item.containsKey("shortname") && item.containsKey("symbol"))
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
      setState(() {
        searchResults = [];
        searchController.text = "";
        _isSearchFocused = false;
      });
      _hideSearchResults();

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

            return ResultAdvancedPage(
              tickerCode: symbol.toUpperCase(),
              companyName: symbol.toUpperCase(),
              language: Language.english,
              sector: '',
            );
          },
        );
      });

      _historyService
          .addHistory(
        companyName: name,
        companyTicker: symbol,
      )
          .catchError((error) {
        print('Error updating history: $error');
      });
    } catch (e) {
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
                                        borderRadius: BorderRadius.circular(8),
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
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                                size: 20,
                                                color: Color(0xFF1E293B),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print(
                                                'Error loading profile image: $error');
                                            return Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                                size: 20,
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
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.person_outline,
                                          size: 20,
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
                                                    color:
                                                        const Color(0xFFF1F5F9),
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
          SideMenu(
            isMenuCollapsed: _isMenuCollapsed,
            isHovered: _isHovered,
            onMenuCollapse: (value) => setState(() => _isMenuCollapsed = value),
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
        ],
      ),
    );
  }
}
