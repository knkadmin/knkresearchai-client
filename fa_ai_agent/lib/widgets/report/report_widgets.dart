import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/report/report_builder.dart';
import 'package:fa_ai_agent/widgets/report/chart_builder.dart';
import 'package:fa_ai_agent/widgets/report/alert_report_builder.dart';
import 'package:fa_ai_agent/widgets/trading_view_chart.dart';
import 'package:fa_ai_agent/services/agent_service.dart';
import 'package:rxdart/subjects.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fa_ai_agent/constants/api_constants.dart';
import 'package:fa_ai_agent/utils/image_utils.dart';

/// A class that provides methods to build various report widgets
class ReportWidgets {
  final AgentService _service;
  final Map<String, Widget> _imageCache;
  final Map<String, String> _imageUrlCache;
  final Map<String, Stream<Map<String, dynamic>>> _streamCache;
  final Map<String, Widget> _widgetContentCache;
  final bool _forceRefresh;

  ReportWidgets({
    required AgentService service,
    required Map<String, Widget> imageCache,
    required Map<String, String> imageUrlCache,
    required Map<String, Widget> sectionCache,
    required Map<String, Stream<Map<String, dynamic>>> streamCache,
    required BehaviorSubject cacheTimeSubject,
    required bool forceRefresh,
  })  : _service = service,
        _imageCache = imageCache,
        _imageUrlCache = imageUrlCache,
        _streamCache = streamCache,
        _widgetContentCache = {},
        _forceRefresh = forceRefresh;

  /// Gets a cached future or creates a new one
  Stream<Map<String, dynamic>> _getCachedStream(
      String key, Stream<Map<String, dynamic>> Function() createStream) {
    if (!_streamCache.containsKey(key)) {
      _streamCache[key] = createStream();
    }
    return _streamCache[key]!;
  }

  /// Builds a report widget
  Widget getReport(
      Stream<Map<String, dynamic>> stream, String title, String key,
      {bool showTitle = true}) {
    final cacheKey = '$key-$showTitle';
    if (_widgetContentCache.containsKey(cacheKey)) {
      return _widgetContentCache[cacheKey]!;
    }

    final widget = ReportBuilder(
      stream: stream,
      title: title,
      reportKey: key,
      showTitle: showTitle,
      onContentBuilt: (Widget content) {
        _widgetContentCache[cacheKey] = content;
      },
    );
    return widget;
  }

  /// Builds a chart widget
  Widget getChart(Stream<Map<String, dynamic>> stream, String key,
      {required String title, bool showTitle = true}) {
    final cacheKey = '$key-$showTitle';
    if (_widgetContentCache.containsKey(cacheKey)) {
      return _widgetContentCache[cacheKey]!;
    }

    final widget = ChartBuilder(
      stream: stream,
      chartKey: key,
      cachedImage: (!_forceRefresh && _imageCache.containsKey(key))
          ? _imageCache[key]
          : null,
      cachedImageUrl: (!_forceRefresh && _imageUrlCache.containsKey(key))
          ? _imageUrlCache[key]
          : null,
      onImageCached: (Widget image, String imageUrl) {
        _imageCache[key] = image;
        _imageUrlCache[key] = imageUrl;
      },
      onContentBuilt: (Widget content) {
        _widgetContentCache[cacheKey] = content;
      },
      title: title,
      showTitle: showTitle,
    );
    return widget;
  }

  /// Gets the business overview report
  Widget getBusinessOverview(String ticker, String language) {
    return getReport(
        _getCachedStream(
            'businessOverview',
            () =>
                _service.getBusinessOverview(ticker, language, _forceRefresh)),
        "Company Overview",
        "businessOverview");
  }

  /// Gets the EPS vs Stock Price chart
  Widget getEPSvsStockPriceChart(String ticker, String language) {
    return getChart(
        _getCachedStream(
            'epsVsStockPriceChart',
            () => _service.getEPSvsStockPriceChart(
                ticker, language, _forceRefresh)),
        'epsVsStockPriceChart',
        title: 'EPS vs Stock Price');
  }

  /// Gets the financial metrics report
  Widget getFinancialMetrics(String ticker, String language) {
    return getReport(
        _getCachedStream(
            'financialMetrics',
            () =>
                _service.getFinancialMetrics(ticker, language, _forceRefresh)),
        "Financial Metrics",
        "financialMetrics",
        showTitle: false);
  }

  /// Gets the financial performance report
  Widget getFinancialPerformance(String ticker, String language) {
    return getReport(
        _getCachedStream(
            'financialPerformance',
            () => _service.getFinancialPerformance(
                ticker, language, _forceRefresh)),
        "Financial Performance",
        "financialPerformance");
  }

  /// Gets the competitor landscape report
  Widget getCompetitorLandscape(String ticker, String language) {
    return getReport(
        _getCachedStream(
            'competitorLandscape',
            () => _service.getCompetitorLandscape(
                ticker, language, _forceRefresh)),
        "Competitive Landscape",
        "competitorLandscape");
  }

  /// Gets the supply chain report
  Widget getSupplyChain(String ticker, String language) {
    return getReport(
        _getCachedStream('supplyChain',
            () => _service.getSupplyChain(ticker, language, _forceRefresh)),
        "Supply Chain Feedbacks",
        "supplyChain");
  }

