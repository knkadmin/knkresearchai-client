import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../agent_service.dart';
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  List<Map<String, dynamic>> searchResults = [];
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  final AgentService service = AgentService();
  final GlobalKey _searchKey = GlobalKey();
  Widget? _reportPage;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _checkAuth();
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

    final searchBarBox =
        _searchKey.currentContext?.findRenderObject() as RenderBox?;
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

  void _navigateToReport(String symbol, String name) {
    // Clear search results and hide dropdown
    setState(() {
      searchResults = [];
      searchController.text = "";
      _isSearchFocused = false;
    });
    _hideSearchResults();

    // Set the report page
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

          if (snapshot.hasData) {
            final data = snapshot.data as Map<String, dynamic>;
            if (data["quotes"] != null && (data["quotes"] as List).isNotEmpty) {
              final quote = (data["quotes"] as List).first;
              final companyName = quote["shortname"] ?? symbol;
              return ResultAdvancedPage(
                tickerCode: symbol.toUpperCase(),
                companyName: companyName,
                language: Language.english,
              );
            }
          }

          // Fallback to using symbol as company name if lookup fails
          return ResultAdvancedPage(
            tickerCode: symbol.toUpperCase(),
            companyName: symbol.toUpperCase(),
            language: Language.english,
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Side Menu
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
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
                    children: [
                      const Icon(
                        Icons.history,
                        size: 20,
                        color: Color(0xFF1E293B),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Report History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Report History List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: 0, // TODO: Replace with actual report history
                    itemBuilder: (context, index) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.analytics,
                            size: 20,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        title: const Text(
                          'Company Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          'TICKER',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Text(
                          '2h ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        onTap: () {
                          // TODO: Handle report history item tap
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Left: Title
                            Row(
                              children: [
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
                                  child: const Icon(
                                    Icons.dashboard,
                                    size: 24,
                                    color: Color(0xFF2563EB),
                                  ),
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
                            // Search Bar
                            Container(
                              width: 500,
                              margin: const EdgeInsets.only(left: 24),
                              child: TextField(
                                key: _searchKey,
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
                                  suffixIcon: searchController.text.isNotEmpty
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
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            // Spacer to push profile button to the right
                            const Spacer(),
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
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.search,
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
                                    TextField(
                                      key: _searchKey,
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
                                        _buildCompanyButton(
                                            'Alphabet', 'GOOGL'),
                                        _buildCompanyButton('Amazon', 'AMZN'),
                                        _buildCompanyButton('Apple', 'AAPL'),
                                        _buildCompanyButton('Meta', 'META'),
                                        _buildCompanyButton(
                                            'Microsoft', 'MSFT'),
                                        _buildCompanyButton('Nvidia', 'NVDA'),
                                        _buildCompanyButton('Tesla', 'TSLA'),
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
        ],
      ),
    );
  }

  Widget _buildCompanyButton(String name, String symbol) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToReport(symbol, name),
        borderRadius: BorderRadius.circular(25),
        hoverColor: const Color(0xFF2E4B6F).withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF2E4B6F),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E4B6F),
                ),
              ),
              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFF2E4B6F).withOpacity(0.3),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchResultItem extends StatefulWidget {
  final String name;
  final String symbol;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.name,
    required this.symbol,
    required this.onTap,
  });

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: isHovered
              ? const Color(0xFF2563EB).withOpacity(0.1)
              : Colors.transparent,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              widget.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              widget.symbol,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E4B6F),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF2E4B6F),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
