import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../models/section.dart';

class SectionVisibilityManager {
  static const List<String> freeSections = [
    'Price Target',
    'Company Overview',
    'Financial Metrics',
    'Financial Performance'
  ];

  static List<Section> filterSections(
      List<Section> sections, bool isAuthenticated, bool isMag7Company) {
    if (isMag7Company) {
      return sections;
    }

    if (isAuthenticated) {
      return sections;
    }

    return sections
        .where((section) => freeSections.contains(section.title))
        .toList();
  }

  static bool isSectionVisible(
      String sectionTitle, bool isAuthenticated, bool isMag7Company) {
    if (isMag7Company) {
      return true;
    }

    if (isAuthenticated) {
      return true;
    }

    return freeSections.contains(sectionTitle);
  }

  static Widget buildSectionContent(
    Section section,
    Widget sectionContent,
    bool isAuthenticated,
    bool isMag7Company,
    BuildContext context,
    String cacheKey,
    Stream<Map<String, bool>> loadingStateStream,
  ) {
    if (isMag7Company || isAuthenticated) {
      return sectionContent;
    }

    if (section.title == 'Financial Performance') {
      return StreamBuilder<Map<String, bool>>(
        stream: loadingStateStream,
        builder: (context, snapshot) {
          final loadingStates = snapshot.data ?? {};
          final isLoading = cacheKey != null && loadingStates[cacheKey] == true;

          if (isLoading) {
            return sectionContent;
          }

          return Stack(
            children: [
              IgnorePointer(
                child: sectionContent,
              ),
              Positioned.fill(
                child: Stack(
                  children: [
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(),
                      ),
                    ),
                    Container(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Unlock Premium Insights',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Get access to detailed analysis and exclusive content',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => context.go('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Sign Up Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return sectionContent;
  }
}
