import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fa_ai_agent/services/agent_service.dart';
import '../result_advanced.dart';
import 'company_button.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import 'search_bar.dart' show CustomSearchBar;
import '../constants/company_data.dart';

class CenterSearchCard extends StatefulWidget {
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
  State<CenterSearchCard> createState() => _CenterSearchCardState();
}

class _CenterSearchCardState extends State<CenterSearchCard> {
  List<Map<String, String>> _mega7Companies = [];

  @override
  void initState() {
    super.initState();
    _loadMega7Companies();
  }

  Future<void> _loadMega7Companies() async {
    final companies = await CompanyData.getMega7CompaniesForButtons();
    if (mounted) {
      setState(() {
        _mega7Companies = companies;
      });
    }
  }

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
            key: widget.searchCardKey,
            controller: widget.searchController,
            focusNode: widget.searchFocusNode,
            onChanged: widget.onSearchChanged,
            hintText: 'Search company or ticker...',
            onClear: () {
              widget.searchController.clear();
              widget.onHideSearchResults();
            },
            width: 600,
            showBorder: true,
            showShadow: false,
          ),
          if (AuthService().currentUser != null) ...[
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
            const Text(
              'Quick Start with Mag 7 Companies',
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
              children: _mega7Companies.map((company) {
                final symbol = company.keys.toList().first;
                final name = company.values.toList().first;
                return CompanyButton(
                  name: name,
                  symbol: symbol,
                  onTap: () => widget.onNavigateToReport(symbol, name),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
