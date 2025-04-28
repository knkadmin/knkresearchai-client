import 'package:fa_ai_agent/services/agent_service.dart';
import 'package:fa_ai_agent/main.dart';
import 'package:fa_ai_agent/models/section.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';
import 'package:fa_ai_agent/widgets/report/report_widgets.dart';
import 'package:fa_ai_agent/widgets/report/report_header.dart';
import 'package:fa_ai_agent/widgets/report/report_content_layout.dart';
import 'package:fa_ai_agent/widgets/report/report_navigation_overlay.dart';
import 'services/watchlist_service.dart';
import 'services/section_visibility_manager.dart';
import 'services/premium_section_manager.dart';
import 'services/company_service.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import 'models/subscription_type.dart';
import 'services/public_user_last_viewed_report_tracker.dart';
import 'dart:async';
import 'services/subscription_service.dart';
import 'package:intl/intl.dart';
import 'package:fa_ai_agent/widgets/report/report_sticky_header.dart';
import 'services/firestore_service.dart';
import 'package:fa_ai_agent/widgets/report/chart_builder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuration for a section
class SectionConfig {
  final String title;
  final String cacheKey;
  final IconData icon;
  final Widget Function(String, String) builder;

  const SectionConfig({
    required this.title,
    required this.cacheKey,
    required this.icon,
    required this.builder,
  });
}

/// Constants and utilities for section management
class SectionConstants {
  static List<SectionConfig> createSectionConfigs(
          ReportWidgets reportWidgets) =>
      [
        SectionConfig(
          title: 'Financial Metrics',
          cacheKey: 'financial-metrics',
          icon: Icons.analytics,
          builder: reportWidgets.getFinancialMetrics,
        ),
        SectionConfig(
          title: 'Price Target',
          cacheKey: 'stock-price-target',
          icon: Icons.trending_up,
          builder: reportWidgets.getStockPriceTarget,
        ),
        SectionConfig(
          title: 'Company Overview',
          cacheKey: 'business-overview',
          icon: Icons.business,
          builder: reportWidgets.getBusinessOverview,
        ),
        SectionConfig(
          title: 'EPS vs Stock Price',
          cacheKey: 'eps-vs-stock-price',
          icon: Icons.compare_arrows,
          builder: (ticker, language) => Column(
            children: [
              reportWidgets.getEPSvsStockPriceChart(ticker, language),
              const SizedBox(height: 16),
              reportWidgets.getEPSvsStockPriceAnalysis(ticker, language,
                  showTitle: false),
            ],
          ),
        ),
        SectionConfig(
          title: 'Financial Performance',
          cacheKey: 'combined-charts',
          icon: Icons.assessment,
          builder: reportWidgets.getCombinedCharts,
        ),
        SectionConfig(
          title: 'Accounting Red Flags',
          cacheKey: 'accounting-redflags',
          icon: Icons.warning_amber_rounded,
          builder: reportWidgets.getAccountingRedFlags,
        ),
        SectionConfig(
          title: 'Cash Flow',
          cacheKey: 'cash-flow-chart',
          icon: Icons.account_balance,
          builder: reportWidgets.getCashFlowChart,
        ),
        SectionConfig(
          title: 'Recent News',
          cacheKey: 'recent-news',
          icon: Icons.newspaper,
          builder: reportWidgets.getRecentNews,
        ),
        SectionConfig(
          title: 'Competitive Landscape',
          cacheKey: 'competitor-landscape',
          icon: Icons.people,
          builder: reportWidgets.getCompetitorLandscape,
        ),
        SectionConfig(
          title: 'Sector Stocks',
          cacheKey: 'sector-stocks',
          icon: Icons.category_outlined,
          builder: reportWidgets.getSectorStocksChart,
        ),
        SectionConfig(
          title: 'Sector Comparison',
          cacheKey: 'sector-comparison',
          icon: Icons.compare_arrows,
          builder: reportWidgets.getSectorComparison,
        ),
        SectionConfig(
          title: 'PE/PB Ratio',
          cacheKey: 'pe-pb-ratio-band',
          icon: Icons.analytics,
          builder: reportWidgets.getPEPBRatioBandChart,
        ),
        SectionConfig(
          title: 'Supply Chain',
          cacheKey: 'supply-chain',
          icon: Icons.linear_scale,
          builder: reportWidgets.getSupplyChain,
        ),
        SectionConfig(
          title: 'Industrial Relations',
          cacheKey: 'industrial-relationship',
          icon: Icons.handshake,
          builder: reportWidgets.getIndustrialRelationship,
        ),
        SectionConfig(
          title: 'Strategic Outlook',
          cacheKey: 'strategic-outlooks',
          icon: Icons.visibility,
          builder: reportWidgets.getStrategicOutlooks,
        ),
        SectionConfig(
          title: 'Insider Trading',
          cacheKey: 'insider-trading',
          icon: Icons.swap_horiz,
          builder: reportWidgets.getInsiderTrading,
        ),
        SectionConfig(
          title: 'Shareholders',
          cacheKey: 'shareholder-chart',
          icon: Icons.pie_chart,
          builder: reportWidgets.getShareholderChart,
        ),
        SectionConfig(
          title: 'Technical Analysis ',
          cacheKey: 'candle-stick-chart',
          icon: Icons.candlestick_chart,
          builder: reportWidgets.getCandleStickChart,
        ),
        SectionConfig(
          title: 'Technical Analysis',
          cacheKey: 'technical-analysis',
          icon: Icons.article_outlined,
          builder: reportWidgets.getTechnicalAnalysis,
        ),
      ];

