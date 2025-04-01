import 'package:fa_ai_agent/agent_service.dart';
import 'package:fa_ai_agent/main.dart';
import 'package:fa_ai_agent/widgets/dynamic_app_bar_title.dart';
import 'package:fa_ai_agent/models/section.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
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
import 'services/watchlist_service.dart';
import 'auth_service.dart';

class ResultAdvancedPage extends StatefulWidget {
  ResultAdvancedPage({
    super.key,
    required this.tickerCode,
    required this.companyName,
    required this.language,
    required this.sector,
  });

  final String tickerCode;
  final String companyName;
  final String sector;
  final Language language;
  final AgentService service = AgentService();
  final BehaviorSubject cacheTimeSubject = BehaviorSubject();
  final BehaviorSubject<String> sectorSubject = BehaviorSubject<String>();

  @override
  State<ResultAdvancedPage> createState() => _ResultAdvancedPageState();
}

class _ResultAdvancedPageState extends State<ResultAdvancedPage> {
  bool forceRefresh = false;
  bool _isRefreshing = false;
  Widget? _cachedMetricsTable;
  final Map<String, Widget> _imageCache = {};
  final Map<String, String> _encodedImageCache = {};
  final Map<String, Widget> _sectionCache = {};
  final Map<String, Future<Map<String, dynamic>>> _futureCache = {};
  final Map<String, bool> _sectionLoadingStates = {};
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showCompanyNameInTitle =
      ValueNotifier<bool>(false);
  final ValueNotifier<double> _navigationTop = ValueNotifier<double>(200);
  final ValueNotifier<String> _currentSection = ValueNotifier<String>('');
  Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, ValueNotifier<bool>> _tickAnimationStates = {};
  final WatchlistService _watchlistService = WatchlistService();
  bool _isHovered = false;

