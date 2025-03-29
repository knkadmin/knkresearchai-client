import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../gradient_text.dart';
import '../auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Check if user is already signed in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print(
            'User already signed in: ${currentUser.displayName ?? currentUser.email}');
        // Navigate to dashboard page
        GoRouter.of(context).go('/dashboard');
      } else {
        print('No user is currently signed in');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Logo
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          size: 24,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'KNK Research',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  // Center: Navigation Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavItem('Features', () {}),
                      _buildNavItem('Research', () {}),
                      _buildNavItem('Market Data', () {}),
                      _buildNavItem('Pricing', () {}),
                      _buildNavItem('Resources', () {}),
                      _buildNavItem('About', () {}),
                    ],
                  ),
                  // Right: Action Buttons
                  Row(
                    children: [
                      // Demo Button
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            // Empty action for demo button
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E2C3D),
                            side: const BorderSide(
                              color: Color(0xFF1E2C3D),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Try Demo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sign In Button
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/signin');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2C3D),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title with modern typography
                      const Text(
                        'AI-Powered\nFinancial Analyst',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -1.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Subtitle with modern typography
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: const Text(
                          'Delivering in-depth research to empower informed investment decisions and optimize returns.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFF64748B),
                            height: 1.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Demo Image
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Card(
                          elevation: 24,
                          shadowColor: Colors.black.withOpacity(0.08),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/charts-demo.jpeg',
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: 1000,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Why Choose AI Agent with Us section
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFF8F9FA),
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            gradientTitle("Why choose AI agent with us?", 32),
                            const SizedBox(height: 60),
                            Center(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildShowcaseCard(
                                      "Quick Insights",
                                      "Understand a U.S.-listed company in just 2 minutes",
                                      "Get a comprehensive overview of any U.S.-listed company in just two minutes, including business model, financials, and market performance.",
                                      Icons.speed,
                                    ),
                                    const SizedBox(width: 24),
                                    _buildShowcaseCard(
                                      "Instant Updates",
                                      "Refresh reports in just 30 seconds",
                                      "No need to search for updates manually—simply refresh the report and get the latest company news and market changes in 30 seconds.",
                                      Icons.update,
                                    ),
                                    const SizedBox(width: 24),
                                    _buildShowcaseCard(
                                      "Comprehensive View",
                                      "Full industry landscape & competitor analysis",
                                      "Easily see where a company fits within its industry, from upstream and downstream supply chains to key competitors, all in one clear report.",
                                      Icons.view_comfy,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Trusted by section
                      const Text(
                        'Trusted by investors worldwide',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Trusted by logos (placeholder)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTrustedByLogo('Bloomberg'),
                          _buildTrustedByLogo('Reuters'),
                          _buildTrustedByLogo('WSJ'),
                          _buildTrustedByLogo('CNBC'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTrustedByLogo(String name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildShowcaseCard(
      String title, String subtitle, String description, IconData iconName) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        width: 350,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2C3D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconName,
                color: const Color(0xFF1E2C3D),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2C3D),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E2C3D),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
