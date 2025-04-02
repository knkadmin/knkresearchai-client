enum SubscriptionType {
  free('free'),
  starter('starter'),
  pro('pro');

  final String value;
  const SubscriptionType(this.value);

  static SubscriptionType fromString(String? value) {
    if (value == null) return SubscriptionType.free;
    return SubscriptionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SubscriptionType.free,
    );
  }

  bool get isPaid => this != SubscriptionType.free;
}
