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
  String _selectedPage = 'watchlist';
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
      _selectedPage = 'report';
    });
  }

  Widget _buildPage() {
    switch (_selectedPage) {
      case 'watchlist':
        return const WatchlistPage();
      case 'membership':
        return const MembershipPage();
      case 'resources':
        return const ResourcesPage();
      case 'report':
        return _reportPage ?? const SizedBox.shrink();
      default:
        return const WatchlistPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    final userEmail = user?.email ?? '';

    // Debug logging
    print('User photo URL: ${user?.photoURL}');
    print('User display name: ${user?.displayName}');
    print('User email: ${user?.email}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      // Left: Title and Navigation Items
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
                          const SizedBox(width: 32),
                          _NavItem(
                            label: 'Watchlist',
                            icon: Icons.list_alt_outlined,
                            isSelected: _selectedPage == 'watchlist',
                            onTap: () =>
                                setState(() => _selectedPage = 'watchlist'),
                          ),
                          const SizedBox(width: 24),
                          _NavItem(
                            label: 'Membership',
                            icon: Icons.card_membership_outlined,
                            isSelected: _selectedPage == 'membership',
                            onTap: () =>
                                setState(() => _selectedPage = 'membership'),
                          ),
                          const SizedBox(width: 24),
                          _NavItem(
                            label: 'Resources',
                            icon: Icons.library_books_outlined,
                            isSelected: _selectedPage == 'resources',
                            onTap: () =>
                                setState(() => _selectedPage = 'resources'),
                          ),
                        ],
                      ),
                      // Search Bar
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          child: TextField(
                            key: _searchKey,
                            controller: searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search company or ticker...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
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
                                  : Icon(Icons.search, color: Colors.grey[600]),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                      ),
                      // Search Results Popup
                      if (searchResults.isNotEmpty)
                        PopupMenuButton<String>(
                          position: PopupMenuPosition.under,
                          offset: const Offset(0, 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 4,
                          color: Colors.white,
                          itemBuilder: (BuildContext context) => searchResults
                              .map((result) => PopupMenuItem<String>(
                                    value: result["symbol"] ?? "",
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                result["name"] ?? "",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                result["symbol"] ?? "",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2E4B6F),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF2E4B6F),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onSelected: (String symbol) {
                            print("Selected symbol: $symbol");
                            final encodedTicker = Uri.encodeComponent(symbol);
                            print("Navigating to /report/$encodedTicker");

                            // Reset search
                            setState(() {
                              searchResults = [];
                              searchController.text = "";
                            });

                            // Navigate
                            _navigateToReport(symbol, symbol);
                          },
                          child: const SizedBox
                              .shrink(), // Empty widget since we don't need a trigger
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
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        user!.photoURL!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
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
                                  // Navigate to welcome page and clear the navigation stack
                                  context.go('/');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error signing out: $e'),
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
                _buildPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected || isHovered
                ? const Color(0xFF2563EB).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isSelected || isHovered
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  color: widget.isSelected || isHovered
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                  fontWeight: widget.isSelected || isHovered
                      ? FontWeight.w500
                      : FontWeight.normal,
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
