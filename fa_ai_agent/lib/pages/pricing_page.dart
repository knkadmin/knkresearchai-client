import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../services/firestore_service.dart';
import '../gradient_text.dart';
import '../models/subscription_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pricing constants
const int kFreePrice = 0;
const int kStarterRegularPrice = 20;
const int kStarterEarlyBirdPrice = 15;
const int kStarterYearlyRegularPrice = 259;
const int kStarterYearlyEarlyBirdPrice = 200;
const int kProPrice = 99;
const double kYearlyDiscount = 0.8; // 20% discount for yearly plans

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  SubscriptionType? selectedPlan;
  bool isYearly = false;
  bool isOneTime = false;

  @override
  void initState() {
    super.initState();
    _checkUserSubscription();
  }

  Future<void> _checkUserSubscription() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final firestoreService = FirestoreService();
      final userData = await firestoreService.getUserData(user.uid);

      if (mounted) {
        setState(() {
          // Set the selected plan based on user's current subscription
          selectedPlan = SubscriptionType.fromString(userData?['subscription']);
        });
      }
    }
  }

  Future<void> _updateSubscription(SubscriptionType plan) async {
    final user = AuthService().currentUser;
    if (user != null) {
      final firestoreService = FirestoreService();
      try {
        Map<String, dynamic> updateData = {
          'subscription': plan.value,
          'subscriptionUpdatedAt': DateTime.now().toIso8601String(),
        };

        // Add payment method only for paid plans
        if (plan.isPaid) {
          updateData['paymentMethod'] = 'monthly';
        } else {
          // Remove paymentMethod field for free plan
          updateData['paymentMethod'] = FieldValue.delete();
        }

        await firestoreService.updateUserProfile(updateData);
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update subscription. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatPrice(int price) {
    return '\$$price';
  }

  int _getStarterPrice() {
    return kStarterEarlyBirdPrice;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    onPressed: () => context.pop(),
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
                  Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildPricingCard(
                          title: 'Free',
                          price: _formatPrice(kFreePrice),
                          period: 'month',
                          features: [
                            'Complete access to reports for Mag 7 companies',
                            'Unlimited report refreshes',
                            'Add companies to watchlist',
                          ],
                          isPopular: false,
                          isSelected: selectedPlan == SubscriptionType.free,
                          onSelect: () {
                            setState(() {
                              selectedPlan = SubscriptionType.free;
                            });
                            _updateSubscription(SubscriptionType.free);
                          },
                        ),
                        _buildPricingCard(
                          title: 'Starter',
                          price: _formatPrice(_getStarterPrice()),
                          period: 'month',
                          features: [
                            'Everything in Free plan',
                            'Unlimited access to reports for all U.S listed companies',
                            'Advanced financial data and industry insights',
                            'Accounting Irregularities detection included',
                            'Insider trading data included',
                          ],
                          isPopular: true,
                          isSelected: selectedPlan == SubscriptionType.starter,
                          onSelect: () {
                            setState(() {
                              selectedPlan = SubscriptionType.starter;
                            });
                            _updateSubscription(SubscriptionType.starter);
                          },
                        ),
                        _buildPricingCard(
                          title: 'Pro',
                          price: _formatPrice(kProPrice),
                          period: 'month',
                          features: [
                            'More advanced features coming soon for pro users - please stay tuned.',
                          ],
                          isPopular: false,
                          isSelected: selectedPlan == SubscriptionType.pro,
                          onSelect: null,
                          isConstruction: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
    required bool isSelected,
    VoidCallback? onSelect,
    bool isConstruction = false,
    String? additionalText,
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
              if (isPopular && (title != 'Starter' || isYearly)) ...[
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
                      Icon(
                        title == 'Starter' ? Icons.local_offer : Icons.star,
                        size: 16,
                        color: const Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        title == 'Starter'
                            ? 'Early Bird Offer'
                            : 'Most Popular',
                        style: const TextStyle(
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
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: const Color(0xFFFFA500),
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
                    if (title == 'Starter') ...[
                      Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: isPopular ? 14 : 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${kStarterRegularPrice}',
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
                                price.substring(
                                    1), // Remove the dollar sign from the original price
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
                    if (title == 'Starter' && isYearly && !isOneTime) ...[
                      const SizedBox(height: 4),
                      Text(
                        'That\'s just \$${(kStarterYearlyEarlyBirdPrice / 12).toStringAsFixed(2)}/month',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (title == 'Starter' && !isYearly && !isOneTime) ...[
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
              if (title == 'Starter' && !isOneTime)
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
                          backgroundColor:
                              isPopular || (title == 'Starter' && isOneTime)
                                  ? const Color(0xFF1E3A8A)
                                  : isSelected
                                      ? const Color(0xFF64748B)
                                      : Colors.white,
                          foregroundColor: isPopular ||
                                  isSelected ||
                                  (title == 'Starter' && isOneTime)
                              ? Colors.white
                              : const Color(0xFF1E3A8A),
                          padding: EdgeInsets.symmetric(
                            vertical: isPopular ? 18 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: isPopular ||
                                    isSelected ||
                                    (title == 'Starter' && isOneTime)
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
                              : onSelect == null
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
                            backgroundColor:
                                isPopular || (title == 'Starter' && isOneTime)
                                    ? const Color(0xFF1E3A8A)
                                    : isSelected
                                        ? const Color(0xFF64748B)
                                        : Colors.white,
                            foregroundColor: isPopular ||
                                    isSelected ||
                                    (title == 'Starter' && isOneTime)
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                            padding: EdgeInsets.symmetric(
                              vertical: isPopular ? 18 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: isPopular ||
                                      isSelected ||
                                      (title == 'Starter' && isOneTime)
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
                                : onSelect == null
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
        if (title == 'Starter' && isYearly && !isOneTime)
          Positioned(
            top: 16,
            right: 16,
            child: const Icon(
              Icons.local_fire_department,
              size: 32,
              color: Color(0xFFFF6B6B),
            ),
          ),
      ],
    );
  }
}
