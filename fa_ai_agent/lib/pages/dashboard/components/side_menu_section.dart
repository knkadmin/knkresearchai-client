import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/side_menu.dart';
import 'package:fa_ai_agent/models/browse_history.dart';

class SideMenuSection extends StatelessWidget {
  final bool isMenuCollapsed;
  final bool isHovered;
  final Function(bool) onMenuCollapse;
  final Function(bool) onHoverChange;
  final VoidCallback onNewSearch;
  final Function(String, String) onNavigateToReport;
  final List<BrowseHistory> browseHistory;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> searchResults;
  final VoidCallback onHideSearchResults;

  const SideMenuSection({
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
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      left: isMenuCollapsed ? -280 : 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width < 850
          ? MediaQuery.of(context).size.width
          : 280,
      child: Stack(
        children: [
          if (MediaQuery.of(context).size.width < 850 && !isMenuCollapsed)
            GestureDetector(
              onTap: () => onMenuCollapse(true),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          SideMenu(
            isMenuCollapsed: isMenuCollapsed,
            isHovered: isHovered,
            onMenuCollapse: onMenuCollapse,
            onHoverChange: onHoverChange,
            onNewSearch: onNewSearch,
            onNavigateToReport: onNavigateToReport,
            browseHistory: browseHistory,
            searchController: searchController,
            searchResults: searchResults,
            onHideSearchResults: onHideSearchResults,
          ),
        ],
      ),
    );
  }
}
