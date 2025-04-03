import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:fa_ai_agent/models/subscription_type.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';

class SubscriptionService {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Get the current user's subscription type
  Future<SubscriptionType> getCurrentUserSubscription() async {
    final user = _authService.currentUser;
    if (user == null) return SubscriptionType.free;

    try {
      final userData = await _firestoreService.getUserProfile();
      return SubscriptionType.fromString(userData?['subscription'] ?? 'free');
    } catch (e) {
      print('Error getting user subscription: $e');
      return SubscriptionType.free;
    }
  }

  // Stream of subscription changes
  Stream<SubscriptionType> streamUserSubscription() {
    final user = _authService.currentUser;
    if (user == null) {
      return Stream.value(SubscriptionType.free);
    }

    return _firestoreService.streamUserSubscription(user.uid).map(
        (subscriptionString) =>
            SubscriptionType.fromString(subscriptionString ?? 'free'));
  }
}
