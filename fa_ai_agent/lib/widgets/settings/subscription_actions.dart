import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/subscription_type.dart';
import '../../models/user.dart';
import '../../services/payment_service.dart';
import 'subscription_dialogs.dart';

class SubscriptionActions extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionActions({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              context.push('/pricing');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(
                color: Color(0xFF1E3A8A),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Upgrade Plan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: subscription.cancelAtPeriodEnd
                ? () => _handleResumeSubscription(context)
                : () => _handleCancelSubscription(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: subscription.cancelAtPeriodEnd
                  ? Colors.white
                  : const Color(0xFFDC2626),
              backgroundColor: subscription.cancelAtPeriodEnd
                  ? const Color(0xFF1E3A8A)
                  : null,
              side: BorderSide(
                color: subscription.cancelAtPeriodEnd
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFDC2626),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              subscription.cancelAtPeriodEnd
                  ? 'Renew ${subscription.type.value.toUpperCase()} Plan'
                  : 'Cancel Subscription',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleResumeSubscription(BuildContext context) async {
    final confirmed = await showResumeSubscriptionDialog(context, subscription);
    if (confirmed == true) {
      try {
        await PaymentService.resumeSubscription();
        print("Subscription resumed");
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resume subscription: ${e.toString()}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCancelSubscription(BuildContext context) async {
    final confirmed = await showCancelSubscriptionDialog(context, subscription);
    if (confirmed == true) {
      try {
        await PaymentService.cancelSubscription();
        print("Subscription cancelled");
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel subscription: ${e.toString()}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }
}
