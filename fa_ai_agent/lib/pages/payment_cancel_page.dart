import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:fa_ai_agent/gradient_text.dart';

class PaymentCancelPage extends StatelessWidget {
  const PaymentCancelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel Animation
                Lottie.asset(
                  'assets/animations/cancel.json',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 32),
                // Cancel Message
                const GradientText(
                  'Payment Cancelled',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No worries!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your payment was cancelled. You can try again whenever you\'re ready.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Features List
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        'Unlimited access to all U.S. listed companies',
                        Icons.business,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        'Advanced financial data and insights',
                        Icons.analytics,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        'Accounting Irregularities detection',
                        Icons.warning_amber,
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        'Insider trading data included',
                        Icons.people,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Buttons
                Column(
                  children: [
                    // Try Again Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/pricing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Home Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go('/'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          side: const BorderSide(
                            color: Color(0xFF1E3A8A),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Return to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1E3A8A),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
