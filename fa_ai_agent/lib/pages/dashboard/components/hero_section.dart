import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/center_search_card.dart';

class HeroSection extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearchChanged;
  final Function(String, String) onNavigateToReport;
  final List<Map<String, dynamic>> searchResults;
  final VoidCallback onHideSearchResults;
  final GlobalKey searchCardKey;
  final String disclaimerText;

  const HeroSection({
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/home.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 100),
          const Text(
            "AI-Powered Financial Analyst",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            height: 50,
            child: const Text(
              "Delivering in-depth research to empower informed investment decisions and optimize returns.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              elevation: 20,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: CenterSearchCard(
                  searchController: searchController,
                  searchFocusNode: searchFocusNode,
                  onSearchChanged: onSearchChanged,
                  onNavigateToReport: onNavigateToReport,
                  searchResults: searchResults,
                  onHideSearchResults: onHideSearchResults,
                  searchCardKey: searchCardKey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              disclaimerText,
              style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.7),
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
