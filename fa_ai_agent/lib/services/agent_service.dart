import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:logging/logging.dart';
import 'package:fa_ai_agent/config.dart';
import 'package:fa_ai_agent/services/search_cache_service.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';
import 'package:fa_ai_agent/constants/api_constants.dart';

class AgentService {
  static final _log = Logger('AgentService');
  final _searchCacheService = SearchCacheService();
  final _firestoreService = FirestoreService();

  AgentService() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  final String baseUrl = ApiConstants.baseUrl;

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
    _log.info("Searching for ticker symbol: $query");

    // Check cache first
    final cachedResults = await _searchCacheService.getCachedResults(query);
    if (cachedResults != null) {
      _log.info("Using cached results for query: $query");
      return {'quotes': cachedResults};
    }

    _log.info("Cache miss, fetching from remote for query: $query");
    final url = Uri.https(baseUrl, 'ticker-symbol-search', {'q': query});

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;

        // Cache the results if we got valid data
        if (jsonResponse['quotes'] != null) {
          await _searchCacheService.cacheSearchResults(
            query,
            List<Map<String, dynamic>>.from(jsonResponse['quotes']),
          );
          _log.info("Cached results for query: $query");
        }

        return jsonResponse;
      } else {
        _log.severe('Error searching ticker symbol: ${response.statusCode}');
        throw Exception('Failed to search ticker symbol');
      }
    } catch (e) {
      _log.severe('Error searching ticker symbol: $e');
      rethrow;
    }
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

  Future<Map<String, dynamic>> getAccountingRedFlags(
      String ticker, String language, bool forceRefresh) {
    _log.info("Requesting accounting red flags for $ticker");
    return getOutput("/report-advanced/accounting-redflags", ticker, language,
        forceRefresh, "accounting-redflags");
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

  Future<Map<String, dynamic>> getEPSvsStockPriceChart(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/charts-advanced/eps-vs-stock-price-chart", ticker,
        language, forceRefresh, "eps-vs-stock-price-chart");
  }

  Future<Map<String, dynamic>> getFinancialMetrics(
      String ticker, String language, bool forceRefresh) {
    return getOutput("/tables-advanced/financial-metrics", ticker, language,
        forceRefresh, "financial-metrics");
  }

  Future<Map<String, dynamic>> getOutput(String endpoint, String ticker,
      String language, bool forceRefresh, String cacheKey) async {
    _log.info("Requesting $endpoint");
    try {
      loadingState[cacheKey] = true;
      loadingStateSubject.add(loadingState);

      final box = Hive.box('settings');
      final String cacheReportKey = "$ticker-$language-$cacheKey";
      final String? cachedReport = box.get(cacheReportKey);

      if (cachedReport == null || forceRefresh) {
        // Get user ID and token from Firestore
        String userId = '';
        String token = '';
        if (_firestoreService.isCurrentUserAuthed()) {
          final userDoc = await _firestoreService.currentUserDoc.get();
          userId = userDoc.id;
          token = userDoc.data()?['token'] as String? ?? '';
        }

        final url = Uri.https(baseUrl, endpoint, {
          'code': ticker,
          'language': language.toLowerCase(),
          'userId': userId,
          'token': token,
        });

        final response = await http.get(url);

        if (response.statusCode == 500) {
          _log.warning(
              "Request failed with status code: ${response.statusCode}");
          loadingState[cacheKey] = false;
          loadingStateSubject.add(loadingState);
          return {};
        }

        final jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;
        final output = jsonResponse['output'];

        output["cachedAt"] = DateTime.now().microsecondsSinceEpoch;
        box.put(cacheReportKey, convert.jsonEncode(output));
        loadingState[cacheKey] = false;
        loadingStateSubject.add(loadingState);
        return output;
      } else {
        loadingState[cacheKey] = false;
        loadingStateSubject.add(loadingState);
        return convert.jsonDecode(cachedReport);
      }
    } catch (e) {
      _log.severe('Error in getOutput: $e');
      loadingState[cacheKey] = false;
      loadingStateSubject.add(loadingState);
      return {};
    }
  }
}
