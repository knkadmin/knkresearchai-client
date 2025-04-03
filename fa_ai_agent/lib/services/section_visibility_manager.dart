import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../models/section.dart';
import '../models/subscription_type.dart';
import '../auth_service.dart';
import '../services/firestore_service.dart';
import 'package:rxdart/subjects.dart';
import '../services/premium_section_manager.dart';

class SectionVisibilityManager {
  static final List<String> freeSections = [
    'Company Overview',
  ];

  static final PremiumSectionManager _premiumSectionManager =
      PremiumSectionManager();

  /// Helper method to check if a user has access to all sections
  static Future<bool> _hasFullAccess(String? userId, bool isMag7Company) async {
    // If it's a Mag 7 company, always return true regardless of user status
    if (isMag7Company) return true;

    // For non-authenticated users, return false
    if (userId == null) return false;

    // For authenticated users, check subscription
    final userData = await FirestoreService().getUserData(userId);
    final subscriptionType =
        SubscriptionType.fromString(userData?['subscription']);
    return subscriptionType.isPaid;
  }

  static Future<List<Section>> filterSections(
    List<Section> sections,
    bool isAuthenticated,
    bool isMag7Company,
  ) async {
    final user = AuthService().currentUser;
    final hasAccess = await _hasFullAccess(user?.uid, isMag7Company);

    if (hasAccess) {
      return sections;
    }

    // For both non-authenticated and free users, show free sections and preview sections
    return sections.where((section) {
      if (freeSections.contains(section.title)) return true;
      return _premiumSectionManager.isPreviewSection(section.title);
    }).toList();
  }

  static Future<bool> isSectionVisible(
    String sectionTitle,
    bool isAuthenticated,
    bool isMag7Company,
  ) async {
    final user = AuthService().currentUser;
    final hasAccess = await _hasFullAccess(user?.uid, isMag7Company);

    if (hasAccess) {
      return true;
    }

    // For both non-authenticated and free users, check if section is free or preview
    return freeSections.contains(sectionTitle) ||
        _premiumSectionManager.isPreviewSection(sectionTitle);
  }

  // Stream section visibility changes
  static Stream<bool> streamSectionVisibility(
    String sectionTitle,
    bool isAuthenticated,
    bool isMag7Company,
  ) {
    // If it's a Mag 7 company, always return true regardless of user status
    if (isMag7Company) return Stream.value(true);

    final user = AuthService().currentUser;
    if (user == null) {
      return Stream.value(freeSections.contains(sectionTitle) ||
          _premiumSectionManager.isPreviewSection(sectionTitle));
    }

    final firestoreService = FirestoreService();
    return firestoreService.streamUserData(user.uid).map((userData) {
      final subscriptionType =
          SubscriptionType.fromString(userData?['subscription']);
      if (subscriptionType.isPaid) return true;

      return freeSections.contains(sectionTitle) ||
          _premiumSectionManager.isPreviewSection(sectionTitle);
    });
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
