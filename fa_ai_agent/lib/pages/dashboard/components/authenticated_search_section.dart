import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/combined_search_news_card.dart';

class AuthenticatedSearchSection extends StatefulWidget {
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
  State<AuthenticatedSearchSection> createState() =>
      _AuthenticatedSearchSectionState();
}

class _AuthenticatedSearchSectionState extends State<AuthenticatedSearchSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _disclaimerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutExpo),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutExpo),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _disclaimerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isWideScreen = constraints.maxWidth > 1000;

                    return Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 1400 : 1100,
                      ),
                      child: CombinedSearchNewsCard(
                        searchController: widget.searchController,
                        searchFocusNode: widget.searchFocusNode,
                        onSearchChanged: widget.onSearchChanged,
                        onNavigateToReport: widget.onNavigateToReport,
                        searchResults: widget.searchResults,
                        onHideSearchResults: widget.onHideSearchResults,
                        searchCardKey: widget.searchCardKey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _disclaimerFadeAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.disclaimerText,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
