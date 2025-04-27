import 'package:fa_ai_agent/constants/subscription_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';
import 'package:rxdart/rxdart.dart';

class PaymentService {
  static final BehaviorSubject<bool> _isLoadingSubject =
      BehaviorSubject.seeded(false);
  static Stream<bool> get isLoadingStream => _isLoadingSubject.stream;

  static const String paymentBaseUrl =
      'https://knkresearchai-server-payment-1067859590559.australia-southeast1.run.app';

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

    final url = Uri.parse('$paymentBaseUrl/create-checkout-session');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'productId': stripeProductId,
        'userId': user.uid,
        'email': user.email,
        'successUrl': Uri.base.origin,
        'cancelUrl': Uri.base.origin,
        'trialDays': SubscriptionConstants.freeTrialDays,
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

    final url = Uri.parse('$paymentBaseUrl/cancel-subscription');
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

  static Future<void> resumeSubscription() async {
    final user = AuthService().currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final url = Uri.parse('$paymentBaseUrl/resume-subscription');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': user.uid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resume subscription: ${response.body}');
    }
  }

  static Future<void> openCustomerPortal() async {
    try {
      _isLoadingSubject.add(true);
      final user = AuthService().currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userData = await FirestoreService().getUserData(user.uid);
      final stripeCustomerId = userData?.subscription.stripeCustomerId;
      if (stripeCustomerId == null) {
        throw Exception('No Stripe customer ID found');
      }

      final url = Uri.parse('$paymentBaseUrl/create-customer-portal-session');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'stripeCustomerId': stripeCustomerId,
          'returnUrl': 'https://knkresearchai.com',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to create customer portal session: ${response.body}');
      }

      final session = json.decode(response.body);
      final portalUrl = session['url'];

      if (kIsWeb) {
        html.window.location.href = portalUrl;
      } else {
        if (await canLaunchUrl(Uri.parse(portalUrl))) {
          await launchUrl(Uri.parse(portalUrl));
        } else {
          throw Exception('Could not open billing portal');
        }
      }
    } finally {
      _isLoadingSubject.add(false);
    }
  }
}
