import 'package:flutter/material.dart';
import '../models/browse_history.dart';
import '../services/watchlist_service.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_ai_agent/widgets/hedge_fund_wizard/system_light_bulb_with_rays.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

class SideMenu extends StatefulWidget {
  final bool isMenuCollapsed;
  final bool isHovered;
  final Function(bool) onMenuCollapse;
  final Function(bool) onHoverChange;
  final Function() onNewSearch;
  final Function(String, String) onNavigateToReport;
  final List<BrowseHistory> browseHistory;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> searchResults;
  final Function() onHideSearchResults;

  const SideMenu({
    super.key,
    required this.isMenuCollapsed,
    required this.isHovered,
    required this.onMenuCollapse,
    required this.onHoverChange,
    required this.onNewSearch,
    required this.onNavigateToReport,
    required this.browseHistory,
    required this.searchController,
    required this.searchResults,
    required this.onHideSearchResults,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isHedgeFundWizardHovered = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _glowAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isFloatingMenu =
        MediaQuery.of(context).size.width < 850 && !widget.isMenuCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: 280,
      transform: Matrix4.translationValues(
        widget.isMenuCollapsed ? -280 : 0,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.menu_open,
                      color: Color(0xFF1E293B),
                    ),
                    onPressed: () => widget.onMenuCollapse(true),
                  ),
                ),
                if (isFloatingMenu)
                  const Text(
                    'KNK Research AI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => widget.onHoverChange(true),
                      onExit: (_) => widget.onHoverChange(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isHovered
                              ? const Color(0xFFF8FAFC)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isHovered
                                ? const Color(0xFF2563EB).withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isHovered
                                  ? const Color(0xFF2563EB).withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: widget.isHovered ? 8 : 4,
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
                              widget.onNewSearch();
                              if (isFloatingMenu) {
                                widget.onMenuCollapse(true);
                              }
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) =>
                          setState(() => _isHedgeFundWizardHovered = true),
                      onExit: (_) =>
                          setState(() => _isHedgeFundWizardHovered = false),
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          final HSLColor hslColor = HSLColor.fromAHSL(
                            1.0,
                            _glowAnimation.value,
                            1.0,
                            0.7,
                          );
                          final Color glowColor = hslColor.toColor();

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isHedgeFundWizardHovered
                                  ? const Color(0xFFF8FAFC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isHedgeFundWizardHovered
                                    ? glowColor.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withOpacity(0.6),
                                  blurRadius:
                                      _isHedgeFundWizardHovered ? 15 : 10,
                                  spreadRadius:
                                      _isHedgeFundWizardHovered ? 4 : 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              if (isFloatingMenu) {
                                widget.onMenuCollapse(true);
                              }
                              context.go('/hedge-fund-wizard');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Text(
                                    'Hedge Fund Wizard',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  const SystemLightBulbWithRays(
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
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: WatchlistService().getWatchlist(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: const Text(
                              'Watchlist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final item = snapshot.data![index];
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  bool isWatchlistHovered = false;
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (_) => setState(
                                        () => isWatchlistHovered = true),
                                    onExit: (_) => setState(
                                        () => isWatchlistHovered = false),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isWatchlistHovered
                                            ? const Color(0xFFF8FAFC)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isWatchlistHovered
                                              ? const Color(0xFF2563EB)
                                                  .withOpacity(0.1)
                                              : Colors.black.withOpacity(0.05),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isWatchlistHovered
                                                ? const Color(0xFF2563EB)
                                                    .withOpacity(0.1)
                                                : Colors.black
                                                    .withOpacity(0.05),
                                            blurRadius:
                                                isWatchlistHovered ? 8 : 4,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          onTap: () {
                                            widget.onNavigateToReport(
                                                item['companyTicker'],
                                                item['companyName']);
                                            if (isFloatingMenu) {
                                              widget.onMenuCollapse(true);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF1F5F9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    item['companyTicker'],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        item['companyName'],
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Color(0xFF1E293B),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if (item['companyName']
                                                              .length >
                                                          30)
                                                        Text(
                                                          item['companyName'],
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: Color(
                                                                0xFF64748B),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                    size: 16,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  onPressed: () async {
                                                    try {
                                                      await WatchlistService()
                                                          .removeFromWatchlist(item[
                                                              'companyTicker']);
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Error removing from watchlist: $e'),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
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
                          const Divider(
                            height: 32,
                            indent: 16,
                            endIndent: 16,
                            color: Color(0xFFE2E8F0),
                          ),
                        ],
                      );
                    },
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.browseHistory.length,
                    itemBuilder: (context, index) {
                      final history = widget.browseHistory[index];
                      final timeAgo = _getTimeAgo(history.viewedDate);

                      return StatefulBuilder(
                        builder: (context, setState) {
                          bool isHistoryHovered = false;
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) =>
                                setState(() => isHistoryHovered = true),
                            onExit: (_) =>
                                setState(() => isHistoryHovered = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isHistoryHovered
                                    ? const Color(0xFFF8FAFC)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isHistoryHovered
                                      ? const Color(0xFF2563EB).withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isHistoryHovered
                                        ? const Color(0xFF2563EB)
                                            .withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: isHistoryHovered ? 8 : 4,
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
                                    widget.onNavigateToReport(
                                        history.companyTicker,
                                        history.companyName);
                                    if (isFloatingMenu) {
                                      widget.onMenuCollapse(true);
                                    }
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
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E293B),
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  history.companyTicker,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF64748B),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
