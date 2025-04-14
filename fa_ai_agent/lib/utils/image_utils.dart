import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fa_ai_agent/constants/api_constants.dart';

class ImageUtils {
  static Future<String> getSignedUrl(String fileName) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/signed-image-url')
        .replace(queryParameters: {'filename': fileName});
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to get signed URL: ${response.body}');
    }
    final body = jsonDecode(response.body);
    final imageUrl = body['url'];
    return imageUrl;
  }
}
