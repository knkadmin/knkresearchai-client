import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fa_ai_agent/services/payment_service.dart';
import 'package:fa_ai_agent/services/firestore_service.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class VeritasPricingPopup extends StatefulWidget {
  const VeritasPricingPopup({super.key});

  @override
  State<VeritasPricingPopup> createState() => _VeritasPricingPopupState();
}

class _VeritasPricingPopupState extends State<VeritasPricingPopup> {
  bool _isProcessing = false;
  String? _selectedProductId;
  int? _selectedAmount;
  int? _selectedTotalValue;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF0F172A),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Get More Veritas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: AuthService().userDocumentStream,
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final credits = data?['credits'] as double? ?? 0;
                    return Center(
                      child: Text(
                        'Current Balance: ${credits.toStringAsFixed(0)} Veritas',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('veritasPricing')
                      .orderBy('amount')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading pricing options',
                          style: TextStyle(color: Colors.red.withOpacity(0.8)),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }

                    final products = snapshot.data!.docs;
                    final screenWidth = MediaQuery.of(context).size.width;
                    final isNarrow = screenWidth < 700;

                    return Column(
                      children: [
                        if (!isNarrow)
                          Center(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: products.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final amount = data['amount'] as int;
                                final baseValue = data['baseValue'] as int;
                                final bonusValue = data['bonusValue'] as int;
                                final stripeProductId =
                                    data['stripeProductId'] as String;
                                final isSelected =
                                    stripeProductId == _selectedProductId;
                                final isPopular =
                                    data['isPopular'] as bool? ?? false;
                                final isBestValue =
                                    data['isBestValue'] as bool? ?? false;
                                return _buildPricingCard(
                                  amount: amount,
                                  baseValue: baseValue,
                                  bonusValue: bonusValue,
                                  stripeProductId: stripeProductId,
                                  isSelected: isSelected,
                                  isPopular: isPopular,
                                  isBestValue: isBestValue,
                                  onTap: () {
                                    setState(() {
                                      _selectedProductId = stripeProductId;
                                      _selectedAmount = amount;
                                      _selectedTotalValue =
                                          baseValue + bonusValue;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        if (isNarrow)
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final doc = products[idx];
                              final data = doc.data() as Map<String, dynamic>;
                              final amount = data['amount'] as int;
                              final baseValue = data['baseValue'] as int;
                              final bonusValue = data['bonusValue'] as int;
                              final stripeProductId =
                                  data['stripeProductId'] as String;
                              final isSelected =
                                  stripeProductId == _selectedProductId;
                              final isPopular =
                                  data['isPopular'] as bool? ?? false;
                              final isBestValue =
                                  data['isBestValue'] as bool? ?? false;
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() {
                                    _selectedProductId = stripeProductId;
                                    _selectedAmount = amount;
                                    _selectedTotalValue =
                                        baseValue + bonusValue;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1E3A8A)
                                            .withOpacity(0.18)
                                        : Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1E3A8A)
                                          : isPopular
                                              ? const Color(0xFFFFD700)
                                              : Colors.white.withOpacity(0.10),
                                      width: isSelected || isPopular ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: const Color(0xFF1E3A8A)
                                              .withOpacity(0.10),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Left: Total, base, bonus
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (isPopular || isBestValue)
                                              Row(
                                                children: [
                                                  if (isPopular)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFFFFD700)
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: const Color(
                                                              0xFFFFD700),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.star,
                                                            color: Color(
                                                                0xFFFFD700),
                                                            size: 12,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Popular',
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xFFFFD700),
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (isPopular && isBestValue)
                                                    const SizedBox(width: 4),
                                                  if (isBestValue)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF4CAF50)
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: const Color(
                                                              0xFF4CAF50),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.thumb_up,
                                                            color: Color(
                                                                0xFF4CAF50),
                                                            size: 12,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Best Value',
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xFF4CAF50),
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            if (isPopular || isBestValue)
                                              const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${baseValue + bonusValue}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Veritas',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (bonusValue > 0) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    '$baseValue',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '+ ${((bonusValue / baseValue) * 100).toStringAsFixed(0)}%',
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFD600),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Right: Price badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.10),
                                              Colors.white.withOpacity(0.04),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.18),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              (amount / 100).toStringAsFixed(0),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'USD',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        if (_selectedProductId != null)
                          Center(
                            child: SizedBox(
                              width: 500,
                              child: ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () async {
                                        setState(() => _isProcessing = true);
                                        try {
                                          // Log analytics event for purchase initiation
                                          await _analytics.logEvent(
                                            name:
                                                'hedge_fund_wizard_purchase_initiated',
                                            parameters: {
                                              'product_id':
                                                  _selectedProductId ?? '',
                                              'amount_usd':
                                                  (_selectedAmount ?? 0) / 100,
                                              'total_value':
                                                  _selectedTotalValue ?? 0,
                                            },
                                          );

                                          await PaymentService
                                              .initiateVeritasPurchase(
                                            _selectedProductId!,
                                            _selectedAmount!,
                                          );

                                          // Log analytics event for successful purchase
                                          await _analytics.logEvent(
                                            name:
                                                'hedge_fund_wizard_purchase_success',
                                            parameters: {
                                              'product_id':
                                                  _selectedProductId ?? '',
                                              'amount_usd':
                                                  (_selectedAmount ?? 0) / 100,
                                              'total_value':
                                                  _selectedTotalValue ?? 0,
                                            },
                                          );

                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        } catch (e) {
                                          // Log analytics event for failed purchase
                                          await _analytics.logEvent(
                                            name:
                                                'hedge_fund_wizard_purchase_failed',
                                            parameters: {
                                              'product_id':
                                                  _selectedProductId ?? '',
                                              'amount_usd':
                                                  (_selectedAmount ?? 0) / 100,
                                              'total_value':
                                                  _selectedTotalValue ?? 0,
                                              'error': e.toString(),
                                            },
                                          );

                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to process payment: ${e.toString()}',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }

                                          if (mounted) {
                                            setState(
                                                () => _isProcessing = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1E3A8A),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF1E3A8A),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Purchase $_selectedTotalValue Veritas Now',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required int amount,
    required int baseValue,
    required int bonusValue,
    required String stripeProductId,
    required bool isSelected,
    required bool isPopular,
    required bool isBestValue,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          onTap();
          // Log analytics event for pricing card selection
          await _analytics.logEvent(
            name: 'hedge_fund_wizard_pricing_card_selected',
            parameters: {
              'product_id': stripeProductId,
              'amount_usd': amount / 100,
              'base_value': baseValue,
              'bonus_value': bonusValue,
              'total_value': baseValue + bonusValue,
              'is_popular': isPopular,
              'is_best_value': isBestValue,
            },
          );
        },
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      const Color(0xFF1E3A8A).withOpacity(0.2),
                      const Color(0xFF1E3A8A).withOpacity(0.1),
                    ]
                  : [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : isPopular
                      ? const Color(0xFFFFD700)
                      : Colors.white.withOpacity(0.1),
              width: isSelected || isPopular ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF1E3A8A).withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badges container with fixed height
              SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Color(0xFFFFD700),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Popular',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isPopular && isBestValue) const SizedBox(width: 4),
                    if (isBestValue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.thumb_up,
                              color: Color(0xFF4CAF50),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Best Value',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Total value (large, bold, with shadow)
                    Text(
                      '${baseValue + bonusValue}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Base value (lighter)
                    Text(
                      '$baseValue',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Bonus value (yellow, bold)
                    Text(
                      '+ ${((bonusValue / baseValue) * 100).toStringAsFixed(0)}% Bonus',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Label
                    const Text(
                      'Veritas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Price at bottom right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '\$', // Dollar sign
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (amount / 100).toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'USD',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
