import 'package:fa_ai_agent/models/subscription_type.dart';

class SubscriptionConstants {
  static const Map<SubscriptionType, List<String>> planBenefits = {
    SubscriptionType.free: [
      'Complete access to reports for Mag 7 companies',
      'Unlimited report refreshes',
      'Add companies to watchlist',
    ],
    SubscriptionType.starter: [
      'Everything in Free plan',
      'Unlimited access to reports for all U.S listed companies',
      'Advanced financial data and industry insights',
      'Accounting Irregularities detection included',
      'Insider trading data included',
    ],
    SubscriptionType.pro: [
      'More advanced features coming soon for pro users - please stay tuned.',
    ],
  };

  static const freeTrialDays = 7;
}
