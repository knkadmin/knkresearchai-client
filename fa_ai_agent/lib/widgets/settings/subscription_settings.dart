import 'package:flutter/material.dart';
import '../../models/subscription_type.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart';
import 'subscription_card.dart';
import 'subscription_actions.dart';
import 'package:go_router/go_router.dart';
import '../../services/payment_service.dart';
import 'package:rxdart/rxdart.dart';

class SubscriptionSettings extends StatelessWidget {
  const SubscriptionSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().currentUser != null
          ? FirestoreService().streamUserData(AuthService().currentUser!.uid)
          : Stream.value(null),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final subscription = user?.subscription ??
            Subscription(
              type: SubscriptionType.free,
              updatedAt: DateTime.now(),
            );

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubscriptionCard(subscription: subscription),
              const SizedBox(height: 24),
              if (subscription.type.isPaid) ...[
                SubscriptionActions(subscription: subscription),
                const SizedBox(height: 24),
                const Divider(
                  color: Color(0xFFE2E8F0),
                  thickness: 1,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage payments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    StreamBuilder<bool>(
                      stream: PaymentService.isLoadingStream,
                      builder: (context, snapshot) {
                        final isLoading = snapshot.data ?? false;
                        return OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  try {
                                    await PaymentService.openCustomerPortal();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to open customer portal: ${e.toString()}'),
                                          backgroundColor: const Color(0xFFDC2626),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(
                              color: Color(0xFF1E3A8A),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                                  ),
                                )
                              : const Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/pricing');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2563EB),
                            Color(0xFF1E40AF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: const Text(
                          'Upgrade Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
