import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:logging/logging.dart';

class AgentService {
  static final _log = Logger('AgentService');

  AgentService() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  final String baseUrl =
      'knkresearchai-server-1067859590559.australia-southeast1.run.app';

  final BehaviorSubject<Map<String, bool>> loadingStateSubject =
      BehaviorSubject();

  final Map<String, bool> loadingState = {};

  Future<bool> sendFeedback(String email, String message) async {
    final response = await http.post(
      Uri.https(baseUrl, '/feedback'),
      headers: {'Content-Type': 'application/json'},
      body: convert.jsonEncode({
        'email': email,
        'message': message,
      }),
    );
    return Future.value(response.statusCode == 200);
  }

  Future<Map<String, dynamic>> searchTickerSymbol(String query) async {
    final url = Uri.https(baseUrl, 'ticker-symbol-search', {'q': query});
    final response = await http.get(url);
    final jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    return Future.value(jsonResponse);
  }

  Future<Map<String, dynamic>> getBusinessOverview(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/report-advanced/business-overview", ticker, language,
        forceRefresh, "business-overview");
  }

  Future<Map<String, dynamic>> getFinancialPerformance(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/report-advanced/financial-performance", ticker, language,
        forceRefresh, "financial-performance");
  }

  Future<Map<String, dynamic>> getCompetitorLandscape(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/report-advanced/competitor-landscape", ticker, language,
        forceRefresh, "competitor-landscape");
  }

  Future<Map<String, dynamic>> getStrategicOutlooks(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/report-advanced/strategic-outlooks", ticker, language,
        forceRefresh, "strategic-outlooks");
  }

  Future<Map<String, dynamic>> getSupplyChain(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/report-advanced/supply-chain", ticker, language,
        forceRefresh, "supply-chain");
  }

  Future<Map<String, dynamic>> getRecentNews(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/report-advanced/recent-news", ticker, language,
        forceRefresh, "recent-news");
  }

  Future<Map<String, dynamic>> getPEPBRatioBand(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/pe-pb-ratio-band", ticker, language,
        forceRefresh, "pe-pb-ratio-band");
  }

  Future<Map<String, dynamic>> getSectorStocks(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/sector-stocks", ticker, language,
        forceRefresh, "sector-stocks");
  }

  Future<Map<String, dynamic>> getStockPriceTarget(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/stock-price-target", ticker, language,
        forceRefresh, "stock-price-target");
  }

  Future<Map<String, dynamic>> getInsiderTrading(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/insider-trading", ticker, language,
        forceRefresh, "insider-trading");
  }

  Future<Map<String, dynamic>> getCandleStickChart(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/candle-stick-chart", ticker, language,
        forceRefresh, "candle-stick-chart");
  }

  Future<Map<String, dynamic>> getCombinedCharts(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/combined-charts", ticker, language,
        forceRefresh, "combined-charts");
  }

  Future<Map<String, dynamic>> getCashFlowChart(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/cash-flow-chart", ticker, language,
        forceRefresh, "cash-flow-chart");
  }

  Future<Map<String, dynamic>> getIndustrialRelationship(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/industrial-relationship", ticker,
        language, forceRefresh, "industrial-relationship");
  }

  Future<Map<String, dynamic>> getSectorComparison(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/sector-comparison", ticker, language,
        forceRefresh, "sector-comparison");
  }

  Future<Map<String, dynamic>> getShareholderChart(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/shareholder-chart", ticker, language,
        forceRefresh, "shareholder-chart");
  }

  Future<Map<String, dynamic>> getFinancialMetrics(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/tables-advanced/financial-metrics", ticker, language,
        forceRefresh, "financial-metrics");
  }

  Future<Map<String, dynamic>> getOutput(String endpoint, String ticker,
      String language, bool forceRefresh, String cacheKey) async {
    _log.info("Requesting $endpoint");
    loadingState[cacheKey] = true;
    loadingStateSubject.add(loadingState);
    final box = Hive.box('settings');
    final String cacheReportKey = "$ticker-$language-$cacheKey";
    final String? cachedReport = box.get(cacheReportKey);
    if (cachedReport == null || forceRefresh) {
      final url = Uri.https(baseUrl, endpoint,
          {'code': ticker, 'language': language.toLowerCase()});
      final response = await http.get(url);
      final jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      final output = jsonResponse['output'];
      output["cachedAt"] = DateTime.now().microsecondsSinceEpoch;
      box.put(cacheReportKey, convert.jsonEncode(output));
      loadingState[cacheKey] = false;
      loadingStateSubject.add(loadingState);
      return Future.value(output);
    } else {
      loadingState[cacheKey] = false;
      loadingStateSubject.add(loadingState);
      return Future.value(convert.jsonDecode(cachedReport));
    }
  }
}
