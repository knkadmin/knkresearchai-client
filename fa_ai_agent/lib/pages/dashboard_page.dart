import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../agent_service.dart';
import 'watchlist_page.dart';
import 'membership_page.dart';
import 'resources_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedPage = 'watchlist';
  final searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  Timer? _debounce;
  final AgentService service = AgentService();
  final GlobalKey _searchKey = GlobalKey();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _overlayEntry?.remove();
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
                      return InkWell(
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
                          context.go('/report/$encodedTicker');
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            symbol,
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
        fetchStockData(query);
      } else {
        setState(() {
          searchResults = [];
        });
        _hideSearchResults();
      }
    });
  }

  void fetchStockData(String query) async {
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

  void _fetchReport(String ticker, String companyName) {
    print("Navigating to report for ticker: $ticker, company: $companyName");
    final encodedTicker = Uri.encodeComponent(ticker);
    print("Encoded ticker: $encodedTicker");
    try {
      if (context.mounted) {
        print("Context is mounted, navigating to /report/$encodedTicker");
        context.go('/report/$encodedTicker');
      } else {
        print("Context is not mounted");
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void _navigateToReport(String symbol, String name) {
    final encodedTicker = Uri.encodeComponent(symbol);
    print("Direct navigation to /report/$encodedTicker");

    // Hide results and reset search
    setState(() {
      searchResults = [];
      searchController.text = "";
    });

    // Navigate
    context.go('/report/$encodedTicker');
  }

  Widget _buildPage() {
    switch (_selectedPage) {
      case 'watchlist':
        return const WatchlistPage();
      case 'membership':
        return const MembershipPage();
      case 'resources':
        return const ResourcesPage();
      default:
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to your Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your personalized financial analysis hub',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
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
                            context.go('/report/$encodedTicker');
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
                              await AuthService().signOut();
                              if (context.mounted) {
                                context.go('/');
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
