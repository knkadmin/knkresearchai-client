import 'package:flutter/material.dart';

class WhyChooseUsSection extends StatelessWidget {
  const WhyChooseUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _gradientTitle(context, "Why choose AI agent with us?", 32),
          const SizedBox(height: 60),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _showcaseCard(
                    context,
                    "Quick Insights",
                    "Understand a U.S.-listed company in just 2 minutes",
                    "Get a comprehensive overview of any U.S.-listed company in just two minutes, including business model, financials, and market performance.",
                    Icons.speed,
                  ),
                  const SizedBox(width: 24),
                  _showcaseCard(
                    context,
                    "Instant Updates",
                    "Refresh reports in just 30 seconds",
                    "No need to search for updates manually—simply refresh the report and get the latest company news and market changes in 30 seconds.",
                    Icons.update,
                  ),
                  const SizedBox(width: 24),
                  _showcaseCard(
                    context,
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
    );
  }

  static Widget _gradientTitle(
      BuildContext context, String text, double fontSize) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF1E2C3D), Color(0xFF2E4B6F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static Widget _showcaseCard(BuildContext context, String title,
      String subtitle, String description, IconData iconName) {
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
