import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:logging/logging.dart';
import 'package:fa_ai_agent/config.dart';
import 'package:fa_ai_agent/services/search_cache_service.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';
import 'package:fa_ai_agent/constants/api_constants.dart';
import 'package:fa_ai_agent/models/financial_report.dart';

class AgentService {
  static final _log = Logger('AgentService');
  final _searchCacheService = SearchCacheService();
  final _firestoreService = FirestoreService();

  // Cache for active streams
  final Map<String, Stream<Map<String, dynamic>>> _activeStreams = {};
  // Cache for the latest data
  final Map<String, Map<String, dynamic>> _latestData = {};
  // Cache for section-specific streams
  final Map<String, Map<String, Stream<Map<String, dynamic>>>> _sectionStreams =
      {};

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
      Uri.https(Uri.parse(baseUrl).host, '/feedback'),
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
    final url = Uri.https(
        Uri.parse(baseUrl).host, 'ticker-symbol-search', {'q': query});

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

  // Get or create a shared stream for a ticker
  Stream<Map<String, dynamic>> _getSharedStream(
      String ticker, String language) {
    final streamKey = '$ticker-$language';

    if (!_activeStreams.containsKey(streamKey)) {
      _log.info('Creating new stream for $streamKey');

      final stream =
          _firestoreService.streamFinancialReport(ticker).map((report) {
        if (report == null) return <String, dynamic>{};

        // Convert FinancialReport to Map<String, dynamic>
        final Map<String, dynamic> data = <String, dynamic>{};

        if (report.businessOverview != null) {
          data['businessOverview'] = report.businessOverview!.toJson();
        }
        if (report.financialPerformance != null) {
          data['financialPerformance'] = report.financialPerformance!.toJson();
        }
        if (report.accountingRedFlags != null) {
          data['accountingRedflags'] = report.accountingRedFlags!.toJson();
        }
        if (report.competitorLandscape != null) {
          data['competitorLandscape'] = report.competitorLandscape!.toJson();
        }
        if (report.strategicOutlooks != null) {
          data['strategicOutlooks'] = report.strategicOutlooks!.toJson();
        }
        if (report.supplyChain != null) {
          data['supplyChain'] = report.supplyChain!.toJson();
        }
        if (report.recentNews != null) {
          data['recentNews'] = report.recentNews!.toJson();
        }
        if (report.cashFlowChart != null) {
          data['cashFlowChart'] = report.cashFlowChart!.toJson();
        }
        if (report.pePbRatioBand != null) {
          data['pePbRatioBand'] = report.pePbRatioBand!.toJson();
        }
        if (report.sectorStocks != null) {
          data['sectorStocks'] = report.sectorStocks!.toJson();
        }
        if (report.combinedCharts != null) {
          data['combinedCharts'] = report.combinedCharts!.toJson();
        }
        if (report.stockPriceTarget != null) {
          data['stockPriceTarget'] = report.stockPriceTarget!.toJson();
        }
        if (report.insiderTrading != null) {
          data['insiderTrading'] = report.insiderTrading!.toJson();
        }
        if (report.candleStickChart != null) {
          data['candleStickChart'] = report.candleStickChart!.toJson();
        }
        if (report.shareholderChart != null) {
          data['shareholderChart'] = report.shareholderChart!.toJson();
        }
        if (report.industrialRelationship != null) {
          data['industrialRelationship'] =
              report.industrialRelationship!.toJson();
        }
        if (report.sectorComparison != null) {
          data['sectorComparison'] = report.sectorComparison!.toJson();
        }
        if (report.epsVsStockPriceChart != null) {
          data['epsVsStockPriceChart'] = report.epsVsStockPriceChart!.toJson();
        }
        if (report.financialMetrics != null) {
          data['financialMetrics'] = report.financialMetrics!.toJson();
        }

        // Add cache timestamp
        data['cachedAt'] = report.lastUpdated?.microsecondsSinceEpoch;

        // Update latest data cache
        _latestData[streamKey] = data;

        return data;
      }).asBroadcastStream();

      _activeStreams[streamKey] = stream;
    }

    return _activeStreams[streamKey]!;
  }

  // Clean up streams when they're no longer needed
  void disposeStream(String ticker, String language) {
    final streamKey = '$ticker-$language';
    _activeStreams.remove(streamKey);
    _latestData.remove(streamKey);
    _sectionStreams.remove(streamKey);
  }

  // Clear all active streams
  void clearStreams() {
    _activeStreams.clear();
    _latestData.clear();
    _sectionStreams.clear();
  }

  // Get a section-specific stream
  Stream<Map<String, dynamic>> getSectionStream(
      String ticker, String language, String section,
      {bool forceRefresh = false}) {
    if (forceRefresh) {
      clearStreams();
    }

    final streamKey = '$ticker-$language';
    final sectionStreams = _sectionStreams.putIfAbsent(streamKey, () => {});

    if (!sectionStreams.containsKey(section)) {
      final sharedStream = _getSharedStream(ticker, language);
      sectionStreams[section] =
          sharedStream.map((data) => {section: data[section]});
    }

    return sectionStreams[section]!;
  }

  // Keep the individual getter methods for backward compatibility
  // They will now use the section-specific streams
  Future<Map<String, dynamic>> getBusinessOverview(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'businessOverview',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getFinancialPerformance(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'financialPerformance',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getAccountingRedFlags(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'accountingRedflags',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getCompetitorLandscape(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'competitorLandscape',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getStrategicOutlooks(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'strategicOutlooks',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getSupplyChain(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'supplyChain',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getRecentNews(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'recentNews',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getPEPBRatioBand(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'pePbRatioBand',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getSectorStocks(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'sectorStocks',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getStockPriceTarget(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'stockPriceTarget',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getInsiderTrading(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'insiderTrading',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getCandleStickChart(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'candleStickChart',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getCombinedCharts(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'combinedCharts',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getCashFlowChart(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'cashFlowChart',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getIndustrialRelationship(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'industrialRelationship',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getSectorComparison(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'sectorComparison',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getShareholderChart(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'shareholderChart',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getEPSvsStockPriceChart(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'epsVsStockPriceChart',
        forceRefresh: forceRefresh);
    return await stream.first;
  }

  Future<Map<String, dynamic>> getFinancialMetrics(
      String ticker, String language, bool forceRefresh) async {
    final stream = getSectionStream(ticker, language, 'financialMetrics',
        forceRefresh: forceRefresh);
    return await stream.first;
  }
}
