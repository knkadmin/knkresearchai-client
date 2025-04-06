import 'package:fa_ai_agent/models/subscription_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final SubscriptionType type;
  final DateTime updatedAt;
  final String? paymentMethod;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelAt;
  final bool cancelAtPeriodEnd;

  const Subscription({
    required this.type,
    required this.updatedAt,
    this.paymentMethod,
    this.currentPeriodEnd,
    this.cancelAt,
    this.cancelAtPeriodEnd = false,
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
    };
  }
}

class User {
  final String uid;
  final String email;
  final String? displayName;
  final Subscription subscription;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const User({
    required this.uid,
    required this.email,
    this.displayName,
    required this.subscription,
    required this.createdAt,
    required this.lastLoginAt,
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
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    Subscription? subscription,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
