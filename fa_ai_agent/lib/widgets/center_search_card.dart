import 'package:flutter/material.dart';
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

class _CenterSearchCardState extends State<CenterSearchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _buttonAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 42,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Search for a US-listed Company',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter a company name or ticker symbol to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
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
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey[200],
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.grey[200],
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Popular Companies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<Map<String, String>>>(
              stream: CompanyData.streamMega7CompaniesForButtons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final companies = snapshot.data!;
                _buttonAnimations = List.generate(
                  companies.length,
                  (index) => CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      0.1 * index,
                      0.1 * index + 0.3,
                      curve: Curves.easeOut,
                    ),
                  ),
                );
                _animationController.forward();

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: companies.asMap().entries.map((entry) {
                    final index = entry.key;
                    final company = entry.value;
                    final symbol = company.keys.toList().first;
                    final name = company.values.toList().first;
                    return AnimatedBuilder(
                      animation: _buttonAnimations[index],
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              0, 20 * (1 - _buttonAnimations[index].value)),
                          child: Opacity(
                            opacity: _buttonAnimations[index].value,
                            child: child,
                          ),
                        );
                      },
                      child: CompanyButton(
                        name: name,
                        symbol: symbol,
                        onTap: () => widget.onNavigateToReport(symbol, name),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
