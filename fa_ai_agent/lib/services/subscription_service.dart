import 'package:fa_ai_agent/models/subscription_type.dart';
import 'package:fa_ai_agent/models/user.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  Future<SubscriptionType> getCurrentUserSubscription() async {
    final user = AuthService().currentUser;
    if (user == null) return SubscriptionType.free;

    final userData = await _firestoreService.getUserData(user.uid);
    if (userData == null) return SubscriptionType.free;

    if (userData.isInActiveTrial) {
      return SubscriptionType.starter; // User is in trial, treat as starter
    }
    return userData.subscription.type;
  }

  Stream<SubscriptionType> streamUserSubscription() {
    final authUser = AuthService().currentUser;
    if (authUser == null) {
      return Stream.value(SubscriptionType.free);
    }

    return _firestoreService.streamUserData(authUser.uid).map((userData) {
      if (userData == null) return SubscriptionType.free;

      if (userData.isInActiveTrial) {
        return SubscriptionType.starter; // User is in trial, treat as starter
      }
      return userData.subscription.type;
    });
  }

  Future<void> updateUserSubscription(SubscriptionType type) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final userData = await _firestoreService.getUserData(user.uid);
    if (userData == null) return;

    // When a user explicitly updates their subscription (e.g., subscribes to a paid plan),
    // we should mark that they have used their free trial if they were in one.
    bool markTrialAsUsed = userData.isInActiveTrial;

    final updatedUser = userData.copyWith(
      subscription: Subscription(
        type: type,
        updatedAt: DateTime.now(),
        paymentMethod: type.isPaid ? 'stripe' : null,
      ),
      // If they were in an active trial and are now moving to a new subscription (likely paid),
      // set hasUsedFreeTrial to true.
      hasUsedFreeTrial: markTrialAsUsed ? true : userData.hasUsedFreeTrial,
    );
    // We need to update the entire user document if hasUsedFreeTrial might change.
    // FirestoreService().updateUserSubscription only updates the subscription sub-document.
    // So, we need a method in FirestoreService to update the whole user or specific top-level fields.
    // For now, let's assume updateUserSubscription is sufficient and we handle hasUsedFreeTrial separately if needed,
    // or the backend/cloud function handles this transition.
    // A more robust solution would involve updating the user object in Firestore with hasUsedFreeTrial set to true.

    await _firestoreService.updateUserSubscription(
        user.uid, updatedUser.subscription);

    // If trial was used, update the user document in Firestore.
    if (markTrialAsUsed) {
      await _firestoreService
          .updateUserProfile(user.uid, {'hasUsedFreeTrial': true});
    }
  }
}
