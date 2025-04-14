import 'package:flutter/material.dart';
import 'package:fa_ai_agent/models/section.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';
import 'package:fa_ai_agent/widgets/animations/tick_animation.dart';
import 'package:fa_ai_agent/widgets/animations/marquee_text.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:intl/intl.dart';

import 'package:fa_ai_agent/services/watchlist_service.dart';

class NavigationListContent extends StatelessWidget {
  final List<Section> sections;
  final String tickerCode;
  final String companyName;
  final ValueNotifier<String> currentSection;
  final ValueNotifier<bool> showCompanyNameInTitle;
  final Map<String, bool> sectionLoadingStates;
  final Map<String, ValueNotifier<bool>> tickAnimationStates;
  final Map<String, String> sectionToCacheKey;
  final Stream<dynamic> cacheTimeStream;
  final Function(String) onSectionTap;
  final Function() onRefresh;
  final Function() onWatch;
  final bool isHovered;
  final Stream<Map<String, bool>> loadingStateStream;
  final WatchlistService watchlistService;
  final ValueNotifier<bool> isRefreshing;

  const NavigationListContent({
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
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: showCompanyNameInTitle,
                  builder: (context, showCompanyName, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (AuthService().currentUser != null &&
                            showCompanyName)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade900,
                                    Colors.blue.shade800,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: MarqueeText(
                                      text: companyName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: StreamBuilder(
                                      stream: cacheTimeStream,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data != null) {
                                          return Text(
                                            'Report Generated: ${DateFormat('dd MMM yyyy').format(DateTime.fromMicrosecondsSinceEpoch(snapshot.data))}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (AuthService().currentUser != null &&
                            showCompanyName) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: StreamBuilder<bool>(
                                    stream: watchlistService
                                        .isInWatchlist(tickerCode),
                                    builder: (context, snapshot) {
                                      final isInWatchlist =
                                          snapshot.data ?? false;
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          bool isHovered = false;
                                          return MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            onEnter: (_) => setState(
                                                () => isHovered = true),
                                            onExit: (_) => setState(
                                                () => isHovered = false),
                                            child: _buildWatchButton(context,
                                                isHovered, isInWatchlist),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ValueListenableBuilder<bool>(
                                  valueListenable: showCompanyNameInTitle,
                                  builder: (context, showCompanyName, child) {
                                    return SizedBox(
                                      width: showCompanyName ? 32 : null,
                                      child: StatefulBuilder(
                                        builder: (context, setState) {
                                          bool isHovered = false;
                                          return MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            onEnter: (_) => setState(
                                                () => isHovered = true),
                                            onExit: (_) => setState(
                                                () => isHovered = false),
                                            child: showCompanyName
                                                ? ValueListenableBuilder<bool>(
                                                    valueListenable:
                                                        isRefreshing,
                                                    builder: (context,
                                                        isRefreshing, child) {
                                                      return IconButton(
                                                        onPressed: isRefreshing
                                                            ? null
                                                            : onRefresh,
                                                        icon: isRefreshing
                                                            ? const SizedBox(
                                                                width: 16,
                                                                height: 16,
                                                                child:
                                                                    ThinkingAnimation(
                                                                  size: 16,
                                                                  color: Color(
                                                                      0xFF1E3A8A),
                                                                ),
                                                              )
                                                            : Icon(
                                                                Icons.refresh,
                                                                size: 16,
                                                                color: isHovered
                                                                    ? Colors
                                                                        .white
                                                                    : const Color(
                                                                        0xFF1E3A8A),
                                                              ),
                                                        style: IconButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              isHovered
                                                                  ? const Color(
                                                                      0xFF1E3A8A)
                                                                  : Colors
                                                                      .white,
                                                          padding:
                                                              EdgeInsets.zero,
                                                          minimumSize:
                                                              const Size(
                                                                  32, 32),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            side: BorderSide(
                                                              color: isHovered
                                                                  ? const Color(
                                                                      0xFF1E3A8A)
                                                                  : const Color(
                                                                          0xFF1E3A8A)
                                                                      .withOpacity(
                                                                          0.2),
                                                              width: 1,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : _buildRefreshButton(
                                                    context, isHovered),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  tickerCode,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFF1E3A8A)
                                            .withOpacity(0.1),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                if (AuthService().currentUser != null) ...[
                                  const SizedBox(height: 4),
                                  StreamBuilder<bool>(
                                    stream: watchlistService
                                        .isInWatchlist(tickerCode),
                                    builder: (context, snapshot) {
                                      final isInWatchlist =
                                          snapshot.data ?? false;
                                      return SizedBox(
                                        width: double.infinity,
                                        child: StatefulBuilder(
                                          builder: (context, setState) {
                                            bool isHovered = false;
                                            return MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              onEnter: (_) => setState(
                                                  () => isHovered = true),
                                              onExit: (_) => setState(
                                                  () => isHovered = false),
                                              child: _buildWatchButton(context,
                                                  isHovered, isInWatchlist),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: StatefulBuilder(
                                    builder: (context, setState) {
                                      bool isHovered = false;
                                      return MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter: (_) =>
                                            setState(() => isHovered = true),
                                        onExit: (_) =>
                                            setState(() => isHovered = false),
                                        child: _buildRefreshButton(
                                            context, isHovered),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<Map<String, bool>>(
                stream: loadingStateStream,
                builder: (context, loadingSnapshot) {
                  final loadingStates = loadingSnapshot.data ?? {};
                  return ValueListenableBuilder<String>(
                    valueListenable: currentSection,
                    builder: (context, currentSection, child) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          final isActive = section.title == currentSection;
                          final cacheKey = sectionToCacheKey[section.title];
                          final isLoading = cacheKey != null &&
                              loadingStates[cacheKey] == true;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onSectionTap(section.title),
                              borderRadius: BorderRadius.circular(8),
                              hoverColor: Colors.grey.shade100,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: isActive
                                          ? const Color(0xFF1E3A8A)
                                          : Colors.blue.shade50,
                                      width: isActive ? 4 : 3,
                                    ),
                                  ),
                                  color: isActive
                                      ? Colors.blue.shade50.withOpacity(0.3)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      section.icon,
                                      size: isActive ? 18 : 16,
                                      color: isLoading
                                          ? Colors.grey.shade400
                                          : isActive
                                              ? const Color(0xFF1E3A8A)
                                              : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        section.title,
                                        style: TextStyle(
                                          fontSize: isActive ? 15 : 14,
                                          color: isLoading
                                              ? Colors.grey.shade400
                                              : isActive
                                                  ? const Color(0xFF1E3A8A)
                                                  : Colors.grey.shade700,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isLoading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: ThinkingAnimation(
                                          size: 16,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      )
                                    else if (cacheKey != null)
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            tickAnimationStates.putIfAbsent(
                                          cacheKey,
                                          () => ValueNotifier<bool>(false),
                                        ),
                                        builder: (context, showTick, child) {
                                          if (showTick) {
                                            return const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: TickAnimation(
                                                size: 16,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            );
                                          }
                                          return isActive
                                              ? Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFF1E3A8A),
                                                    shape: BoxShape.circle,
                                                  ),
                                                )
                                              : const SizedBox.shrink();
                                        },
                                      )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchButton(
      BuildContext context, bool isHovered, bool isInWatchlist) {
    return ElevatedButton.icon(
      onPressed: onWatch,
      icon: Icon(
        isInWatchlist ? Icons.check_circle : Icons.notifications_outlined,
        size: 16,
        color: isInWatchlist
            ? (isHovered ? Colors.white : const Color(0xFF1E3A8A))
            : Colors.white,
      ),
      label: Text(
        isInWatchlist ? 'In Watchlist' : 'Watch',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isInWatchlist
              ? (isHovered ? Colors.white : const Color(0xFF1E3A8A))
              : Colors.white,
        ),
      ),
      style: isInWatchlist
          ? (isHovered
              ? ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 1,
                    ),
                  ),
                )
              : ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: const Color(0xFF1E3A8A).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ))
          : ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1,
                ),
              ),
            ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, bool isHovered) {
    return ValueListenableBuilder<bool>(
      valueListenable: isRefreshing,
      builder: (context, isRefreshing, child) {
        return ElevatedButton.icon(
          onPressed: isRefreshing ? null : onRefresh,
          icon: isRefreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ThinkingAnimation(
                    size: 16,
                    color: Color(0xFF1E3A8A),
                  ),
                )
              : Icon(
                  Icons.refresh,
                  size: 16,
                  color: isHovered ? Colors.white : const Color(0xFF1E3A8A),
                ),
          label: Text(
            isRefreshing ? 'Refreshing...' : 'Refresh',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isHovered ? Colors.white : const Color(0xFF1E3A8A),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isHovered ? const Color(0xFF1E3A8A) : Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isHovered
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF1E3A8A).withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}
