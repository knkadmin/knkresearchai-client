class PricingPlan {
  final String type;
  final int amount;
  final String stripeProductId;
  final int? discountedAmount;

  PricingPlan({
    required this.type,
    required this.amount,
    required this.stripeProductId,
    this.discountedAmount,
  });

  factory PricingPlan.fromFirestore(Map<String, dynamic> data) {
    return PricingPlan(
      type: data['type'] ?? '',
      amount: data['amount'] ?? 0,
      stripeProductId: data['stripeProductId'] ?? '',
      discountedAmount: data['discountedAmount'],
    );
  }
}
