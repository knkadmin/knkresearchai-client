import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:fa_ai_agent/constants/api_constants.dart';

class PaymentService {
  static Future<void> initiateCheckout(String stripeProductId) async {
    try {
      final checkoutSession = await _createCheckoutSession(stripeProductId);
      await _redirectToCheckout(checkoutSession['url']);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _createCheckoutSession(
      String stripeProductId) async {
    final user = AuthService().currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/create-checkout-session');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'productId': stripeProductId,
        'userId': user.uid,
        'email': user.email,
        'successUrl': Uri.base.origin,
        'cancelUrl': Uri.base.origin,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create checkout session: ${response.body}');
    }

    return json.decode(response.body);
  }

  static Future<void> _redirectToCheckout(String checkoutUrl) async {
    if (kIsWeb) {
      html.window.location.href = checkoutUrl;
    } else {
      if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
        await launchUrl(Uri.parse(checkoutUrl));
      } else {
        throw Exception('Could not launch checkout URL');
      }
    }
  }

  static Future<void> cancelSubscription() async {
    final user = AuthService().currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/cancel-subscription');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': user.uid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel subscription: ${response.body}');
    }
  }
}