  static List<String> get allSectionNames => createSectionConfigs(ReportWidgets(
        service: AgentService(),
        imageCache: {},
        imageUrlCache: {},
        sectionCache: {},
        streamCache: {},
        cacheTimeSubject: BehaviorSubject(),
        forceRefresh: false,
      )).map((config) => config.title).toList();

  static List<String> get premiumSectionNames => allSectionNames
      .where((section) => section != 'Company Overview')
      .toList();

  static Map<String, String> get sectionToCacheKey => {
        for (var config in createSectionConfigs(ReportWidgets(
          service: AgentService(),
          imageCache: {},
          imageUrlCache: {},
          sectionCache: {},
          streamCache: {},
          cacheTimeSubject: BehaviorSubject(),
          forceRefresh: false,
        )))
          config.title: config.cacheKey
      };
}

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
  final Map<String, String> _imageUrlCache = {};
  final Map<String, Widget> _sectionCache = {};
  final Map<String, Stream<Map<String, dynamic>>> _streamCache = {};
  final Map<String, bool> _sectionLoadingStates = {};
  final ValueNotifier<bool> _showCompanyNameInTitle =
      ValueNotifier<bool>(false);
  final ValueNotifier<double> _navigationTop = ValueNotifier<double>(200);
  final ValueNotifier<bool> _isRefreshing = ValueNotifier<bool>(false);
  Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, ValueNotifier<bool>> _tickAnimationStates = {};
  final WatchlistService _watchlistService = WatchlistService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CompanyService _companyService = CompanyService();
  bool _isHovered = false;
  bool forceRefresh = false;

  StreamSubscription<SubscriptionType>? _subscriptionSubscription;
  final ValueNotifier<SubscriptionType?> _subscriptionTypeNotifier =
      ValueNotifier<SubscriptionType?>(null);

  final PremiumSectionManager _premiumSectionManager = PremiumSectionManager();

  ReportWidgets _reportWidgets = ReportWidgets(
    service: AgentService(),
    imageCache: {},
    imageUrlCache: {},
    sectionCache: {},
    streamCache: {},
    cacheTimeSubject: BehaviorSubject(),
    forceRefresh: false,
  );

  late List<Section> sections;

  @override
  void initState() {
    super.initState();

    _initializeCacheTime();

    // Set document title for web
    if (kIsWeb) {
      html.document.title =
          "${widget.tickerCode} - ${widget.companyName} | KNK Research AI";
    }

    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    analytics.logEvent(
        name: 'view_reports', parameters: {'ticker': widget.tickerCode});
    _scrollController.addListener(_onScroll);

    // Update requested field to true
    FirestoreService().updateRequestedField(widget.tickerCode);

    // Initialize sections
    sections =
        SectionConstants.createSectionConfigs(_reportWidgets).map((config) {
      return Section(
        title: config.title,
        icon: config.icon,
        buildContent: () =>
            config.builder(widget.tickerCode, widget.language.value),
      );
    }).toList();

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
    _isMag7CompanyFuture = _companyService.isMag7Company(widget.tickerCode);

    // Save last viewed report for non-authenticated users
    if (AuthService().currentUser == null) {
      _cacheManager.saveLastViewedReport(widget.tickerCode);
    }

    // Set up user data subscription
    final user = AuthService().currentUser;
    if (user != null) {
      _subscriptionSubscription = _subscriptionService
          .streamUserSubscription()
          .listen((subscriptionType) {
        // Check if mounted before updating state
        if (mounted) {
          _subscriptionTypeNotifier.value = subscriptionType;
        }
      });
    }

    // Initialize the report widgets
    _reportWidgets = ReportWidgets(
      service: widget.service,
      imageCache: _imageCache,
      imageUrlCache: _imageUrlCache,
      sectionCache: _sectionCache,
      streamCache: _streamCache,
      cacheTimeSubject: widget.cacheTimeSubject,
      forceRefresh: forceRefresh,
    );
  }

  /// Initializes the cache time from Firestore.
  void _initializeCacheTime() async {
    try {
      final doc = await FirestoreService()
          .getDocument('financialReports', widget.tickerCode);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lastUpdated = data['lastUpdated'] as Timestamp?;
        if (lastUpdated != null) {
          widget.cacheTimeSubject.add(lastUpdated.millisecondsSinceEpoch *
              1000); // Convert to microseconds
          return;
        }
      }

      // If no lastUpdated field exists, use current time
      final currentTimestamp = DateTime.now().microsecondsSinceEpoch;
      widget.cacheTimeSubject.add(currentTimestamp);
    } catch (e) {
      print('Error initializing cache time: $e');
      // Fallback to current time if there's an error
      final currentTimestamp = DateTime.now().microsecondsSinceEpoch;
      widget.cacheTimeSubject.add(currentTimestamp);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _currentSection.dispose();
    widget.sectorSubject.close();
    _imageCache.clear();
    _sectionCache.clear();
    _streamCache.clear();
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
    const initialTop =
        400.0; // Initial top position (adjusted to align with first section)
    const stickyTop = 80.0; // Position when sticky (below app bar)

    if (scrollOffset > initialTop - stickyTop) {
      _navigationTop.value = stickyTop;
    } else {
      _navigationTop.value = initialTop - scrollOffset;
    }

    // Update current section based on scroll position (Revised Logic)
    String? lastVisibleSectionTitle;
    // Iterate through the ordered sections list
    for (final section in sections) {
      final key = _sectionKeys[section.title];
      final context = key?.currentContext;
      if (context != null) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);

        // Check if the section's top is at or above the threshold (200px)
        if (position.dy <= 200) {
          // Keep track of the last section that meets the condition
          lastVisibleSectionTitle = section.title;
        } else {
          // Optimization: If we find a section whose top is below the threshold,
          // and we already found a candidate, we can stop early
          // because sections are ordered visually.
          if (lastVisibleSectionTitle != null) {
            break;
          }
        }
      }
    }

    // Update the current section if a suitable one was found
    if (lastVisibleSectionTitle != null &&
        _currentSection.value != lastVisibleSectionTitle) {
      _currentSection.value = lastVisibleSectionTitle;
    }
    // If no section's top is above the threshold (e.g., scrolled to top),
    // potentially default to the first section if needed (optional enhancement)
    // else if (lastVisibleSectionTitle == null && _currentSection.value != sections.first.title) {
    //  _currentSection.value = sections.first.title;
    // }
  }

  void _scrollToSection(String sectionTitle) {
    final key = _sectionKeys[sectionTitle];
    // Check context before the delay
    if (key?.currentContext != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        // Check mount status and key non-null *and* context non-null *after* delay
        if (mounted && key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutExpo,
            alignment: 0.0,
          );
        }
      });
    }
  }

  void _handleRefresh() async {
    // Get the latest timestamp from Firestore
    try {
      final doc = await FirestoreService()
          .getDocument('financialReports', widget.tickerCode);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lastUpdated = data['lastUpdated'] as Timestamp?;
        if (lastUpdated != null) {
          widget.cacheTimeSubject.add(lastUpdated.millisecondsSinceEpoch *
              1000); // Convert to microseconds
        }
      }
    } catch (e) {
      print('Error getting cache time: $e');
      // Fallback to current time if there's an error
      final currentTimestamp = DateTime.now().microsecondsSinceEpoch;
      widget.cacheTimeSubject.add(currentTimestamp);
    }

    setState(() {
      _isRefreshing.value = true;
      _sectionLoadingStates.clear();
      for (var notifier in _tickAnimationStates.values) {
        notifier.dispose();
      }
      _tickAnimationStates.clear();
      _streamCache.clear(); // Clear the future cache to force new requests
      _imageCache.clear(); // Clear image cache
      _imageUrlCache.clear(); // Clear image URL cache
      _sectionCache.clear(); // Clear section cache
      ChartBuilder.clearSignedUrlCache(); // Clear signed URL cache
      forceRefresh = true; // Set force refresh flag

      // Reinitialize the report widgets with the updated forceRefresh value
      _reportWidgets = ReportWidgets(
        service: widget.service,
        imageCache: _imageCache,
        imageUrlCache: _imageUrlCache,
        sectionCache: _sectionCache,
        streamCache: _streamCache,
        cacheTimeSubject: widget.cacheTimeSubject,
        forceRefresh: forceRefresh,
      );

      // Recreate sections with the new report widgets
      sections =
          SectionConstants.createSectionConfigs(_reportWidgets).map((config) {
        return Section(
          title: config.title,
          icon: config.icon,
          buildContent: () =>
              config.builder(widget.tickerCode, widget.language.value),
        );
      }).toList();

      // Reset the current section to the first one
      if (sections.isNotEmpty) {
        _currentSection.value = sections.first.title;
      }
    });

    // Wait for all sections to finish loading
    await Future.delayed(const Duration(milliseconds: 100));

    _isRefreshing.value = false;
    forceRefresh = false; // Reset force refresh flag after refresh is complete
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isAuthenticated = user != null;

    return ValueListenableBuilder<SubscriptionType?>(
      valueListenable: _subscriptionTypeNotifier,
      builder: (context, subscriptionType, child) {
        return FutureBuilder<bool>(
          future: _isMag7CompanyFuture,
          builder: (context, mag7Snapshot) {
            if (mag7Snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
      bool isMag7Company, SubscriptionType? userSubscriptionType) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildMainContent(
              sections, isAuthenticated, isMag7Company, userSubscriptionType),
          _buildNavigationOverlay(),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<Section> sections, bool isAuthenticated,
      bool isMag7Company, SubscriptionType? userSubscriptionType) {
    return Stack(
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
                    padding: EdgeInsets.only(top: isNarrow ? 60 : 0),
                    child: ReportContentLayout(
                      sections: sections,
                      isAuthenticated: isAuthenticated,
                      isMag7Company: isMag7Company,
                      userSubscriptionType: userSubscriptionType,
                      isNarrow: isNarrow,
                      buildSection: _buildSection,
                      headerView: (title) => ReportHeader(
                        tickerCode: widget.tickerCode,
                        cacheTimeSubject: widget.cacheTimeSubject,
                        language: widget.language,
                      ),
                      sectionCache: _sectionCache,
                      tickerCode: widget.tickerCode,
                      language: widget.language.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Add sticky header for narrow screens
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1000) return const SizedBox.shrink();

            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReportStickyHeader(
                    tickerCode: widget.tickerCode,
                    companyName: widget.companyName,
                    showCompanyNameInTitle: _showCompanyNameInTitle,
                    cacheTimeSubject: widget.cacheTimeSubject,
                    watchlistService: _watchlistService,
                    isRefreshing: _isRefreshing,
                    onRefresh: _handleRefresh,
                    onWatch: () async {
                      try {
                        final isInWatchlist = await _watchlistService
                            .isInWatchlist(widget.tickerCode)
                            .first;
                        if (isInWatchlist) {
                          await _watchlistService
                              .removeFromWatchlist(widget.tickerCode);
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
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavigationOverlay() {
    return ReportNavigationOverlay(
      sections: sections.where((s) => s.title != 'Technical Analysis').toList(),
      tickerCode: widget.tickerCode,
      companyName: widget.companyName,
      currentSection: _currentSection,
      showCompanyNameInTitle: _showCompanyNameInTitle,
      sectionLoadingStates: _sectionLoadingStates,
      tickAnimationStates: _tickAnimationStates,
      sectionToCacheKey: SectionConstants.sectionToCacheKey,
      cacheTimeStream: widget.cacheTimeSubject.stream,
      onSectionTap: _scrollToSection,
      onRefresh: _handleRefresh,
      isRefreshing: _isRefreshing,
      onWatch: () async {
        try {
          // Get the current value from the stream
          final isInWatchlist =
              await _watchlistService.isInWatchlist(widget.tickerCode).first;

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
      isHovered: _isHovered,
      loadingStateStream: widget.service.loadingStateSubject.stream,
      watchlistService: _watchlistService,
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 0),
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

        // If it's a Mag 7 company, show all sections without restrictions
        if (isMag7Company) {
          return sectionContent;
        }

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

            return ValueListenableBuilder<SubscriptionType?>(
              valueListenable: _subscriptionTypeNotifier,
              builder: (context, subscriptionType, child) {
                // Only check subscription type for authenticated users
                if (isAuthenticated && subscriptionType == null) {
                  return const SizedBox.shrink();
                }

                // Check if we should show blur overlay
                final shouldShowBlur =
                    _premiumSectionManager.shouldShowBlurOverlay(
                  sectionTitle: section.title,
                  isAuthenticated: isAuthenticated,
                  isMag7Company: isMag7Company,
                  subscriptionType: subscriptionType,
                );

                if (shouldShowBlur) {
                  return _premiumSectionManager.buildSectionWithBlurOverlay(
                    sectionContent: sectionContent,
                    sectionTitle: section.title,
                    isAuthenticated: isAuthenticated,
                    context: context,
                    cacheManager: _cacheManager,
                  );
                }

                // For non-premium sections or users with access, show content
                return sectionContent;
              },
            );
          },
        );
      },
    );
  }
}