  /// Gets the strategic outlooks report
  Widget getStrategicOutlooks(String ticker, String language) {
    return getReport(
        _getCachedStream(
            'strategicOutlooks',
            () =>
                _service.getStrategicOutlooks(ticker, language, _forceRefresh)),
        "Strategic Outlooks",
        "strategicOutlooks");
  }

  /// Gets the recent news report
  Widget getRecentNews(String ticker, String language) {
    return getReport(
        _getCachedStream('recentNews',
            () => _service.getRecentNews(ticker, language, _forceRefresh)),
        "Recent News",
        "recentNews");
  }

  /// Gets the stock price target chart
  Widget getStockPriceTarget(String ticker, String language) {
    return getChart(
        _getCachedStream(
            'stockPriceTarget',
            () =>
                _service.getStockPriceTarget(ticker, language, _forceRefresh)),
        'stockPriceTarget',
        title: 'Price Target',
        showTitle: false);
  }

  /// Gets the insider trading chart
  Widget getInsiderTrading(String ticker, String language) {
    return getChart(
        _getCachedStream('insiderTrading',
            () => _service.getInsiderTrading(ticker, language, _forceRefresh)),
        'insiderTrading',
        title: 'Insider Trading');
  }

  /// Gets the PE/PB ratio band chart
  Widget getPEPBRatioBandChart(String ticker, String language) {
    return getChart(
        _getCachedStream('pbRatioBand',
            () => _service.getPEPBRatioBand(ticker, language, _forceRefresh)),
        'pePbRatioBand',
        title: 'PE/PB Ratio');
  }

  /// Gets the sector stocks chart
  Widget getSectorStocksChart(String ticker, String language) {
    return getChart(
        _getCachedStream('sectorStocks',
            () => _service.getSectorStocks(ticker, language, _forceRefresh)),
        'sectorStocks',
        title: 'Sector Stocks');
  }

  /// Gets the candle stick chart
  Widget getCandleStickChart(String ticker, String language) {
    return getChart(
        _getCachedStream(
            'candleStickChart',
            () =>
                _service.getCandleStickChart(ticker, language, _forceRefresh)),
        'candleStickChart',
        title: 'Technical Analysis');
  }

  Widget getTechnicalAnalysis(String ticker, String language) {
    return getReport(
        _getCachedStream(
            'technicalAnalysis',
            () =>
                _service.getTechnicalAnalysis(ticker, language, _forceRefresh)),
        "Technical Analysis",
        "technicalAnalysis",
        showTitle: false);
  }

  /// Gets the combined charts
  Widget getCombinedCharts(String ticker, String language) {
    return Column(
      children: [
        getChart(
          _getCachedStream(
              'combinedCharts',
              () =>
                  _service.getCombinedCharts(ticker, language, _forceRefresh)),
          'combinedCharts',
          title: 'Financial Performance',
        ),
        const SizedBox(height: 24),
        getReport(
          _getCachedStream(
              'financialPerformance',
              () => _service.getFinancialPerformance(
                  ticker, language, _forceRefresh)),
          "Financial Performance",
          "financialPerformance",
          showTitle: false,
        ),
      ],
    );
  }

  /// Gets the cash flow chart
  Widget getCashFlowChart(String ticker, String language) {
    return getChart(
        _getCachedStream('cashFlowChart',
            () => _service.getCashFlowChart(ticker, language, _forceRefresh)),
        'cashFlowChart',
        title: 'Cash Flow');
  }

  /// Gets the industrial relationship chart
  Widget getIndustrialRelationship(String ticker, String language) {
    return getChart(
        _getCachedStream(
            'industrialRelationship',
            () => _service.getIndustrialRelationship(
                ticker, language, _forceRefresh)),
        'industrialRelationship',
        title: 'Industrial Relations');
  }

  /// Gets the sector comparison chart
  Widget getSectorComparison(String ticker, String language) {
    return getChart(
        _getCachedStream(
            'sectorComparison',
            () =>
                _service.getSectorComparison(ticker, language, _forceRefresh)),
        'sectorComparison',
        title: 'Sector Comparison');
  }

  /// Gets the shareholder chart
  Widget getShareholderChart(String ticker, String language) {
    return getChart(
        _getCachedStream(
            'shareholderChart',
            () =>
                _service.getShareholderChart(ticker, language, _forceRefresh)),
        'shareholderChart',
        title: 'Shareholders');
  }

  /// Gets the trading view chart
  Widget getTradingViewChart(String ticker, String companyName) {
    return TradingViewChart(
      tickerSymbol: ticker,
      companyName: companyName,
    );
  }

  /// Gets the accounting red flags report
  Widget getAccountingRedFlags(String ticker, String language) {
    const cacheKey = 'accountingRedFlags';
    if (_widgetContentCache.containsKey(cacheKey)) {
      return _widgetContentCache[cacheKey]!;
    }
    return AlertReportBuilder(
      stream: _getCachedStream(
          'accountingRedFlags',
          () =>
              _service.getAccountingRedFlags(ticker, language, _forceRefresh)),
      title: "Accounting Red Flags",
      onContentBuilt: (Widget content) {
        _widgetContentCache[cacheKey] = content;
      },
      reportKey: 'accountingRedFlags',
    );
  }
}
