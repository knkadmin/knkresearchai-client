import 'package:flutter/material.dart';
import 'package:fa_ai_agent/models/section.dart';
import 'package:fa_ai_agent/models/subscription_type.dart';
import 'package:fa_ai_agent/services/section_visibility_manager.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';

class ReportContentLayout extends StatelessWidget {
  final List<Section> sections;
  final bool isAuthenticated;
  final bool isMag7Company;
  final SubscriptionType? userSubscriptionType;
  final bool isNarrow;
  final Widget Function(Section) buildSection;
  final Widget Function(String) headerView;
  final Widget Function(bool) getMetricsTable;

  const ReportContentLayout({
    Key? key,
    required this.sections,
    required this.isAuthenticated,
    required this.isMag7Company,
    required this.userSubscriptionType,
    required this.isNarrow,
    required this.buildSection,
    required this.headerView,
    required this.getMetricsTable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isNarrow ? 24.0 : 264.0,
        right: 24.0,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final subscriptionType =
              userSubscriptionType ?? SubscriptionType.free;
          final shouldShowMetrics = isMag7Company ||
              (isAuthenticated && subscriptionType != SubscriptionType.free);

          return FutureBuilder<List<Section>>(
            future: SectionVisibilityManager.filterSections(
              sections,
              isAuthenticated,
              isMag7Company,
            ),
            builder: (context, sectionsSnapshot) {
              if (sectionsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: ThinkingAnimation());
              }

              final filteredSections = sectionsSnapshot.data ?? [];
              final contentSections = _buildContentSections(filteredSections);
              final accountingRedFlagsIndex = filteredSections
                  .indexWhere((s) => s.title == 'Accounting Red Flags');

              return Column(
                children: [
                  headerView(sections.first.title),
                  const SizedBox(height: 24),
                  _buildSectionsContainer(
                    contentSections,
                    accountingRedFlagsIndex,
                    shouldShowMetrics,
                    isNarrow,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildContentSections(List<Section> filteredSections) {
    return filteredSections
        .map((section) => buildSection(section))
        .where(
            (widget) => widget is! SizedBox || (widget as SizedBox).width != 0)
        .toList();
  }

  Widget _buildSectionsContainer(
    List<Widget> contentSections,
    int accountingRedFlagsIndex,
    bool shouldShowMetrics,
    bool isNarrow,
  ) {
    return Container(
      color: Colors.white,
      child: isNarrow
          ? _buildNarrowLayout(contentSections, shouldShowMetrics)
          : _buildWideLayout(
              contentSections,
              accountingRedFlagsIndex,
              shouldShowMetrics,
            ),
    );
  }

  Widget _buildNarrowLayout(
      List<Widget> contentSections, bool shouldShowMetrics) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shouldShowMetrics) ...[
            getMetricsTable(true),
            const SizedBox(height: 48),
          ],
          ...contentSections,
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    List<Widget> contentSections,
    int accountingRedFlagsIndex,
    bool shouldShowMetrics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contentSections.isNotEmpty) contentSections[0],
        const SizedBox(height: 8),
        _buildMainSections(
          contentSections,
          accountingRedFlagsIndex,
          shouldShowMetrics,
        ),
        if (accountingRedFlagsIndex >= 0)
          ...contentSections.skip(accountingRedFlagsIndex),
      ],
    );
  }

  Widget _buildMainSections(
    List<Widget> contentSections,
    int accountingRedFlagsIndex,
    bool shouldShowMetrics,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contentSections.length > 1) contentSections[1],
                const SizedBox(height: 48),
                if (contentSections.length > 2) contentSections[2],
                const SizedBox(height: 48),
                if (contentSections.length > 3) contentSections[3],
                const SizedBox(height: 48),
                if (accountingRedFlagsIndex > 4)
                  ...contentSections.skip(4).take(accountingRedFlagsIndex - 4),
              ],
            ),
          ),
          if (shouldShowMetrics) ...[
            const SizedBox(width: 24),
            SizedBox(
              width: 280,
              child: getMetricsTable(false),
            ),
          ],
        ],
      ),
    );
  }
}
