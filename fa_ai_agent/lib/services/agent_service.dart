import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:async'; // Added for Future.value and Stream transformations
import 'package:logging/logging.dart';
import 'package:fa_ai_agent/config.dart';
import 'package:fa_ai_agent/services/search_cache_service.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';
import 'package:fa_ai_agent/constants/api_constants.dart';
import 'package:fa_ai_agent/models/financial_report.dart';
import 'package:fa_ai_agent/services/auth_service.dart';

class AgentService {
  static final _log = Logger('AgentService');
  final _searchCacheService = SearchCacheService();
  final _firestoreService = FirestoreService();

  // Cache for active Firestore streams (charts)
  final Map<String, Stream<Map<String, dynamic>>> _activeFirestoreStreams = {};
  // Cache for the latest data (both charts from Firestore and text reports from API)
  final Map<String, Map<String, dynamic>> _latestData = {};
  // Cache for section-specific streams (both types)
  final Map<String, Map<String, Stream<Map<String, dynamic>>>> _sectionStreams =
      {};

  // Define text report sections and their API paths
  static const Map<String, String> _textReportSections = {
    'businessOverview': 'report-advanced/business-overview',
    'financialPerformance': 'report-advanced/financial-performance',
    'strategicOutlooks': 'report-advanced/strategic-outlooks',
    'accountingRedflags':
        'report-advanced/accounting-redflags', // Corrected key
    'supplyChain': 'report-advanced/supply-chain',
    'competitorLandscape': 'report-advanced/competitor-landscape',
    'recentNews':
        'report-advanced/recent-news', // Assuming recentNews is also text-based
    'financialMetrics':
        'tables-advanced/financial-metrics', // Added financial metrics
    'technicalAnalysis': 'report-advanced/technical-analysis',
    'epsVsStockPriceAnalysis': 'report-advanced/eps-vs-stock-price-analysis',
  };

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

  // Get current user's ID
  String? get currentUserId => AuthService().currentUser?.uid;

