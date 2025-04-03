import 'package:flutter/material.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:fa_ai_agent/models/section.dart';
import 'package:fa_ai_agent/widgets/navigation_list_content.dart';

class ReportNavigationOverlay extends StatelessWidget {
  final List<Section> sections;
  final String tickerCode;
  final String companyName;
  final ValueNotifier<String> currentSection;
  final ValueNotifier<bool> showCompanyNameInTitle;
  final Map<String, bool> sectionLoadingStates;
  final Map<String, ValueNotifier<bool>> tickAnimationStates;
  final Map<String, String> sectionToCacheKey;
  final Stream cacheTimeStream;
  final Function(String) onSectionTap;
  final VoidCallback onRefresh;
  final VoidCallback onWatch;
  final bool isHovered;
  final Stream<Map<String, bool>> loadingStateStream;
  final dynamic watchlistService;
  final ValueNotifier<bool> isRefreshing;

  const ReportNavigationOverlay({
    Key? key,
    required this.sections,
    required this.tickerCode,
    required this.companyName,
    required this.currentSection,
    required this.showCompanyNameInTitle,
    required this.sectionLoadingStates,
    required this.tickAnimationStates,
    required this.sectionToCacheKey,
    required this.cacheTimeStream,
    required this.onSectionTap,
    required this.onRefresh,
    required this.onWatch,
    required this.isHovered,
    required this.loadingStateStream,
    required this.watchlistService,
    required this.isRefreshing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: LayoutConstants.maxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isNarrow = constraints.maxWidth < 1000;
              if (isNarrow) return const SizedBox.shrink();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 280,
                      height: MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.only(right: 24),
                      child: NavigationListContent(
                        sections: sections,
                        tickerCode: tickerCode,
                        companyName: companyName,
                        currentSection: currentSection,
                        showCompanyNameInTitle: showCompanyNameInTitle,
                        sectionLoadingStates: sectionLoadingStates,
                        tickAnimationStates: tickAnimationStates,
                        sectionToCacheKey: sectionToCacheKey,
                        cacheTimeStream: cacheTimeStream,
                        onSectionTap: onSectionTap,
                        onRefresh: onRefresh,
                        onWatch: onWatch,
                        isHovered: isHovered,
                        loadingStateStream: loadingStateStream,
                        watchlistService: watchlistService,
                        isRefreshing: isRefreshing,
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
