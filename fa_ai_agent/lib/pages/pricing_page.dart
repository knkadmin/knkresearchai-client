import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth_service.dart';
import '../services/firestore_service.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  String? selectedPlan;

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
          if (userData != null && userData['subscription'] != null) {
            selectedPlan = userData['subscription'];
          } else {
            // Default to free plan if no subscription is set
            selectedPlan = 'free';
          }
        });
      }
    }
  }

  Future<void> _updateSubscription(String plan) async {
    final user = AuthService().currentUser;
    if (user != null) {
      final firestoreService = FirestoreService();
      try {
        await firestoreService.updateUserProfile({
          'subscription': plan,
          'subscriptionUpdatedAt': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          context.go('/');
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
                    onPressed: () => context.go('/'),
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
              padding: const EdgeInsets.symmetric(vertical: 60),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Select the plan that best fits your needs',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 60),
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
                          price: '\$0',
                          period: 'month',
                          features: [
                            'Access to basic company reports',
                            'Limited to 5 reports per day',
                            'Basic market data',
                            'Standard support',
                          ],
                          isPopular: false,
                          isSelected: selectedPlan == 'free',
                          onSelect: () {
                            setState(() {
                              selectedPlan = 'free';
                            });
                            _updateSubscription('free');
                          },
                        ),
                        _buildPricingCard(
                          title: 'Basic',
                          price: '\$29',
                          period: 'month',
                          features: [
                            'Unlimited company reports',
                            'Advanced market data',
                            'Priority support',
                            'Custom watchlists',
                            'Email notifications',
                          ],
                          isPopular: true,
                          isSelected: selectedPlan == 'basic',
                          onSelect: () {
                            setState(() {
                              selectedPlan = 'basic';
                            });
                            _updateSubscription('basic');
                          },
                        ),
                        _buildPricingCard(
                          title: 'Pro',
                          price: '\$99',
                          period: 'month',
                          features: [
                            'Everything in Basic',
                            'Real-time market data',
                            'Advanced analytics',
                            'API access',
                            'Dedicated support',
                            'Custom reports',
                          ],
                          isPopular: false,
                          isSelected: selectedPlan == 'pro',
                          onSelect: () {
                            setState(() {
                              selectedPlan = 'pro';
                            });
                            _updateSubscription('pro');
                          },
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
    required VoidCallback onSelect,
  }) {
    return Stack(
      children: [
        Container(
          width: isPopular ? 360 : 320,
          height: isPopular ? 560 : 520,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Most Popular',
                        style: TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: isPopular ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: isPopular ? 56 : 48,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/$period',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: isPopular
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFF1E3A8A).withOpacity(0.8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSelected ? null : onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular
                        ? const Color(0xFF1E3A8A)
                        : isSelected
                            ? const Color(0xFF64748B)
                            : Colors.white,
                    foregroundColor: isPopular || isSelected
                        ? Colors.white
                        : const Color(0xFF1E3A8A),
                    padding: EdgeInsets.symmetric(
                      vertical: isPopular ? 18 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isPopular || isSelected
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
                        : 'Select ${isPopular ? 'Basic' : title} Plan',
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
    );
  }
}