  // Get current user's token
  Future<String?> getCurrentUserToken() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

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
    if (cachedResults != null && cachedResults.isNotEmpty) {
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

  // Get or create a shared Firestore stream for CHART data
  Stream<Map<String, dynamic>> _getSharedFirestoreStream(
      String ticker, String language) {
    final streamKey = '$ticker-$language';

    if (!_activeFirestoreStreams.containsKey(streamKey)) {
      _log.info('Creating new Firestore stream for CHART data for $streamKey');

      final stream =
          _firestoreService.streamFinancialReport(ticker).map((report) {
        _log.info('Received Firestore update for $streamKey');
        if (report == null) return <String, dynamic>{};

        // Convert ONLY CHART FinancialReport sections to Map<String, dynamic>
        final Map<String, dynamic> chartData = <String, dynamic>{};

        // --- CHART SECTIONS ---
        if (report.cashFlowChart != null) {
          chartData['cashFlowChart'] = report.cashFlowChart!.toJson();
        }
        if (report.pePbRatioBand != null) {
          chartData['pePbRatioBand'] = report.pePbRatioBand!.toJson();
        }
        if (report.sectorStocks != null) {
          chartData['sectorStocks'] = report.sectorStocks!.toJson();
        }
        if (report.combinedCharts != null) {
          chartData['combinedCharts'] = report.combinedCharts!.toJson();
        }
        if (report.stockPriceTarget != null) {
          // Assuming this might contain chartable data or is fetched this way
          chartData['stockPriceTarget'] = report.stockPriceTarget!.toJson();
        }
        if (report.insiderTrading != null) {
          // Assuming this might contain chartable data or is fetched this way
          chartData['insiderTrading'] = report.insiderTrading!.toJson();
        }
        if (report.candleStickChart != null) {
          chartData['candleStickChart'] = report.candleStickChart!.toJson();
        }
        if (report.shareholderChart != null) {
          chartData['shareholderChart'] = report.shareholderChart!.toJson();
        }
        if (report.industrialRelationship != null) {
          // Assuming this might contain chartable data or is fetched this way
          chartData['industrialRelationship'] =
              report.industrialRelationship!.toJson();
        }
        if (report.sectorComparison != null) {
          // Assuming this might contain chartable data or is fetched this way
          chartData['sectorComparison'] = report.sectorComparison!.toJson();
        }
        if (report.epsVsStockPriceChart != null) {
          chartData['epsVsStockPriceChart'] =
              report.epsVsStockPriceChart!.toJson();
        }
        // FinancialMetrics is now fetched via API, removed from here
        // --- END CHART SECTIONS ---

        // Add cache timestamp from Firestore document
        chartData['cachedAt'] = report.lastUpdated?.microsecondsSinceEpoch;

        // Update latest data cache ONLY with chart data for this stream
        // Ensure existing text report data for this key is preserved
        _latestData[streamKey] = {
          ...?(_latestData[
              streamKey]), // Preserve existing data (potentially text reports)
          ...chartData // Overwrite with new chart data
        };
        _log.fine(
            'Updated _latestData for $streamKey with chart data. Keys: ${_latestData[streamKey]?.keys}');

        return chartData; // Return only chart data from this stream mapper
      }).asBroadcastStream(); // Use shareReplay ??
      // Using shareValueSeeded or similar might be better if initial value is needed
      // Consider error handling within the stream

      _activeFirestoreStreams[streamKey] = stream;
    }

    return _activeFirestoreStreams[streamKey]!;
  }

  // Fetch text report section from the API or local cache
  Future<Map<String, dynamic>> _fetchTextReportSection(
      String ticker, String language, String section,
      {bool forceRefresh = false}) async {
    final path = _textReportSections[section];
    if (path == null) {
      _log.warning('Invalid text report section requested: $section');
      return {'error': 'Invalid section'}; // Return error map
    }

    final cacheKey = '$ticker-$language-$section';
    final Box<String> box = Hive.box<String>('report_section_cache');

    // 1. Check local Hive cache if not forcing refresh
    if (!forceRefresh) {
      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        try {
          final cachedData =
              convert.jsonDecode(cachedJson) as Map<String, dynamic>;
          _log.info("CACHE HIT (Local): Using Hive cache for $cacheKey");
          return cachedData;
        } catch (e) {
          _log.warning(
              "Failed to decode cached data for $cacheKey from Hive: $e. Deleting invalid entry.");
          await box.delete(cacheKey); // Delete corrupted entry
        }
      } else {
        _log.fine("CACHE MISS (Local): No Hive cache found for $cacheKey");
      }
    } else {
      _log.info("CACHE BYPASS (Local): forceRefresh=true for $cacheKey");
    }

    // 2. Fetch from API if cache miss or forceRefresh
    final queryParams = {
      'code': ticker,
      'language': language,
    };

    // Add userId and token to query parameters if available
    final userId = currentUserId;
    final token = await getCurrentUserToken();
    if (userId != null) {
      queryParams['userId'] = userId;
    }
    if (token != null) {
      queryParams['token'] = token;
    }

    final url = Uri.https(Uri.parse(baseUrl).host, path, queryParams);

    _log.info('Fetching text report for $section from API: $url');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final jsonResponse =
            convert.jsonDecode(response.body) as Map<String, dynamic>;
        _log.info('Successfully fetched $section for $ticker from API');

        // Extract the actual content from the 'output' key
        if (jsonResponse.containsKey('output')) {
          final outputData =
              jsonResponse['output'] as Map<String, dynamic>? ?? {};

          // 3. Save to Hive cache
          try {
            final String jsonToCache = convert.jsonEncode(outputData);
            await box.put(cacheKey, jsonToCache);
            _log.info(
                "CACHE WRITE (Local): Saved API response for $cacheKey to Hive.");
          } catch (e) {
            _log.severe(
                "Failed to encode or save data for $cacheKey to Hive: $e");
          }
          return outputData;
        } else {
          _log.warning(
              "API response for $section ($ticker) missing 'output' key. Response: $jsonResponse");
          return {'error': "API response structure error for $section"};
        }
      } else {
        _log.severe(
            'Error fetching $section for $ticker: ${response.statusCode} ${response.body}');
        return {
          'error': 'Failed to load $section',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      _log.severe('Exception fetching $section for $ticker: $e');
      return {'error': 'Exception fetching $section: $e'};
    }
  }

  // Clean up streams when they're no longer needed
  void disposeStream(String ticker, String language) {
    final streamKey = '$ticker-$language';
    _activeFirestoreStreams.remove(streamKey); // Changed from _activeStreams
    _latestData.remove(streamKey);
    _sectionStreams.remove(streamKey);
    _log.info('Disposed streams and caches for $streamKey');
  }

  // Clear all active streams and caches
  void clearStreams() {
    _activeFirestoreStreams.clear(); // Changed from _activeStreams
    _latestData.clear();
    _sectionStreams.clear();
    _log.info('Cleared all active streams and caches');
  }

