import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../models/section.dart';
import '../auth_service.dart';
import '../services/firestore_service.dart';
import 'package:rxdart/subjects.dart';

class SectionVisibilityManager {
  static final List<String> freeSections = [
    'Price Target',
    'Company Overview',
    'EPS vs Stock Price',
    'Financial Performance',
  ];

  static Future<List<Section>> filterSections(
    List<Section> sections,
    bool isAuthenticated,
    bool isMag7Company,
  ) async {
    // If it's a Mag 7 company, show all sections regardless of subscription
    if (isMag7Company) {
      return sections;
    }

    if (!isAuthenticated) {
      return sections
          .where((section) => freeSections.contains(section.title))
          .toList();
    }

    // For authenticated users, check their subscription status
    final user = AuthService().currentUser;
    if (user != null) {
      final firestoreService = FirestoreService();
      final userData = await firestoreService.getUserData(user.uid);

      // If user has a paid subscription, show all sections
      if (userData != null &&
          userData['subscription'] != null &&
          userData['subscription'] != 'free') {
        return sections;
      }

      // For free users, show only free sections
      return sections
          .where((section) => freeSections.contains(section.title))
          .toList();
    }

    return sections;
  }

  static Future<bool> isSectionVisible(
    String sectionTitle,
    bool isAuthenticated,
    bool isMag7Company,
  ) async {
    // If it's a Mag 7 company, show all sections regardless of subscription
    if (isMag7Company) {
      return true;
    }

    if (!isAuthenticated) {
      return freeSections.contains(sectionTitle);
    }

    // For authenticated users, check their subscription status
    final user = AuthService().currentUser;
    if (user != null) {
      final firestoreService = FirestoreService();
      final userData = await firestoreService.getUserData(user.uid);

      // If user has a paid subscription, show all sections
      if (userData != null &&
          userData['subscription'] != null &&
          userData['subscription'] != 'free') {
        return true;
      }

      // For free users, show only free sections
      return freeSections.contains(sectionTitle);
    }

    return false;
  }

  static Future<Widget> buildSectionContent(
    Section section,
    Widget sectionContent,
    bool isAuthenticated,
    bool isMag7Company,
    BuildContext context,
    String cacheKey,
    Stream<Map<String, bool>> loadingStateStream,
  ) async {
    final isVisible =
        await isSectionVisible(section.title, isAuthenticated, isMag7Company);

    if (!isVisible) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Starter Plan to access this section',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/pricing');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return sectionContent;
  }
}
