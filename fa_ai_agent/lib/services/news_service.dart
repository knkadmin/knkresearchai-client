import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fa_ai_agent/config/environment.dart';
import 'package:fa_ai_agent/models/news_article.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NewsService {
  final String _baseUrl = EnvironmentConfig.current.newsApiBaseUrl;

  // Box name for news cache
  static const String _newsCacheBoxName = 'news_cache';

  // Cache duration (10 minutes)
  static const Duration _cacheDuration = Duration(minutes: 10);

  // Lazily initialize the box when first needed
  Box? _cacheBox;

  // Get the cache box, opening it if needed
  Future<Box> get cacheBox async {
    if (_cacheBox == null || !_cacheBox!.isOpen) {
      _cacheBox = await Hive.openBox(_newsCacheBoxName);
    }
    return _cacheBox!;
  }

  Future<List<NewsArticle>> getGeneralNews({int page = 0}) async {
    final cacheKey = 'general-news-$page';
    return _getWithCache(cacheKey, () => _fetchGeneralNews(page: page));
  }

  Future<List<NewsArticle>> getPressReleasesLatest({int page = 0}) async {
    final cacheKey = 'press-releases-$page';
    return _getWithCache(cacheKey, () => _fetchPressReleasesLatest(page: page));
  }

  Future<List<NewsArticle>> getStockLatestNews({int page = 0}) async {
    final cacheKey = 'stock-latest-news-$page';
    return _getWithCache(cacheKey, () => _fetchStockLatestNews(page: page));
  }

  Future<List<NewsArticle>> getStockNews(
      {required String symbols, int page = 0}) async {
    final cacheKey = 'stock-news-$symbols-$page';
    return _getWithCache(
        cacheKey, () => _fetchStockNews(symbols: symbols, page: page));
  }

  // Helper method to handle caching logic using Hive
  Future<List<NewsArticle>> _getWithCache(
      String cacheKey, Future<List<NewsArticle>> Function() fetchData) async {
    final box = await cacheBox;

    // Check if we have cached data
    if (box.containsKey(cacheKey)) {
      final cachedItem = box.get(cacheKey);

      if (cachedItem != null) {
        final Map<String, dynamic> cachedData = jsonDecode(cachedItem);
        final timestamp = DateTime.parse(cachedData['timestamp']);
        final now = DateTime.now();

        // Check if cache is still fresh (less than 10 minutes old)
        if (now.difference(timestamp) < _cacheDuration) {
          print('Using cached news data for: $cacheKey');

          // Deserialize the cached news articles
          final List<dynamic> articlesJson = cachedData['data'];
          return articlesJson
              .map((json) => NewsArticle.fromJson(json))
              .toList();
        }

        print('Cache expired for: $cacheKey');
      }
    } else {
      print('No cache found for: $cacheKey');
    }

    try {
      // Fetch fresh data
      final data = await fetchData();

      // Save to cache with timestamp
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data.map((article) => article.toJson()).toList(),
      };

      await box.put(cacheKey, jsonEncode(cacheData));

      return data;
    } catch (e) {
      // If we have any cached data and encounter an error, return stale data as fallback
      if (box.containsKey(cacheKey)) {
        final cachedItem = box.get(cacheKey);

        if (cachedItem != null) {
          print('Error fetching fresh data, using stale cache for: $cacheKey');
          final Map<String, dynamic> cachedData = jsonDecode(cachedItem);
          final List<dynamic> articlesJson = cachedData['data'];
          return articlesJson
              .map((json) => NewsArticle.fromJson(json))
              .toList();
        }
      }
      // Otherwise, rethrow the error
      rethrow;
    }
  }

  // Original API methods renamed to separate API calls from caching logic
  Future<List<NewsArticle>> _fetchGeneralNews({int page = 0}) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/general-news?page=$page'));
    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      if (body is List) {
        return body.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to parse general news. Expected a list.');
      }
    } else {
      throw Exception(
          'Failed to load general news. Status code: ${response.statusCode}');
    }
  }

  Future<List<NewsArticle>> _fetchPressReleasesLatest({int page = 0}) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/press-releases-latest?page=$page'));
    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      if (body is List) {
        return body.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to parse latest press releases. Expected a list.');
      }
    } else {
      throw Exception(
          'Failed to load latest press releases. Status code: ${response.statusCode}');
    }
  }

  Future<List<NewsArticle>> _fetchStockLatestNews({int page = 0}) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/stock-latest-news?page=$page'));
    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      if (body is List) {
        return body.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to parse latest stock news. Expected a list.');
      }
    } else {
      throw Exception(
          'Failed to load latest stock news. Status code: ${response.statusCode}');
    }
  }

  Future<List<NewsArticle>> _fetchStockNews(
      {required String symbols, int page = 0}) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/stock-news/$symbols?page=$page'));
    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(response.body);
      if (body is List) {
        return body.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to parse stock news for $symbols. Expected a list.');
      }
    } else {
      throw Exception(
          'Failed to load stock news for $symbols. Status code: ${response.statusCode}');
    }
  }

  // Method to manually clear the cache if needed
  Future<void> clearCache() async {
    final box = await cacheBox;
    await box.clear();
    print('News cache cleared');
  }
}
