import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchCacheService {
  static const String _cachePrefix = 'search_cache_';
  static const Duration _cacheDuration =
      Duration(hours: 24); // Cache for 24 hours

  Future<void> cacheSearchResults(
      String query, List<Map<String, dynamic>> results) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cachePrefix + query.toLowerCase();

    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'results': results,
    };

    await prefs.setString(cacheKey, jsonEncode(cacheData));
  }

  Future<List<Map<String, dynamic>>?> getCachedResults(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cachePrefix + query.toLowerCase();

    final cachedData = prefs.getString(cacheKey);
    if (cachedData == null) return null;

    final decodedData = jsonDecode(cachedData) as Map<String, dynamic>;
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(decodedData['timestamp']);

    // Check if cache is expired
    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      await prefs.remove(cacheKey);
      return null;
    }

    return List<Map<String, dynamic>>.from(decodedData['results']);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
