import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';
import 'package:fa_ai_agent/services/watchlist_service.dart';
import 'package:intl/intl.dart';

class ReportStickyHeader extends StatelessWidget {
  final String tickerCode;
  final String companyName;
  final ValueNotifier<bool> showCompanyNameInTitle;
  final BehaviorSubject cacheTimeSubject;
  final WatchlistService watchlistService;
  final ValueNotifier<bool> isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onWatch;

  const ReportStickyHeader({
    super.key,
    required this.tickerCode,
    required this.companyName,
    required this.showCompanyNameInTitle,
    required this.cacheTimeSubject,
    required this.watchlistService,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: showCompanyNameInTitle,
              builder: (context, showCompanyName, child) {
                return AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: showCompanyName
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 40,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tickerCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  secondChild: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 45,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        StreamBuilder(
                          stream: cacheTimeSubject.stream,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Text(
                                'Report Generated: ${DateFormat('dd MMM yyyy').format(snapshot.data as DateTime)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Row(
              children: [
                StreamBuilder<bool>(
                  stream: watchlistService.isInWatchlist(tickerCode),
                  builder: (context, snapshot) {
                    final isInWatchlist = snapshot.data ?? false;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        bool isHovered = false;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => isHovered = true),
                          onExit: (_) => setState(() => isHovered = false),
                          child: ElevatedButton.icon(
                            onPressed: onWatch,
                            icon: Icon(
                              isInWatchlist
                                  ? Icons.check_circle
                                  : Icons.notifications_outlined,
                              size: 16,
                              color: isInWatchlist
                                  ? (isHovered
                                      ? Colors.white
                                      : const Color(0xFF1E3A8A))
                                  : Colors.white,
                            ),
                            label: Text(
                              isInWatchlist ? 'In Watchlist' : 'Watch',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isInWatchlist
                                    ? (isHovered
                                        ? Colors.white
                                        : const Color(0xFF1E3A8A))
                                    : Colors.white,
                              ),
                            ),
                            style: isInWatchlist
                                ? (isHovered
                                    ? ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1E3A8A),
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: const BorderSide(
                                            color: Color(0xFF1E3A8A),
                                            width: 1,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor:
                                            const Color(0xFF1E3A8A),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                            color: const Color(0xFF1E3A8A)
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                      ))
                                : ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: Color(0xFF1E3A8A),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 8),
                StatefulBuilder(
                  builder: (context, setState) {
                    bool isHovered = false;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isRefreshing,
                        builder: (context, isRefreshing, child) {
                          return IconButton(
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
                                    color: isHovered
                                        ? Colors.white
                                        : const Color(0xFF1E3A8A),
                                  ),
                            style: IconButton.styleFrom(
                              backgroundColor: isHovered
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.white,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(32, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isHovered
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFF1E3A8A)
                                          .withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
