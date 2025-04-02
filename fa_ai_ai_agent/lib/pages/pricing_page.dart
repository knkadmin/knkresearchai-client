import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_ai_ai_agent/services/auth_service.dart';
import 'package:fa_ai_ai_agent/services/firestore_service.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({Key? key}) : super(key: key);

  @override
  _PricingPageState createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  bool isOneTime = false;
  bool isYearly = false;

  Future<void> _updateSubscription(String plan) async {
    final user = AuthService().currentUser;
    if (user != null) {
      final firestoreService = FirestoreService();
      try {
        // Determine the payment recurring method
        String paymentMethod;
        if (isOneTime) {
          paymentMethod = 'one-time';
        } else if (isYearly) {
          paymentMethod = 'yearly';
        } else {
          paymentMethod = 'monthly';
        }

        await firestoreService.updateUserProfile({
          'subscription': plan,
          'paymentMethod': paymentMethod,
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
    // ... existing code ...
  }
}
