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
  final Map<String, Widget> _sectionCache;
  final Map<String, Future<Map<String, dynamic>>> _futureCache;
  final BehaviorSubject _cacheTimeSubject;
  final bool _forceRefresh;

  ReportWidgets({
    required AgentService service,
    required Map<String, Widget> imageCache,
    required Map<String, String> imageUrlCache,
    required Map<String, Widget> sectionCache,
    required Map<String, Future<Map<String, dynamic>>> futureCache,
    required BehaviorSubject cacheTimeSubject,
    required bool forceRefresh,
  })  : _service = service,
        _imageCache = imageCache,
        _imageUrlCache = imageUrlCache,
        _sectionCache = sectionCache,
        _futureCache = futureCache,
        _cacheTimeSubject = cacheTimeSubject,
        _forceRefresh = forceRefresh;

  /// Gets a cached future or creates a new one
  Future<Map<String, dynamic>> _getCachedFuture(
      String key, Future<Map<String, dynamic>> Function() createFuture) {
    if (!_futureCache.containsKey(key)) {
      _futureCache[key] = createFuture();
    }
    return _futureCache[key]!;
  }

  /// Builds a report widget
  Widget getReport(
      Future<Map<String, dynamic>> future, String title, String key,
      {bool showTitle = true}) {
    return ReportBuilder(
      future: future,
      title: title,
      reportKey: key,
      showTitle: showTitle,
    );
  }

  /// Builds a chart widget
  Widget getChart(Future<Map<String, dynamic>> future, String key,
      {required String title, bool showTitle = true}) {
    return ChartBuilder(
      future: future,
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
      title: title,
      showTitle: showTitle,
    );
  }

  /// Gets the business overview report
  Widget getBusinessOverview(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'businessOverview',
            () =>
                _service.getBusinessOverview(ticker, language, _forceRefresh)),
        "Company Overview",
        "businessOverview");
  }

  /// Gets the EPS vs Stock Price chart
  Widget getEPSvsStockPriceChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'epsVsStockPriceChart',
            () => _service.getEPSvsStockPriceChart(
                ticker, language, _forceRefresh)),
        'epsVsStockPriceChart',
        title: 'EPS vs Stock Price');
  }

  /// Gets the financial metrics report
  Widget getFinancialMetrics(String ticker, String language) {
    return getReport(
        _getCachedFuture(
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
        _getCachedFuture(
            'financialPerformance',
            () => _service.getFinancialPerformance(
                ticker, language, _forceRefresh)),
        "Financial Performance",
        "financialPerformance");
  }

  /// Gets the competitor landscape report
  Widget getCompetitorLandscape(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'competitorLandscape',
            () => _service.getCompetitorLandscape(
                ticker, language, _forceRefresh)),
        "Competitive Landscape",
        "competitorLandscape");
  }

  /// Gets the supply chain report
  Widget getSupplyChain(String ticker, String language) {
    return getReport(
        _getCachedFuture('supplyChain',
            () => _service.getSupplyChain(ticker, language, _forceRefresh)),
        "Supply Chain Feedbacks",
        "supplyChain");
  }

  /// Gets the strategic outlooks report
  Widget getStrategicOutlooks(String ticker, String language) {
    return getReport(
        _getCachedFuture(
            'strategicOutlooks',
            () =>
                _service.getStrategicOutlooks(ticker, language, _forceRefresh)),
        "Strategic Outlooks",
        "strategicOutlooks");
  }

  /// Gets the recent news report
  Widget getRecentNews(String ticker, String language) {
    return getReport(
        _getCachedFuture('recentNews',
            () => _service.getRecentNews(ticker, language, _forceRefresh)),
        "Recent News",
        "recentNews");
  }

  /// Gets the stock price target chart
  Widget getStockPriceTarget(String ticker, String language) {
    return getChart(
        _getCachedFuture(
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
        _getCachedFuture('insiderTrading',
            () => _service.getInsiderTrading(ticker, language, _forceRefresh)),
        'insiderTrading',
        title: 'Insider Trading');
  }

  /// Gets the PE/PB ratio band chart
  Widget getPEPBRatioBandChart(String ticker, String language) {
    return getChart(
        _getCachedFuture('pbRatioBand',
            () => _service.getPEPBRatioBand(ticker, language, _forceRefresh)),
        'pePbRatioBand',
        title: 'PE/PB Ratio');
  }

  /// Gets the sector stocks chart
  Widget getSectorStocksChart(String ticker, String language) {
    return getChart(
        _getCachedFuture('sectorStocks',
            () => _service.getSectorStocks(ticker, language, _forceRefresh)),
        'sectorStocks',
        title: 'Sector Stocks');
  }

  /// Gets the candle stick chart
  Widget getCandleStickChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'candleStickChart',
            () =>
                _service.getCandleStickChart(ticker, language, _forceRefresh)),
        'candleStickChart',
        title: 'Technical Analysis');
  }

  /// Gets the combined charts
  Widget getCombinedCharts(String ticker, String language) {
    return Column(
      children: [
        getChart(
          _getCachedFuture(
              'combinedCharts',
              () =>
                  _service.getCombinedCharts(ticker, language, _forceRefresh)),
          'combinedCharts',
          title: 'Financial Performance',
        ),
        const SizedBox(height: 24),
        getReport(
          _getCachedFuture(
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
        _getCachedFuture('cashFlowChart',
            () => _service.getCashFlowChart(ticker, language, _forceRefresh)),
        'cashFlowChart',
        title: 'Cash Flow');
  }

  /// Gets the industrial relationship chart
  Widget getIndustrialRelationship(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'industrialRelationship',
            () => _service.getIndustrialRelationship(
                ticker, language, _forceRefresh)),
        'industrialRelationship',
        title: 'Industrial Relations');
  }

  /// Gets the sector comparison chart
  Widget getSectorComparison(String ticker, String language) {
    return getChart(
        _getCachedFuture(
            'sectorComparison',
            () =>
                _service.getSectorComparison(ticker, language, _forceRefresh)),
        'sectorComparison',
        title: 'Sector Comparison');
  }

  /// Gets the shareholder chart
  Widget getShareholderChart(String ticker, String language) {
    return getChart(
        _getCachedFuture(
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
    return AlertReportBuilder(
      future: _getCachedFuture('accountingRedFlags', () async {
        final data = await _service.getAccountingRedFlags(
            ticker, language, _forceRefresh);
        if (data['accountingRedflags'] != null) {
          final redFlags = data['accountingRedflags'];
          if (redFlags['incomeStatement'] != null) {
            redFlags['incomeStatement'] =
                await ImageUtils.getSignedUrl(redFlags['incomeStatement']);
          }
          if (redFlags['balanceSheet'] != null) {
            redFlags['balanceSheet'] =
                await ImageUtils.getSignedUrl(redFlags['balanceSheet']);
          }
        }
        return data;
      }),
      title: "Accounting Red Flags",
      reportKey: "accountingRedflags",
    );
  }
}
