import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
import '../services/pricing_service.dart';
import '../gradient_text.dart';
import '../models/subscription_type.dart';
import '../models/user.dart';
import '../constants/subscription_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;

// Stripe product IDs
const String kStarterMonthlyProductId = 'prod_starter_monthly';
const String kStarterYearlyProductId = 'prod_starter_yearly';
const String kProMonthlyProductId = 'prod_pro_monthly';

class StripeProduct {
  final String id;
  final String name;
  final String description;
  final String priceId;
  final int amount;
  final String currency;
  final String? interval;
  final String type;

  StripeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.priceId,
    required this.amount,
    required this.currency,
    this.interval,
    required this.type,
  });

  factory StripeProduct.fromJson(Map<String, dynamic> json) {
    return StripeProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      priceId: json['price_id'],
      amount: json['amount'],
      currency: json['currency'],
      interval: json['interval'],
      type: json['type'] ?? '',
    );
  }
}

class PricingPlan {
  final String type;
  final int amount;
  final String stripeProductId;
  final int? discountedAmount;

  PricingPlan({
    required this.type,
    required this.amount,
    required this.stripeProductId,
    this.discountedAmount,
  });

  factory PricingPlan.fromFirestore(Map<String, dynamic> data) {
    return PricingPlan(
      type: data['type'] ?? '',
      amount: data['amount'] ?? 0,
      stripeProductId: data['stripeProductId'] ?? '',
      discountedAmount: data['discountedAmount'],
    );
  }
}

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  bool _isLoading = false;
  final PricingService _pricingService = PricingService();

  @override
  void initState() {
    super.initState();
    _pricingService.initialize();
  }

  Future<void> _updateSubscription(SubscriptionType plan) async {
    if (plan == SubscriptionType.free) {
      // Show confirmation dialog for downgrading to Free plan
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Plan Change'),
          content: const Text(
            'Are you sure you want to downgrade to Free plan? You will no longer have unlimited access to all U.S. listed companies (except for Mag 7)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          // Show loading overlay
          if (mounted) {
            setState(() => _isLoading = true);
          }

          // Cancel the current subscription
          await PaymentService.cancelSubscription();

          // Update the user's subscription in Firestore
          final user = AuthService().currentUser;
          if (user != null) {
            await FirestoreService().updateUserSubscription(
              user.uid,
              Subscription(
                type: SubscriptionType.free,
                updatedAt: DateTime.now(),
                paymentMethod: null,
              ),
            );
          }

          // Navigate back
          if (mounted) {
            setState(() => _isLoading = false);
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error',
              text: 'Failed to cancel subscription: ${e.toString()}',
            );
          }
        }
      }
      return;
    }

    // For paid plans, initiate Stripe payment flow
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final pricingPlan = _pricingService.pricingPlans[plan.value];
      if (pricingPlan == null) {
        throw Exception('Pricing plan not found for type: ${plan.value}');
      }

      await PaymentService.initiateCheckout(pricingPlan.stripeProductId);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Payment Failed',
          text: e.toString(),
        );
      }
    }
  }

  String _formatPrice(int price) {
    return '\$${(price / 100).toStringAsFixed(0)}';
  }

  String _getFreePrice() {
    return _formatPrice(0);
  }

  String _getStarterPriceFromFirestore() {
    final starterPlan = _pricingService.pricingPlans['starter'];
    if (starterPlan == null) {
      return '\$0.00';
    }

    return _formatPrice(starterPlan.discountedAmount ?? starterPlan.amount);
  }

  String _getStarterRegularPriceFromFirestore() {
    final starterPlan = _pricingService.pricingPlans['starter'];
    if (starterPlan == null) {
      return '20';
    }

    return _formatPrice(starterPlan.amount).substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        icon: const Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pricing Content
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Text(
                        'Choose Your Plan',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the plan that best fits your needs',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'All prices are in USD',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Pricing Cards
                      ListenableBuilder(
                        listenable: _pricingService,
                        builder: (context, _) {
                          if (_pricingService.hasError) {
                            return Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to load pricing information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _pricingService.retry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            );
                          }

                          if (!_pricingService.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E3A8A),
                              ),
                            );
                          }

                          return Center(
                            child: Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Free Plan Card - Only show for free users
                                StreamBuilder<User?>(
                                    stream: user != null
                                        ? FirestoreService()
                                            .streamUserData(user.uid)
                                        : Stream.value(null),
                                    builder: (context, snapshot) {
                                      final currentSubscription =
                                          snapshot.data?.subscription.type ??
                                              SubscriptionType.free;
                                      // Only show Free plan card if user is on free plan
                                      if (currentSubscription ==
                                          SubscriptionType.free) {
                                        return _buildPricingCard(
                                          title: 'Free',
                                          price: _getFreePrice(),
                                          period: 'month',
                                          features: SubscriptionConstants
                                                  .planBenefits[
                                              SubscriptionType.free]!,
                                          isPopular: false,
                                          isSelected: true,
                                          onSelect: () => _updateSubscription(
                                              SubscriptionType.free),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                // Starter Plan Card
                                StreamBuilder<User?>(
                                    stream: user != null
                                        ? FirestoreService()
                                            .streamUserData(user.uid)
                                        : Stream.value(null),
                                    builder: (context, snapshot) {
                                      final currentSubscription =
                                          snapshot.data?.subscription.type ??
                                              SubscriptionType.free;
                                      return _buildPricingCard(
                                        title: 'Starter',
                                        price: _getStarterPriceFromFirestore(),
                                        regularPrice:
                                            _getStarterRegularPriceFromFirestore(),
                                        period: 'month',
                                        features:
                                            SubscriptionConstants.planBenefits[
                                                SubscriptionType.starter]!,
                                        isPopular: true,
                                        isSelected: currentSubscription ==
                                            SubscriptionType.starter,
                                        onSelect: () => _updateSubscription(
                                            SubscriptionType.starter),
                                      );
                                    }),
                                // Pro Plan Card
                                StreamBuilder<User?>(
                                    stream: user != null
                                        ? FirestoreService()
                                            .streamUserData(user.uid)
                                        : Stream.value(null),
                                    builder: (context, snapshot) {
                                      final currentSubscription =
                                          snapshot.data?.subscription.type ??
                                              SubscriptionType.free;
                                      return _buildPricingCard(
                                        title: 'Pro',
                                        price:
                                            '\$0.00', // Will be updated when Pro plan is available
                                        period: 'month',
                                        features:
                                            SubscriptionConstants.planBenefits[
                                                SubscriptionType.pro]!,
                                        isPopular: false,
                                        isSelected: currentSubscription ==
                                            SubscriptionType.pro,
                                        onSelect: null,
                                        isConstruction: true,
                                      );
                                    }),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    String? regularPrice,
    required String period,
    required List<String> features,
    required bool isPopular,
    required bool isSelected,
    VoidCallback? onSelect,
    bool isConstruction = false,
  }) {
    return Stack(
      children: [
        Container(
          width: isPopular ? 360 : 320,
          height: (title == 'Starter') ? null : (isPopular ? 520 : 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isPopular ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPopular
                  ? const Color(0xFF1E3A8A)
                  : Colors.black.withOpacity(0.1),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: isPopular
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize:
                (title == 'Starter') ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 16,
                        color: Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Early Bird Offer',
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (isConstruction) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.construction,
                        size: 16,
                        color: Color(0xFFFFA500),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: Color(0xFFFFA500),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GradientText(
                title,
                style: TextStyle(
                  fontSize: isPopular ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(height: 8),
              if (onSelect != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title == 'Starter' && regularPrice != null) ...[
                      Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: isPopular ? 14 : 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  regularPrice,
                                  style: TextStyle(
                                    fontSize: isPopular ? 32 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B)
                                        .withOpacity(0.5),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'USD/month',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B)
                                        .withOpacity(0.5),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Text(
                              '\$',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B).withOpacity(0.5),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: isPopular ? 16 : 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                price.substring(1),
                                style: TextStyle(
                                  fontSize: isPopular ? 56 : 48,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'USD/month',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Text(
                            '\$',
                            style: TextStyle(
                              fontSize: isPopular ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (title == 'Starter') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Early Bird Offer',
                              style: TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Limited time',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (title == 'Starter')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (onSelect != null) ...[
                                Icon(
                                  Icons.check_circle,
                                  color: isPopular
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFF1E3A8A)
                                          .withOpacity(0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: onSelect == null
                                        ? const Color(0xFF1E293B)
                                            .withOpacity(0.6)
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSelected ? null : onSelect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPopular
                              ? const Color(0xFF1E3A8A)
                              : Colors.white,
                          foregroundColor: isPopular
                              ? Colors.white
                              : const Color(0xFF1E3A8A),
                          padding: EdgeInsets.symmetric(
                            vertical: isPopular ? 18 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: isPopular
                                ? BorderSide.none
                                : const BorderSide(
                                    color: Color(0xFF1E3A8A),
                                    width: 1,
                                  ),
                          ),
                        ),
                        child: Text(
                          isSelected
                              ? 'Your current plan'
                              : title == 'Pro'
                                  ? 'Not Available'
                                  : title == 'Free'
                                      ? 'Select'
                                      : 'Start with 7 days Free Trial',
                          style: TextStyle(
                            fontSize: isPopular ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...features.map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (onSelect != null) ...[
                                  Icon(
                                    Icons.check_circle,
                                    color: isPopular
                                        ? const Color(0xFF1E3A8A)
                                        : const Color(0xFF1E3A8A)
                                            .withOpacity(0.8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: onSelect == null
                                          ? const Color(0xFF1E293B)
                                              .withOpacity(0.6)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSelected ? null : onSelect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPopular
                                ? const Color(0xFF1E3A8A)
                                : Colors.white,
                            foregroundColor: isPopular
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                            padding: EdgeInsets.symmetric(
                              vertical: isPopular ? 18 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: isPopular
                                  ? BorderSide.none
                                  : const BorderSide(
                                      color: Color(0xFF1E3A8A),
                                      width: 1,
                                    ),
                            ),
                          ),
                          child: Text(
                            isSelected
                                ? 'Your current plan'
                                : title == 'Pro'
                                    ? 'Not Available'
                                    : title == 'Free'
                                        ? 'Select'
                                        : 'Start with 7 days Free Trial',
                            style: TextStyle(
                              fontSize: isPopular ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
