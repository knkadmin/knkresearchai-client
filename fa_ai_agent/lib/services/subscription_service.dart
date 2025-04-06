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
    return userData?.subscription.type ?? SubscriptionType.free;
  }

  Stream<SubscriptionType> streamUserSubscription() {
    final user = AuthService().currentUser;
    if (user == null) {
      return Stream.value(SubscriptionType.free);
    }

    return _firestoreService.streamUserData(user.uid).map((user) {
      return user?.subscription.type ?? SubscriptionType.free;
    });
  }

  Future<void> updateUserSubscription(SubscriptionType type) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final userData = await _firestoreService.getUserData(user.uid);
    if (userData == null) return;

    final updatedUser = userData.copyWith(
      subscription: Subscription(
        type: type,
        updatedAt: DateTime.now(),
        paymentMethod: type.isPaid ? 'stripe' : null,
      ),
    );

    await _firestoreService.updateUserSubscription(
        user.uid, updatedUser.subscription);
  }
}
