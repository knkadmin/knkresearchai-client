import 'package:fa_ai_agent/models/subscription_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final SubscriptionType type;
  final DateTime updatedAt;
  final String? paymentMethod;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelAt;
  final bool cancelAtPeriodEnd;
  final String? stripeCustomerId;

  const Subscription({
    required this.type,
    required this.updatedAt,
    this.paymentMethod,
    this.currentPeriodEnd,
    this.cancelAt,
    this.cancelAtPeriodEnd = false,
    this.stripeCustomerId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      type: SubscriptionType.fromString(json['type'] ?? 'free'),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['updatedAt'] ?? DateTime.now().toIso8601String()),
      paymentMethod: json['paymentMethod'],
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['currentPeriodEnd'] * 1000)
          : null,
      cancelAt: json['cancelAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['cancelAt'] * 1000)
          : null,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] ?? false,
      stripeCustomerId: json['stripeCustomerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'updatedAt': updatedAt.toIso8601String(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (currentPeriodEnd != null)
        'currentPeriodEnd': currentPeriodEnd!.toIso8601String(),
      if (cancelAt != null) 'cancelAt': cancelAt!.toIso8601String(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
    };
  }

  Subscription copyWith({
    SubscriptionType? type,
    DateTime? updatedAt,
    String? paymentMethod,
    DateTime? currentPeriodEnd,
    DateTime? cancelAt,
    bool? cancelAtPeriodEnd,
    String? stripeCustomerId,
  }) {
    return Subscription(
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      cancelAt: cancelAt ?? this.cancelAt,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
    );
  }
}

class User {
  final String uid;
  final String email;
  final String? displayName;
  final Subscription subscription;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? stripeCustomerId;
  final bool hasUsedFreeTrial;
  final DateTime? trialEndDate;
  final String signInMethod;

  const User({
    required this.uid,
    required this.email,
    this.displayName,
    required this.subscription,
    required this.createdAt,
    required this.lastLoginAt,
    this.stripeCustomerId,
    this.hasUsedFreeTrial = false,
    this.trialEndDate,
    required this.signInMethod,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      subscription: Subscription.fromJson(json['subscription'] ?? {}),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['lastLoginAt'] is Timestamp
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['lastLoginAt'] ?? DateTime.now().toIso8601String()),
      stripeCustomerId: json['stripeCustomerId'],
      hasUsedFreeTrial: json['hasUsedFreeTrial'] ?? false,
      trialEndDate: json['trialEndDate'] is Timestamp
          ? (json['trialEndDate'] as Timestamp).toDate()
          : json['trialEndDate'] != null
              ? DateTime.parse(json['trialEndDate'])
              : null,
      signInMethod: json['signInMethod'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      if (displayName != null) 'displayName': displayName,
      'subscription': subscription.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
      'hasUsedFreeTrial': hasUsedFreeTrial,
      if (trialEndDate != null)
        'trialEndDate': Timestamp.fromDate(trialEndDate!),
      'signInMethod': signInMethod,
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    Subscription? subscription,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? stripeCustomerId,
    bool? hasUsedFreeTrial,
    DateTime? trialEndDate,
    String? signInMethod,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      hasUsedFreeTrial: hasUsedFreeTrial ?? this.hasUsedFreeTrial,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      signInMethod: signInMethod ?? this.signInMethod,
    );
  }
}

extension UserTrialExtension on User {
  bool get isInActiveTrial {
    // Check for active trial period
    return trialEndDate != null &&
        trialEndDate!.isAfter(DateTime.now()) &&
        !hasUsedFreeTrial;
  }
}
