import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/center_search_card.dart';

class AuthenticatedSearchSection extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearchChanged;
  final Function(String, String) onNavigateToReport;
  final List<Map<String, dynamic>> searchResults;
  final VoidCallback onHideSearchResults;
  final GlobalKey searchCardKey;
  final String disclaimerText;

  const AuthenticatedSearchSection({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onNavigateToReport,
    required this.searchResults,
    required this.onHideSearchResults,
    required this.searchCardKey,
    required this.disclaimerText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CenterSearchCard(
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            onSearchChanged: onSearchChanged,
            onNavigateToReport: onNavigateToReport,
            searchResults: searchResults,
            onHideSearchResults: onHideSearchResults,
            searchCardKey: searchCardKey,
          ),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              disclaimerText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
