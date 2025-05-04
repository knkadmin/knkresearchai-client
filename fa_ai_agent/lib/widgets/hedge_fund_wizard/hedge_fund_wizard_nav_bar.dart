import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../hedge_fund_wizard/hedge_fund_wizard_nav_bar.dart';
import '../hedge_fund_wizard/veritas_pricing_popup.dart';

class HedgeFundWizardNavBar extends StatelessWidget {
  final bool isMenuCollapsed;
  final double? userCredits;
  final bool isStarterPlan;
  final VoidCallback onMenuToggle;
  final Animation<double> flashAnimation;

  const HedgeFundWizardNavBar({
    super.key,
    required this.isMenuCollapsed,
    required this.userCredits,
    required this.isStarterPlan,
    required this.onMenuToggle,
    required this.flashAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldHideTitle = screenWidth < 600;

    return Row(children: [
      TextButton.icon(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white.withValues(alpha: 0.1);
              }
              return Colors.transparent;
            },
          ),
          padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
        ),
        icon: const Row(
          children: [
            Icon(Icons.chevron_left, color: Colors.white),
            SizedBox(width: 4),
            Icon(Icons.home, color: Colors.white),
          ],
        ),
        label: const SizedBox.shrink(),
        onPressed: () => context.go('/'),
      ),
      const SizedBox(width: 8),
      if (!shouldHideTitle)
        const Text(
          'Hedge Fund Wizard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      const Spacer(),
      if (isMenuCollapsed)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Credits Button
            if (userCredits != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCreditsButton(context),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.05),
                    disabledBackgroundColor:
                        Colors.black.withValues(alpha: 0.03),
                    foregroundColor: Colors.white70,
                    disabledForegroundColor: Colors.white60,
                    elevation: 0,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05), width: 1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text(
                    'Veritas: 0',
                  ),
                ),
              ),
            // Vertical splitter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 28,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            SizedBox(
              width: 40,
              child: TextButton.icon(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white.withValues(alpha: 0.1);
                      }
                      return Colors.transparent;
                    },
                  ),
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.only(left: 8, top: 8, bottom: 8)),
                ),
                icon: const Icon(Icons.history, color: Colors.white),
                label: const SizedBox.shrink(),
                onPressed: onMenuToggle,
              ),
            ),
          ],
        ),
    ]);
  }

  Widget _buildCreditsButton(BuildContext context) {
    return AnimatedBuilder(
      animation: flashAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: flashAnimation.value * 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFF1E293B),
            onSelected: (value) {
              if (value == 'purchase') {
                showDialog(
                  context: context,
                  builder: (context) => const VeritasPricingPopup(),
                );
              } else if (value == 'upgrade') {
                context.push('/pricing');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Veritas is the currency consumed each time Hedge Fund Wizard answers your question. The cost varies based on question complexity.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                enabled: false,
                child: Divider(
                  color: Colors.white.withOpacity(0.1),
                  height: 1,
                ),
              ),
              PopupMenuItem<String>(
                value: 'purchase',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Center(
                    child: Text(
                      'Purchase Veritas',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isStarterPlan) ...[
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'upgrade',
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF1E3A8A).withOpacity(0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Upgrade to Starter Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: null,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Available Veritas: ${userCredits?.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
