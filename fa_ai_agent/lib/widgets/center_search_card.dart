import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../agent_service.dart';
import '../result_advanced.dart';
import 'company_button.dart';
import '../auth_service.dart';
import 'search_bar.dart' show CustomSearchBar;

class CenterSearchCard extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearchChanged;
  final Function(String, String) onNavigateToReport;
  final List<Map<String, dynamic>> searchResults;
  final Function() onHideSearchResults;
  final GlobalKey searchCardKey;

  const CenterSearchCard({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onNavigateToReport,
    required this.searchResults,
    required this.onHideSearchResults,
    required this.searchCardKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: Color(0xFF1E293B),
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
          CustomSearchBar(
            key: searchCardKey,
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            hintText: 'Search company or ticker...',
            onClear: () {
              searchController.clear();
              onHideSearchResults();
            },
            width: 600,
            showBorder: true,
            showShadow: false,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            AuthService().currentUser == null
                ? 'Quick Start with Mega 7 Companies for FREE'
                : 'Quick Start with Mega 7 Companies',
            style: const TextStyle(
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
                onTap: () => onNavigateToReport('GOOGL', 'Alphabet'),
              ),
              CompanyButton(
                name: 'Amazon',
                symbol: 'AMZN',
                onTap: () => onNavigateToReport('AMZN', 'Amazon'),
              ),
              CompanyButton(
                name: 'Apple',
                symbol: 'AAPL',
                onTap: () => onNavigateToReport('AAPL', 'Apple'),
              ),
              CompanyButton(
                name: 'Meta',
                symbol: 'META',
                onTap: () => onNavigateToReport('META', 'Meta'),
              ),
              CompanyButton(
                name: 'Microsoft',
                symbol: 'MSFT',
                onTap: () => onNavigateToReport('MSFT', 'Microsoft'),
              ),
              CompanyButton(
                name: 'Nvidia',
                symbol: 'NVDA',
                onTap: () => onNavigateToReport('NVDA', 'Nvidia'),
              ),
              CompanyButton(
                name: 'Tesla',
                symbol: 'TSLA',
                onTap: () => onNavigateToReport('TSLA', 'Tesla'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
