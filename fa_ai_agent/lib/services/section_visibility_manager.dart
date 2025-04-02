import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../models/section.dart';
import '../models/subscription_type.dart';
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

  /// Helper method to check if a user has access to all sections
  static Future<bool> _hasFullAccess(String? userId, bool isMag7Company) async {
    // If it's a Mag 7 company, always grant full access
    if (isMag7Company) {
      return true;
    }

    // If no user ID (non-authenticated) or no user data (free user), return false
    if (userId == null) {
      return false;
    }

    // Check user's subscription status
    final firestoreService = FirestoreService();
    final userData = await firestoreService.getUserData(userId);

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

    // For both non-authenticated and free users, show only free sections
    return sections
        .where((section) => freeSections.contains(section.title))
        .toList();
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

    // For both non-authenticated and free users, check if section is free
    return freeSections.contains(sectionTitle);
  }

  // Stream section visibility changes
  static Stream<bool> streamSectionVisibility(
    String sectionTitle,
    bool isAuthenticated,
    bool isMag7Company,
  ) {
    final user = AuthService().currentUser;
    if (user == null) {
      return Stream.value(freeSections.contains(sectionTitle));
    }

    final firestoreService = FirestoreService();
    return firestoreService.streamUserData(user.uid).map((userData) {
      if (isMag7Company) return true;

      final subscriptionType =
          SubscriptionType.fromString(userData?['subscription']);
      if (subscriptionType.isPaid) return true;

      return freeSections.contains(sectionTitle);
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
