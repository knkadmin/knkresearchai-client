import 'package:fa_ai_agent/agent_service.dart';
import 'package:fa_ai_agent/main.dart';
import 'package:fa_ai_agent/widgets/dynamic_app_bar_title.dart';
import 'package:fa_ai_agent/models/section.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:fa_ai_agent/constants/company_data.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:rxdart/subjects.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_ai_agent/widgets/report_builder.dart';
import 'package:fa_ai_agent/widgets/chart_builder.dart';
import 'package:fa_ai_agent/widgets/thinking_animation.dart';
import 'package:fa_ai_agent/widgets/tick_animation.dart';
import 'package:fa_ai_agent/widgets/trading_view_chart.dart';
import 'package:fa_ai_agent/widgets/alert_report_builder.dart';
import 'package:fa_ai_agent/widgets/marquee_text.dart';
import 'package:fa_ai_agent/widgets/blur_overlay.dart';
import 'services/watchlist_service.dart';
import 'services/section_visibility_manager.dart';
import 'auth_service.dart';
import 'services/firestore_service.dart';
import 'models/subscription_type.dart';
import 'services/public_user_last_viewed_report_tracker.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class ResultAdvancedPage extends StatefulWidget {
  final String tickerCode;
  final String companyName;
  final Language language;
  final String sector;

  ResultAdvancedPage({
    super.key,
    required this.tickerCode,
    required this.companyName,
    required this.language,
    required this.sector,
  });

  final AgentService service = AgentService();
  final BehaviorSubject cacheTimeSubject = BehaviorSubject();
  final BehaviorSubject<String> sectorSubject = BehaviorSubject<String>();

  @override
  State<ResultAdvancedPage> createState() => _ResultAdvancedPageState();
}

