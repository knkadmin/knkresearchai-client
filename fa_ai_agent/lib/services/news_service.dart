import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fa_ai_agent/config/environment.dart';
import 'package:fa_ai_agent/models/news_article.dart';

class NewsService {
  final String _baseUrl = EnvironmentConfig.current.newsApiBaseUrl;

  Future<List<NewsArticle>> getGeneralNews({int page = 1}) async {
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

  Future<List<NewsArticle>> getPressReleasesLatest({int page = 1}) async {
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

  Future<List<NewsArticle>> getStockLatestNews({int page = 1}) async {
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

  Future<List<NewsArticle>> getStockNews(
      {required String symbols, int page = 1}) async {
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
}
