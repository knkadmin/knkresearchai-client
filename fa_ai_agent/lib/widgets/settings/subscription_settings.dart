import 'package:flutter/material.dart';
import '../../models/subscription_type.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart';
import 'subscription_card.dart';
import 'subscription_actions.dart';

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
              const Text(
                'Subscription Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              SubscriptionCard(subscription: subscription),
              const SizedBox(height: 24),
              if (subscription.type.isPaid)
                SubscriptionActions(subscription: subscription),
            ],
          ),
        );
      },
    );
  }
}