class _ResultAdvancedPageState extends State<ResultAdvancedPage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<String> _currentSection = ValueNotifier<String>('');
  final PublicUserLastViewedReportTracker _cacheManager =
      PublicUserLastViewedReportTracker();
  late Future<bool> _isMag7CompanyFuture;
  final Map<String, Widget> _imageCache = {};
  final Map<String, String> _encodedImageCache = {};
  final Map<String, Widget> _sectionCache = {};
  final Map<String, Future<Map<String, dynamic>>> _futureCache = {};
  final Map<String, bool> _sectionLoadingStates = {};
  final ValueNotifier<bool> _showCompanyNameInTitle =
      ValueNotifier<bool>(false);
  final ValueNotifier<double> _navigationTop = ValueNotifier<double>(200);
  Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, ValueNotifier<bool>> _tickAnimationStates = {};
  final WatchlistService _watchlistService = WatchlistService();
  bool _isHovered = false;
  bool forceRefresh = false;

  StreamSubscription<String?>? _subscriptionSubscription;
  final ValueNotifier<String?> _subscriptionTypeNotifier =
      ValueNotifier<String?>(null);

  // Add mapping between section titles and their cache keys
  final Map<String, String> _sectionToCacheKey = {
    'Price Target': 'stock-price-target',
    'Company Overview': 'business-overview',
    'EPS vs Stock Price': 'eps-vs-stock-price-chart',
    'Financial Performance': 'combined-charts',
    'Accounting Red Flags': 'accounting-redflags',
    'Cash Flow': 'cash-flow-chart',
    'Recent News': 'recent-news',
    'Competitive Landscape': 'competitor-landscape',
    'Sector Stocks': 'sector-stocks',
    'Sector Comparison': 'sector-comparison',
    'PE/PB Ratio': 'pe-pb-ratio-band',
    'Supply Chain': 'supply-chain',
    'Industrial Relations': 'industrial-relationship',
    'Strategic Outlook': 'strategic-outlooks',
    'Insider Trading': 'insider-trading',
    'Shareholders': 'shareholder-chart',
    'Technical Analysis': 'candle-stick-chart',
  };

  late final List<Section> sections = [
    Section(
      title: 'Price Target',
      icon: Icons.trending_up,
      buildContent: () =>
          getStockPriceTarget(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Company Overview',
      icon: Icons.business,
      buildContent: () =>
          getBusinessOverview(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'EPS vs Stock Price',
      icon: Icons.compare_arrows,
      buildContent: () =>
          getEPSvsStockPriceChart(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Financial Performance',
      icon: Icons.assessment,
      buildContent: () =>
          getCombinedCharts(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Accounting Red Flags',
      icon: Icons.warning_amber_rounded,
      buildContent: () =>
          getAccountingRedFlags(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Cash Flow',
      icon: Icons.account_balance,
      buildContent: () =>
          getCashFlowChart(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Recent News',
      icon: Icons.newspaper,
      buildContent: () =>
          getRecentNews(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Competitive Landscape',
      icon: Icons.people,
      buildContent: () =>
          getCompetitorLandscape(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Sector Stocks',
      icon: Icons.category_outlined,
      buildContent: () =>
          getSectorStocksChart(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Sector Comparison',
      icon: Icons.compare_arrows,
      buildContent: () =>
          getSectorComparison(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'PE/PB Ratio',
      icon: Icons.analytics,
      buildContent: () =>
          getPEPBRatioBandChart(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Supply Chain',
      icon: Icons.linear_scale,
      buildContent: () =>
          getSupplyChain(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Industrial Relations',
      icon: Icons.handshake,
      buildContent: () =>
          getIndustrialRelationship(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Strategic Outlook',
      icon: Icons.visibility,
      buildContent: () =>
          getStrategicOutlooks(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Insider Trading',
      icon: Icons.swap_horiz,
      buildContent: () =>
          getInsiderTrading(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Shareholders',
      icon: Icons.pie_chart,
      buildContent: () =>
          getShareholderChart(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Technical Analysis',
      icon: Icons.candlestick_chart,
      buildContent: () =>
          getCandleStickChart(widget.tickerCode, widget.language.value),
    ),
  ];

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    analytics.logEvent(
        name: 'view_reports', parameters: {'ticker': widget.tickerCode});
    _scrollController.addListener(_onScroll);
    // Initialize section keys from sections list with unique keys
    _sectionKeys = {
      for (var section in sections)
        section.title:
            GlobalKey(debugLabel: '${widget.tickerCode}_${section.title}')
    };
    // Set initial section to the first one
    _currentSection.value = sections.first.title;
    widget.sectorSubject.add(widget.sector);

    // Initialize the Mag 7 company check future
    _isMag7CompanyFuture = _checkIfMag7Company();

    // Save last viewed report for non-authenticated users
    if (AuthService().currentUser == null) {
      _cacheManager.saveLastViewedReport(widget.tickerCode);
    }

    // Set up user data subscription
    final user = AuthService().currentUser;
    if (user != null) {
      _subscriptionSubscription =
          FirestoreService().streamUserSubscription(user.uid).listen((data) {
        if (mounted) {
          _subscriptionTypeNotifier.value = data;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _currentSection.dispose();
    widget.sectorSubject.close();
    _imageCache.clear();
    _sectionCache.clear();
    _futureCache.clear();
    _sectionLoadingStates.clear();
    for (var notifier in _tickAnimationStates.values) {
      notifier.dispose();
    }
    _tickAnimationStates.clear();

    _subscriptionSubscription?.cancel();
    _subscriptionTypeNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if we've scrolled past the header (using 100 as approximate header height threshold)
    if (_scrollController.offset > 100 && !_showCompanyNameInTitle.value) {
      _showCompanyNameInTitle.value = true;
    } else if (_scrollController.offset <= 100 &&
        _showCompanyNameInTitle.value) {
      _showCompanyNameInTitle.value = false;
    }

    // Calculate navigation position
    final scrollOffset = _scrollController.offset;
    final initialTop =
        400.0; // Initial top position (adjusted to align with first section)
    final stickyTop = 80.0; // Position when sticky (below app bar)

    if (scrollOffset > initialTop - stickyTop) {
      _navigationTop.value = stickyTop;
    } else {
      _navigationTop.value = initialTop - scrollOffset;
    }

    // Update current section based on scroll position
    for (final entry in _sectionKeys.entries) {
      final key = entry.key;
      final context = entry.value.currentContext;
      if (context != null) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        // Check if the section is in view
        if (position.dy <= 200 && position.dy + size.height > 200) {
          if (_currentSection.value != key) {
            _currentSection.value = key;
          }
          break;
        }
      }
    }
  }

  Widget _buildSection(Section section) {
    final user = AuthService().currentUser;
    final isAuthenticated = user != null;

    // Make all sections from Accounting Red Flags onwards full width
    final bool isFullWidth = sections.indexOf(section) >=
        sections.indexWhere((s) => s.title == 'Accounting Red Flags');

    Widget sectionContent = Column(
      key: _sectionKeys[section.title],
      children: [
        if (isFullWidth)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: section.buildContent(),
          )
        else
          section.buildContent(),
        const SizedBox(height: 48),
      ],
    );

    return FutureBuilder<bool>(
      future: _isMag7CompanyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final isMag7Company = snapshot.data ?? false;

        return StreamBuilder<bool>(
          stream: SectionVisibilityManager.streamSectionVisibility(
            section.title,
            isAuthenticated,
            isMag7Company,
          ),
          builder: (context, visibilitySnapshot) {
            if (visibilitySnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<SubscriptionType>(
              future: _getCurrentUserSubscription(),
              builder: (context, subscriptionSnapshot) {
                if (subscriptionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final subscriptionType =
                    subscriptionSnapshot.data ?? SubscriptionType.free;

                if (!isMag7Company &&
                    (!isAuthenticated ||
                        subscriptionType == SubscriptionType.free)) {
                  // For Price Target and Financial Performance, show blur cover with action button
                  if (section.title == 'Price Target' ||
                      section.title == 'Financial Performance') {
                    return Stack(
                      children: [
                        sectionContent,
                        BlurOverlay(
                          title: section.title,
                          isAuthenticated: isAuthenticated,
                          onActionPressed: () {
                            if (isAuthenticated) {
                              context.push('/pricing');
                            } else {
                              _cacheManager.pendingWatchlistAddition = true;
                              context.go('/signup');
                            }
                          },
                        ),
                      ],
                    );
                  }
                  return sectionContent;
                }

                return sectionContent;
              },
            );
          },
        );
      },
    );
  }

  Widget getMetricsTable(bool isNarrow) {
    final cachedMetricsTable = _sectionCache['financialMetrics'];
    if (cachedMetricsTable == null) {
      _sectionCache['financialMetrics'] = getFinancialMetrics(
        widget.tickerCode,
        widget.language.value,
      );
    }
    return SizedBox(
      width: isNarrow ? double.infinity : 280,
      child: _sectionCache['financialMetrics'] ?? const SizedBox.shrink(),
    );
  }

  void _scrollToSection(String sectionTitle) {
    final key = _sectionKeys[sectionTitle];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleRefresh() async {
    setState(() {
      _sectionLoadingStates.clear();
      for (var notifier in _tickAnimationStates.values) {
        notifier.dispose();
      }
      _tickAnimationStates.clear();
      _futureCache.clear(); // Clear the future cache to force new requests
      _imageCache.clear(); // Clear image cache
      _encodedImageCache.clear(); // Clear encoded image cache
      _sectionCache.clear(); // Clear section cache
      forceRefresh = true; // Set force refresh flag
    });
  }

  Widget _buildRefreshButton(bool isHovered) {
    return StreamBuilder<Map<String, bool>>(
      stream: widget.service.loadingStateSubject.stream,
      builder: (context, snapshot) {
        final loadingStates = snapshot.data ?? {};
        final isAnySectionLoading =
            loadingStates.values.any((isLoading) => isLoading);
        final isRefreshing = isAnySectionLoading;

        return StatefulBuilder(
          builder: (context, setState) {
            bool isHovered = false;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => isHovered = true),
              onExit: (_) => setState(() => isHovered = false),
              child: ValueListenableBuilder<bool>(
                valueListenable: _showCompanyNameInTitle,
                builder: (context, showCompanyName, child) {
                  return SizedBox(
                    width: showCompanyName ? 32 : null,
                    child: showCompanyName
                        ? ElevatedButton(
                            onPressed: isRefreshing ? null : _handleRefresh,
                            style: isHovered
                                ? _getHoverButtonStyle().copyWith(
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.all(0),
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                      const Size(32, 40),
                                    ),
                                  )
                                : _getButtonStyle().copyWith(
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.all(0),
                                    ),
                                    minimumSize: MaterialStateProperty.all(
                                      const Size(32, 40),
                                    ),
                                  ),
                            child: isRefreshing
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
                          )
                        : ElevatedButton.icon(
                            onPressed: isRefreshing ? null : _handleRefresh,
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
                            label: Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isHovered
                                    ? Colors.white
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                            style: isHovered
                                ? _getHoverButtonStyle().copyWith(
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  )
                                : _getButtonStyle().copyWith(
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                    ),
                                  ),
                          ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavigationList(List<Section> sections) {
    final user = AuthService().currentUser;
    final isAuthenticated = user != null;

    return FutureBuilder<bool>(
      future: _isMag7CompanyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final isMag7Company = snapshot.data ?? false;

        return FutureBuilder<List<Section>>(
          future: SectionVisibilityManager.filterSections(
            sections,
            isAuthenticated,
            isMag7Company,
          ),
          builder: (context, sectionsSnapshot) {
            if (sectionsSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final visibleSections = sectionsSnapshot.data ?? [];
            return _buildNavigationListContent(visibleSections);
          },
        );
      },
    );
  }

  Widget _buildNavigationListContent(List<Section> sections) {
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
                  valueListenable: _showCompanyNameInTitle,
                  builder: (context, showCompanyName, child) {
                    return SizedBox(
                      height: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (AuthService().currentUser != null &&
                              showCompanyName)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
                                        text: widget.companyName,
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
                                        stream: widget.cacheTimeSubject.stream,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Text(
                                              'Report Generated: ${DateFormat('dd MMM yyyy').format(snapshot.data)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.8),
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
                          SizedBox(
                              height: AuthService().currentUser != null &&
                                      showCompanyName
                                  ? 12
                                  : 0),
                          if (AuthService().currentUser != null &&
                              showCompanyName)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: StatefulBuilder(
                                      builder: (context, setState) {
                                        bool isHovered = false;
                                        return MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          onEnter: (_) =>
                                              setState(() => isHovered = true),
                                          onExit: (_) =>
                                              setState(() => isHovered = false),
                                          child: _buildWatchButton(),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _showCompanyNameInTitle,
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
                                              child: _buildRefreshButton(
                                                  isHovered),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.tickerCode,
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
                                    SizedBox(
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
                                            child: _buildWatchButton(),
                                          );
                                        },
                                      ),
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
                                          child: _buildRefreshButton(isHovered),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<Map<String, bool>>(
                stream: widget.service.loadingStateSubject.stream,
                builder: (context, loadingSnapshot) {
                  final loadingStates = loadingSnapshot.data ?? {};
                  return ValueListenableBuilder<String>(
                    valueListenable: _currentSection,
                    builder: (context, currentSection, child) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          final isActive = section.title == currentSection;
                          final cacheKey = _sectionToCacheKey[section.title];
                          final isLoading = cacheKey != null &&
                              loadingStates[cacheKey] == true;

                          // Handle loading state changes
                          if (cacheKey != null) {
                            final wasLoading =
                                _sectionLoadingStates[cacheKey] ?? false;
                            if (wasLoading && !isLoading) {
                              // Get or create the ValueNotifier for this section
                              final tickNotifier =
                                  _tickAnimationStates.putIfAbsent(
                                cacheKey,
                                () => ValueNotifier<bool>(false),
                              );

                              // Show tick animation
                              tickNotifier.value = true;

                              // Hide tick after animation
                              Future.delayed(const Duration(milliseconds: 800),
                                  () {
                                if (mounted) {
                                  tickNotifier.value = false;
                                }
                              });
                            }
                            _sectionLoadingStates[cacheKey] = isLoading;
                          }

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _scrollToSection(section.title),
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
                                            _tickAnimationStates.putIfAbsent(
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isAuthenticated = user != null;

    return ValueListenableBuilder<String?>(
      valueListenable: _subscriptionTypeNotifier,
      builder: (context, subscriptionType, child) {
        return FutureBuilder<bool>(
          future: _isMag7CompanyFuture,
          builder: (context, mag7Snapshot) {
            if (mag7Snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: ThinkingAnimation());
            }

            final isMag7Company = mag7Snapshot.data ?? false;
            return _buildScaffold(
                sections, isAuthenticated, isMag7Company, subscriptionType);
          },
        );
      },
    );
  }

  Widget _buildScaffold(List<Section> sections, bool isAuthenticated,
      bool isMag7Company, String? userSubscriptionType) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: LayoutConstants.maxWidth),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool isNarrow = constraints.maxWidth < 1000;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: isNarrow ? 24.0 : 264.0,
                        right: 24.0,
                      ),
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          // Use cached user data instead of stream
                          final subscriptionType = SubscriptionType.fromString(
                              userSubscriptionType ?? 'free');

                          // Determine if metrics table should be shown
                          final shouldShowMetrics = isMag7Company ||
                              (isAuthenticated &&
                                  subscriptionType != SubscriptionType.free);

                          print('Metrics visibility check:');
                          print('isMag7Company: $isMag7Company');
                          print('isAuthenticated: $isAuthenticated');
                          print('subscriptionType: $subscriptionType');
                          print('shouldShowMetrics: $shouldShowMetrics');

                          return FutureBuilder<List<Section>>(
                            future: SectionVisibilityManager.filterSections(
                              sections,
                              isAuthenticated,
                              isMag7Company,
                            ),
                            builder: (context, sectionsSnapshot) {
                              if (sectionsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(child: ThinkingAnimation());
                              }

                              final filteredSections =
                                  sectionsSnapshot.data ?? [];
                              final contentSections = filteredSections
                                  .map((section) => _buildSection(section))
                                  .where((widget) =>
                                      widget is! SizedBox ||
                                      (widget as SizedBox).width != 0)
                                  .toList();

                              // Find the index of Accounting Red Flags section
                              final accountingRedFlagsIndex =
                                  filteredSections.indexWhere(
                                      (s) => s.title == 'Accounting Red Flags');

                              return Column(
                                children: [
                                  headerView(widget.companyName),
                                  const SizedBox(height: 24),
                                  Container(
                                    color: Colors.white,
                                    child: isNarrow
                                        ? Padding(
                                            padding: const EdgeInsets.all(32),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (shouldShowMetrics) ...[
                                                  getMetricsTable(isNarrow),
                                                  const SizedBox(height: 48),
                                                ],
                                                ...contentSections,
                                              ],
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (contentSections.isNotEmpty)
                                                contentSections[0],
                                              const SizedBox(height: 8),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 32),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (contentSections
                                                                  .length >
                                                              1)
                                                            contentSections[1],
                                                          const SizedBox(
                                                              height: 48),
                                                          if (contentSections
                                                                  .length >
                                                              2)
                                                            contentSections[2],
                                                          const SizedBox(
                                                              height: 48),
                                                          if (contentSections
                                                                  .length >
                                                              3)
                                                            contentSections[3],
                                                          const SizedBox(
                                                              height: 48),
                                                          // First four sections are in the left column
                                                          if (accountingRedFlagsIndex >
                                                              4)
                                                            ...contentSections
                                                                .skip(4)
                                                                .take(
                                                                    accountingRedFlagsIndex -
                                                                        4),
                                                        ],
                                                      ),
                                                    ),
                                                    if (shouldShowMetrics) ...[
                                                      const SizedBox(width: 24),
                                                      SizedBox(
                                                        width: 280,
                                                        child: getMetricsTable(
                                                            isNarrow),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              // Sections from Accounting Red Flags onwards are full width
                                              if (accountingRedFlagsIndex >= 0)
                                                ...contentSections.skip(
                                                    accountingRedFlagsIndex),
                                            ],
                                          ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: LayoutConstants.maxWidth),
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
                            child: _buildNavigationListContent(sections),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget headerView(String companyName) {
    return StreamBuilder(
        stream: widget.cacheTimeSubject.stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          final user = AuthService().currentUser;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade800,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    companyName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                StreamBuilder<String>(
                                  stream: widget.sectorSubject.stream,
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        snapshot.data!,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (snapshot.hasData)
                      SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Report Generated",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM, yyyy').format(snapshot.data),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.language == Language.english
                      ? "KNK Research - Comprehensive Financial Analysis Report"
                      : "KNK Research - 综合财务分析报告",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget getBusinessOverview(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'businessOverview',
            () => widget.service
                .getBusinessOverview(ticker, language, forceRefresh)),
        "Company Overview",
        "businessOverview");
  }

  Widget getEPSvsStockPriceChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'epsVsStockPriceChart',
            () => widget.service
                .getEPSvsStockPriceChart(ticker, language, forceRefresh)),
        'epsVsStockPriceChart',
        title: 'EPS vs Stock Price');
  }

  Widget getFinancialMetrics(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'financialMetrics',
            () => widget.service
                .getFinancialMetrics(ticker, language, forceRefresh)),
        "Financial Metrics",
        "financialMetrics",
        showTitle: false);
  }

  Widget getReport(
      Future<Map<String, dynamic>> future, String title, String key,
      {bool showTitle = true}) {
    return ReportBuilder(
      future: future,
      title: title,
      reportKey: key,
      showTitle: showTitle,
      onCacheTimeUpdate: (DateTime cacheTime) {
        widget.cacheTimeSubject.add(cacheTime);
      },
    );
  }

  Widget getFinancialPerformance(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'financialPerformance',
            () => widget.service
                .getFinancialPerformance(ticker, language, forceRefresh)),
        "Financial Performance",
        "financialReport");
  }

  Widget getCompetitorLandscape(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'competitorLandscape',
            () => widget.service
                .getCompetitorLandscape(ticker, language, forceRefresh)),
        "Competitive Landscape",
        "competitorReport");
  }

  Widget getSupplyChain(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'supplyChain',
            () =>
                widget.service.getSupplyChain(ticker, language, forceRefresh)),
        "Supply Chain Feedbacks",
        "supplyChainReport");
  }

  Widget getStrategicOutlooks(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'strategicOutlooks',
            () => widget.service
                .getStrategicOutlooks(ticker, language, forceRefresh)),
        "Strategic Outlooks",
        "strategicOutlooksReport");
  }

  Widget getRecentNews(String ticker, String language) {
    return getReport(
        _getCachedFuture('recentNews',
            () => widget.service.getRecentNews(ticker, language, forceRefresh)),
        "Recent News",
        "recentNews");
  }

  Widget getStockPriceTarget(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'stockPriceTarget',
            () => widget.service
                .getStockPriceTarget(ticker, language, forceRefresh)),
        'stockPriceTarget',
        title: 'Price Target',
        showTitle: false);
  }

  Widget getInsiderTrading(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'insiderTrading',
            () => widget.service
                .getInsiderTrading(ticker, language, forceRefresh)),
        'insiderTrading',
        title: 'Insider Trading');
  }

  Widget getPEPBRatioBandChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'pbRatioBand',
            () => widget.service
                .getPEPBRatioBand(ticker, language, forceRefresh)),
        'pbRatioBand',
        title: 'PE/PB Ratio');
  }

  Widget getSectorStocksChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'sectorStocks',
            () =>
                widget.service.getSectorStocks(ticker, language, forceRefresh)),
        'sectorStocks',
        title: 'Sector Stocks');
  }

  Widget getCandleStickChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'candleStickChart',
            () => widget.service
                .getCandleStickChart(ticker, language, forceRefresh)),
        'candleStickChart',
        title: 'Technical Analysis');
  }

  Widget getCombinedCharts(String ticker, String language) {
    return Column(
      children: [
        getChart(
          _getCachedFuture(
              'combinedCharts',
              () => widget.service
                  .getCombinedCharts(ticker, language, forceRefresh)),
          'combinedCharts',
          title: 'Financial Performance',
        ),
        const SizedBox(height: 24),
        getReport(
          _getCachedFuture(
              'financialPerformance',
              () => widget.service
                  .getFinancialPerformance(ticker, language, forceRefresh)),
          "Financial Performance",
          "financialReport",
          showTitle: false,
        ),
      ],
    );
  }

  Widget getCashFlowChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'cashFlowChart',
            () => widget.service
                .getCashFlowChart(ticker, language, forceRefresh)),
        'cashFlowChart',
        title: 'Cash Flow');
  }

  Widget getIndustrialRelationship(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'industrialRelationship',
            () => widget.service
                .getIndustrialRelationship(ticker, language, forceRefresh)),
        'industrialRelationship',
        title: 'Industrial Relations');
  }

  Widget getSectorComparison(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'sectorComparison',
            () => widget.service
                .getSectorComparison(ticker, language, forceRefresh)),
        'sectorComparison',
        title: 'Sector Comparison');
  }

  Widget getShareholderChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'shareholderChart',
            () => widget.service
                .getShareholderChart(ticker, language, forceRefresh)),
        'shareholderChart',
        title: 'Shareholders');
  }

  Widget getChart(Future<Map<String, dynamic>> future, String key,
      {required String title, bool showTitle = true}) {
    return ChartBuilder(
      future: future,
      chartKey: key,
      cachedImage: (!forceRefresh && _imageCache.containsKey(key))
          ? _imageCache[key]
          : null,
      cachedEncodedImage: (!forceRefresh && _encodedImageCache.containsKey(key))
          ? _encodedImageCache[key]
          : null,
      onImageCached: (Widget image, String encodedImage) {
        _imageCache[key] = image;
        _encodedImageCache[key] = encodedImage;
      },
      title: title,
      showTitle: showTitle,
    );
  }

  Future<Map<String, dynamic>> _getCachedFuture(
      String key, Future<Map<String, dynamic>> Function() createFuture) {
    if (!_futureCache.containsKey(key)) {
      _futureCache[key] = createFuture();
    }
    return _futureCache[key]!;
  }

  Widget getTradingViewChart(String ticker, String companyName) {
    return TradingViewChart(
      tickerSymbol: ticker,
      companyName: companyName,
    );
  }

  Widget getAccountingRedFlags(String ticker, String language) {
    return AlertReportBuilder(
      future: _getCachedFuture(
          'accountingRedFlags',
          () => widget.service
              .getAccountingRedFlags(ticker, language, forceRefresh)),
      title: "Accounting Red Flags",
      reportKey: "accountingRedflags",
      onCacheTimeUpdate: (DateTime cacheTime) {
        widget.cacheTimeSubject.add(cacheTime);
      },
    );
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E3A8A),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          width: 1,
        ),
      ),
    );
  }

  ButtonStyle _getHoverButtonStyle() {
    return ElevatedButton.styleFrom(
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
    );
  }

  Widget _buildWatchButton() {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<bool>(
      stream: _watchlistService.isInWatchlist(widget.tickerCode),
      builder: (context, snapshot) {
        final isInWatchlist = snapshot.data ?? false;

        return ElevatedButton.icon(
          onPressed: () async {
            try {
              if (isInWatchlist) {
                await _watchlistService.removeFromWatchlist(widget.tickerCode);
              } else {
                await _watchlistService.addToWatchlist(
                  companyName: widget.companyName,
                  companyTicker: widget.tickerCode,
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: Icon(
            isInWatchlist ? Icons.check_circle : Icons.notifications_outlined,
            size: 16,
            color: isInWatchlist
                ? (_isHovered ? Colors.white : const Color(0xFF1E3A8A))
                : Colors.white,
          ),
          label: Text(
            isInWatchlist ? 'In Watchlist' : 'Watch',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isInWatchlist
                  ? (_isHovered ? Colors.white : const Color(0xFF1E3A8A))
                  : Colors.white,
            ),
          ),
          style: isInWatchlist
              ? (_isHovered ? _getHoverButtonStyle() : _getButtonStyle())
              : ElevatedButton.styleFrom(
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
                ),
        );
      },
    );
  }

  Future<bool> _checkIfMag7Company() async {
    try {
      final companies = await CompanyData.getMega7Companies();
      return companies
          .any((company) => company.keys.first == widget.tickerCode);
    } catch (e) {
      print('Error checking if company is Mag 7: $e');
      return false;
    }
  }

  Future<SubscriptionType> _getCurrentUserSubscription() async {
    final user = AuthService().currentUser;
    if (user == null) return SubscriptionType.free;

    try {
      final userData = await FirestoreService().getUserProfile();
      return SubscriptionType.fromString(userData?['subscription'] ?? 'free');
    } catch (e) {
      print('Error getting user subscription: $e');
      return SubscriptionType.free;
    }
  }
}