  // Add mapping between section titles and their cache keys
  final Map<String, String> _sectionToCacheKey = {
    'Price Target': 'stock-price-target',
    'Overview': 'business-overview',
    'Combined Charts': 'combined-charts',
    'Financial Performance': 'financial-performance',
    'Accounting Red Flags': 'accounting-redflags',
    'Cash Flow': 'cash-flow-chart',
    'Recent News': 'recent-news',
    'Competitors': 'competitor-landscape',
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
      title: 'Overview',
      icon: Icons.business,
      buildContent: () =>
          getBusinessOverview(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Combined Charts',
      icon: Icons.show_chart,
      buildContent: () =>
          getCombinedCharts(widget.tickerCode, widget.language.value),
    ),
    Section(
      title: 'Financial Performance',
      icon: Icons.assessment,
      buildContent: () =>
          getFinancialPerformance(widget.tickerCode, widget.language.value),
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
      title: 'Competitors',
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
    // Section(
    //   title: 'Interactive Chart',
    //   icon: Icons.timeline,
    //   buildContent: () =>
    //       getTradingViewChart(widget.tickerCode, widget.companyName),
    // ),
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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _showCompanyNameInTitle.dispose();
    _navigationTop.dispose();
    _currentSection.dispose();
    _cachedMetricsTable = null;
    _imageCache.clear();
    _sectionCache.clear();
    _futureCache.clear();
    _sectionLoadingStates.clear();
    for (var notifier in _tickAnimationStates.values) {
      notifier.dispose();
    }
    _tickAnimationStates.clear();
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
    final bool isFullWidth = sections.indexOf(section) >=
        sections.indexWhere((s) => s.title == 'Cash Flow');

    Widget sectionContent = Column(
      key: _sectionKeys[section.title],
      children: [
        if (isFullWidth)
          SizedBox(
            width: double.infinity,
            child: section.buildContent(),
          )
        else
          section.buildContent(),
        const SizedBox(height: 48),
      ],
    );

    // For non-authenticated users, handle section visibility
    if (user == null) {
      // List of sections that are free for non-authenticated users
      final freeSections = ['Price Target', 'Overview', 'Financial Metrics'];

      // Check if the company is in Mega 7 list
      final bool isMega7Company = [
        'AAPL', // Apple
        'MSFT', // Microsoft
        'GOOGL', // Alphabet
        'AMZN', // Amazon
        'NVDA', // NVIDIA
        'META', // Meta
        'TSLA', // Tesla
      ].contains(widget.tickerCode);

      // Special handling for Combined Charts section
      if (section.title == 'Combined Charts') {
        // For Mega 7 companies, show the content without blur
        if (isMega7Company) {
          return sectionContent;
        }

        final cacheKey = _sectionToCacheKey[section.title];
        return StreamBuilder<Map<String, bool>>(
          stream: widget.service.loadingStateSubject.stream,
          builder: (context, snapshot) {
            final loadingStates = snapshot.data ?? {};
            final isLoading =
                cacheKey != null && loadingStates[cacheKey] == true;

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

      // Return null for non-free sections
      if (!freeSections.contains(section.title) && !isMega7Company) {
        return const SizedBox.shrink();
      }
    }

    return sectionContent;
  }

  Widget getMetricsTable(bool isNarrow) {
    _cachedMetricsTable ??=
        getFinancialMetrics(widget.tickerCode, widget.language.value);
    return SizedBox(
      width: isNarrow ? double.infinity : 280,
      child: _cachedMetricsTable,
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
      _isRefreshing = true;
      forceRefresh = true;
      _cachedMetricsTable = null;
      _imageCache.clear();
      _sectionCache.clear();
      _futureCache.clear();
      _sectionLoadingStates.clear();
      for (var notifier in _tickAnimationStates.values) {
        notifier.dispose();
      }
      _tickAnimationStates.clear();
    });

    try {
      // Wait for all sections to load
      await Future.wait(sections.map((section) async {
        final cacheKey = _sectionToCacheKey[section.title];
        if (cacheKey != null) {
          await widget.service.getOutput(
            "/report-advanced/$cacheKey",
            widget.tickerCode,
            widget.language.value,
            true,
            cacheKey,
          );
        }
      }));

      if (mounted) {
        setState(() {
          _isRefreshing = false;
          forceRefresh = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          forceRefresh = false;
        });
      }
      print('Error refreshing report: $e');
    }
  }

  Widget _buildRefreshButton(bool isHovered) {
    return StreamBuilder<Map<String, bool>>(
      stream: widget.service.loadingStateSubject.stream,
      builder: (context, snapshot) {
        final loadingStates = snapshot.data ?? {};
        final isAnySectionLoading =
            loadingStates.values.any((isLoading) => isLoading);
        final isRefreshing = _isRefreshing || isAnySectionLoading;

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
                          if (user != null && showCompanyName)
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
                              height: user != null && showCompanyName ? 12 : 0),
                          if (user != null && showCompanyName)
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
                                  if (user != null) ...[
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
    // Filter sections based on authentication status
    final List<Section> visibleSections = user != null
        ? sections
        : sections.where((section) {
            final freeSections = [
              'Price Target',
              'Overview',
              'Combined Charts',
              'Financial Metrics'
            ];
            final bool isMega7Company = [
              'GOOGL', // Alphabet
              'AMZN', // Amazon
              'AAPL', // Apple
              'META', // Meta
              'MSFT', // Microsoft
              'NVDA', // Nvidia
              'TSLA', // Tesla
            ].contains(widget.tickerCode);
            return freeSections.contains(section.title) || isMega7Company;
          }).toList();

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
                          final metricsTable = getMetricsTable(isNarrow);
                          final contentSections = sections
                              .map((section) => _buildSection(section))
                              .where((widget) =>
                                  widget is! SizedBox ||
                                  (widget as SizedBox).width != 0)
                              .toList();

                          final keyMetricsSection = Container(
                            color: Colors.white,
                            child: isNarrow
                                ? Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        metricsTable,
                                        const SizedBox(height: 48),
                                        ...contentSections
                                            .take(contentSections.length),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (contentSections.isNotEmpty)
                                        contentSections[0], // Price Target
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (contentSections.length >
                                                      1)
                                                    contentSections[
                                                        1], // Overview
                                                  const SizedBox(height: 48),
                                                  if (contentSections.length >
                                                      2)
                                                    contentSections[
                                                        2], // Combined Charts
                                                  const SizedBox(height: 48),
                                                  if (contentSections.length >
                                                      3)
                                                    contentSections[
                                                        3], // Financial Performance
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            SizedBox(
                                              width: 280,
                                              child: metricsTable,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          );

                          final remainingSection = Container(
                            padding: const EdgeInsets.all(32),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (contentSections.length > 4) ...[
                                  ...contentSections.skip(4).take(4),
                                  const SizedBox(height: 24),
                                  ...contentSections.skip(8),
                                ],
                              ],
                            ),
                          );

                          return Column(
                            children: [
                              headerView(widget.companyName),
                              const SizedBox(height: 24),
                              keyMetricsSection,
                              const SizedBox(height: 24),
                              remainingSection,
                            ],
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
                            height: MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.only(right: 24),
                            child: _buildNavigationList(visibleSections),
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
                                if (user == null)
                                  IconButton(
                                    onPressed: () {
                                      context.go('/');
                                    },
                                    icon: const Icon(
                                      Icons.home,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    tooltip: 'Home',
                                  ),
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
        'stockPriceTarget');
  }

  Widget getInsiderTrading(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'insiderTrading',
            () => widget.service
                .getInsiderTrading(ticker, language, forceRefresh)),
        'insiderTrading');
  }

  Widget getPEPBRatioBandChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'pbRatioBand',
            () => widget.service
                .getPEPBRatioBand(ticker, language, forceRefresh)),
        'pbRatioBand');
  }