  // Get a section-specific stream (handles both text reports via API and charts via Firestore)
  Stream<Map<String, dynamic>> getSectionStream(
      String ticker, String language, String section,
      {bool forceRefresh = false}) {
    final streamKey = '$ticker-$language';
    final sectionCache = _sectionStreams.putIfAbsent(streamKey, () => {});
    _log.fine(
        "getSectionStream called for: $section ($streamKey), forceRefresh: $forceRefresh");

    // If stream for this section already exists, return it
    if (!forceRefresh && sectionCache.containsKey(section)) {
      _log.info(
          "CACHE HIT (Stream): Returning cached stream for $section ($streamKey)");
      return sectionCache[section]!;
    }

    _log.fine(
        "No cached stream found or forceRefresh=true for $section ($streamKey)");

    // --- Logic for Text Reports (API Fetch) ---
    if (_textReportSections.containsKey(section)) {
      _log.info(
          "Requesting TEXT section: $section ($streamKey), ForceRefresh: $forceRefresh");
      // Check cache first (_latestData)
      final cachedData = _latestData[streamKey]?[section];
      _log.fine(
          "Checked _latestData for $section ($streamKey). Found data: ${cachedData != null}");
      final bool needsFetch = forceRefresh || cachedData == null;

      Stream<Map<String, dynamic>> stream;

      if (needsFetch) {
        _log.info(
            "CACHE MISS or REFRESH: Fetching $section from API (needed: $needsFetch)");
        // Use Future.asStream to convert the API call Future into a Stream
        stream = Future.microtask(() async {
          final fetchedData = await _fetchTextReportSection(
              ticker, language, section,
              forceRefresh: forceRefresh);
          if (fetchedData.containsKey('error')) {
            // Propagate error as stream error event
            throw Exception(
                "API/Cache Error for $section: ${fetchedData['error']}");
          }
          // Update cache
          _latestData.putIfAbsent(streamKey, () => {})[section] = fetchedData;
          _log.fine(
              'Updated _latestData for $streamKey with API data for $section. Keys: ${_latestData[streamKey]?.keys}');
          return fetchedData; // Emit the actual data, not the wrapped map
        }).asStream();
      } else {
        _log.info(
            "CACHE HIT (Data): Using cached data from _latestData for $section ($streamKey)");
        // If cached data exists and no refresh needed, return a stream that emits it once
        // Ensure cached data is not null or an error map before emitting
        if (cachedData != null && !cachedData.containsKey('error')) {
          stream = Stream.value(
              cachedData); // Emit the actual data, not the wrapped map
        } else {
          // If cache is empty or contains an error, return an empty stream or error stream?
          // Let's return an empty stream for now, maybe log warning.
          _log.warning(
              "Cached data for $section ($streamKey) is null or an error, returning empty stream.");
          stream = Stream.empty(); // Or Stream.error(..)?
        }
      }

      // Cache the stream itself
      _log.fine("Caching stream for $section ($streamKey) with shareReplay.");
      sectionCache[section] = stream.shareReplay(
          maxSize: 1); // Cache the stream and replay last value
      return sectionCache[section]!;

      // --- Logic for Chart Reports (Firestore Stream) ---
    } else {
      _log.info(
          "Requesting CHART section: $section ($streamKey), ForceRefresh: $forceRefresh");
      // If forceRefresh, we might need to clear existing Firestore stream?
      // For now, _getSharedFirestoreStream handles caching internally.
      // If forceRefresh is true, we should ensure the shared stream is potentially recreated or refetches.
      // Let's clear the specific stream cache entry if forceRefresh is true
      if (forceRefresh) {
        _activeFirestoreStreams
            .remove(streamKey); // Force recreation on next call
        // Also clear the section stream cache entry
        sectionCache.remove(section);
        _log.info(
            "Cleared active Firestore stream due to forceRefresh for $streamKey");
      }

      final sharedFirestoreStream = _getSharedFirestoreStream(ticker, language);

      // Map the shared stream to emit only the requested chart section
      final chartStream = sharedFirestoreStream
          .map((data) {
            _log.fine(
                "Mapping Firestore data for chart section $section ($streamKey). Available keys: ${data.keys}");
            return {section: data[section]};
          })
          .where((dataMap) =>
              dataMap[section] !=
              null) // Only emit if data exists for the section
          .distinct(); // Only emit when the section data changes

      sectionCache[section] = chartStream.shareReplay(
          maxSize: 1); // Cache the stream and replay last value
      return sectionCache[section]!;
    }
  }

  // Keep the individual getter methods for backward compatibility
  // They will now use the section-specific streams
  Stream<Map<String, dynamic>> getBusinessOverview(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'businessOverview',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getFinancialPerformance(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'financialPerformance',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getAccountingRedFlags(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'accountingRedflags',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getCompetitorLandscape(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'competitorLandscape',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getStrategicOutlooks(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'strategicOutlooks',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getSupplyChain(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'supplyChain',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getRecentNews(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'recentNews',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getPEPBRatioBand(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'pePbRatioBand',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getSectorStocks(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'sectorStocks',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getStockPriceTarget(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'stockPriceTarget',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getInsiderTrading(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'insiderTrading',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getCandleStickChart(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'candleStickChart',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getTechnicalAnalysis(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'technicalAnalysis',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getCombinedCharts(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'combinedCharts',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getCashFlowChart(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'cashFlowChart',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getIndustrialRelationship(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'industrialRelationship',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getSectorComparison(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'sectorComparison',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getShareholderChart(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'shareholderChart',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getEPSvsStockPriceChart(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'epsVsStockPriceChart',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getEPSvsStockPriceAnalysis(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'epsVsStockPriceAnalysis',
        forceRefresh: forceRefresh);
  }

  Stream<Map<String, dynamic>> getFinancialMetrics(
      String ticker, String language, bool forceRefresh) {
    return getSectionStream(ticker, language, 'financialMetrics',
        forceRefresh: forceRefresh);
  }
}
