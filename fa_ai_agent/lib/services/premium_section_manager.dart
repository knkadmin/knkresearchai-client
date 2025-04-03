import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/subscription_type.dart';
import 'public_user_last_viewed_report_tracker.dart';
import '../widgets/blur_overlay.dart';
import '../result_advanced.dart';

/// Manages premium section access and visibility
class PremiumSectionManager {
  // Singleton instance
  static final PremiumSectionManager _instance =
      PremiumSectionManager._internal();
  factory PremiumSectionManager() => _instance;
  PremiumSectionManager._internal();

  // List of premium sections that require authentication or paid subscription
  List<String> get premiumSections => SectionConstants.premiumSectionNames;

  // List of sections that can be shown as preview with blur overlay
  final List<String> previewSections = [
    'Price Target',
  ];

  /// Checks if a section is premium
  bool isPremiumSection(String sectionTitle) {
    return premiumSections.contains(sectionTitle);
  }

  /// Checks if a section can be shown as preview
  bool isPreviewSection(String sectionTitle) {
    return previewSections.contains(sectionTitle);
  }

  /// Determines if a section should be shown with a blur overlay
  bool shouldShowBlurOverlay({
    required String sectionTitle,
    required bool isAuthenticated,
    required bool isMag7Company,
    required SubscriptionType? subscriptionType,
  }) {
    // Mag 7 companies always show all content without blur
    if (isMag7Company) {
      return false;
    }

    // Non-authenticated users see blur on premium sections and preview sections
    if (!isAuthenticated) {
      return isPremiumSection(sectionTitle) || isPreviewSection(sectionTitle);
    }

    // Authenticated users with free subscription see blur on premium sections and preview sections
    if (subscriptionType == SubscriptionType.free) {
      return isPremiumSection(sectionTitle) || isPreviewSection(sectionTitle);
    }

    // Authenticated users with paid subscription see all content
    return false;
  }

  /// Determines if a section should be shown at all
  bool shouldShowSection({
    required String sectionTitle,
    required bool isAuthenticated,
    required bool isMag7Company,
    required SubscriptionType? subscriptionType,
  }) {
    // Mag 7 companies always show all content
    if (isMag7Company) {
      return true;
    }

    // Show all sections that are either premium or preview
    return isPremiumSection(sectionTitle) || isPreviewSection(sectionTitle);
  }

  /// Builds a section with blur overlay for premium content
  Widget buildSectionWithBlurOverlay({
    required Widget sectionContent,
    required String sectionTitle,
    required bool isAuthenticated,
    required BuildContext context,
    required PublicUserLastViewedReportTracker cacheManager,
    VoidCallback? onActionPressed,
  }) {
    return Stack(
      children: [
        sectionContent,
        BlurOverlay(
          title: sectionTitle,
          isAuthenticated: isAuthenticated,
          onActionPressed: onActionPressed ??
              () {
                if (isAuthenticated) {
                  context.push('/pricing');
                } else {
                  cacheManager.pendingWatchlistAddition = true;
                  context.go('/signup');
                }
              },
        ),
      ],
    );
  }
}