  Widget getSectorStocksChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'sectorStocks',
            () =>
                widget.service.getSectorStocks(ticker, language, forceRefresh)),
        'sectorStocks');
  }

  Widget getCandleStickChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'candleStickChart',
            () => widget.service
                .getCandleStickChart(ticker, language, forceRefresh)),
        'candleStickChart');
  }

  Widget getCombinedCharts(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'combinedCharts',
            () => widget.service
                .getCombinedCharts(ticker, language, forceRefresh)),
        'combinedCharts');
  }

  Widget getCashFlowChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'cashFlowChart',
            () => widget.service
                .getCashFlowChart(ticker, language, forceRefresh)),
        'cashFlowChart');
  }

  Widget getIndustrialRelationship(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'industrialRelationship',
            () => widget.service
                .getIndustrialRelationship(ticker, language, forceRefresh)),
        'industrialRelationship');
  }

  Widget getSectorComparison(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'sectorComparison',
            () => widget.service
                .getSectorComparison(ticker, language, forceRefresh)),
        'sectorComparison');
  }

  Widget getShareholderChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'shareholderChart',
            () => widget.service
                .getShareholderChart(ticker, language, forceRefresh)),
        'shareholderChart');
  }

  Widget getChart(Future<Map<String, dynamic>> future, String key) {
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
    );
  }

  Future<Map<String, dynamic>> _getCachedFuture(
      String key, Future<Map<String, dynamic>> Function() createFuture) {
    if (!_futureCache.containsKey(key)) {
      _futureCache[key] = createFuture();
    }
    return _futureCache[key]!;
  }

  List<Widget> _buildActions() {
    return [
      StreamBuilder(
          stream: widget.service.loadingStateSubject.stream,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final Map<String, bool> loadingState = snapshot.data;
              final isWorking = loadingState.containsValue(true);
              return isWorking
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ThinkingAnimation(
                        size: 20,
                        color: Color(0xFF1E3A8A),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleRefresh,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered))
                              return const Color(0xFF1E3A8A);
                            return Colors.black;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      child: Text(
                        widget.language == Language.english
                            ? 'Update Reports'
                            : '获取最新',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5),
                      ));
            }
            return ElevatedButton(
              onPressed: _handleRefresh,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.hovered))
                      return const Color(0xFF1E3A8A);
                    return Colors.black;
                  },
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: Text(
                widget.language == Language.english ? 'Update Reports' : '获取最新',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
            );
          }),
    ];
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
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(seconds: 15),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  bool _isOverflowing = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _checkOverflow();
      }
    });
  }

  void _checkOverflow() {
    if (_isDisposed) return;

    final textStyle = widget.style;
    final text = widget.text;
    final fontSize = textStyle.fontSize ?? 18.0;
    final fontFamily = textStyle.fontFamily;
    final fontWeight = textStyle.fontWeight ?? FontWeight.normal;

    // Approximate text width based on character count and font size
    final approximateWidth = text.length * fontSize * 0.6;

    if (approximateWidth > 200) {
      // Check against container width
      if (!_isDisposed) {
        setState(() {
          _isOverflowing = true;
        });
        // Add a small delay before starting the animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed && mounted) {
            _startMarquee();
          }
        });
      }
    }
  }

  void _startMarquee() {
    if (!_scrollController.hasClients || _isDisposed) return;

    _scrollController
        .animateTo(
      _scrollController.position.maxScrollExtent,
      duration: widget.duration,
      curve: Curves.linear,
    )
        .then((_) {
      if (!_isDisposed && mounted) {
        _scrollController.jumpTo(0);
        _startMarquee();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOverflowing) {
      return Text(
        widget.text,
        style: widget.style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            widget.text,
            style: widget.style,
          ),
          const SizedBox(width: 20), // Add some space between repetitions
          Text(
            widget.text,
            style: widget.style,
          ),
        ],
      ),
    );
  }
}
