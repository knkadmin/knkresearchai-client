import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/legal_dialog.dart';

class FooterSection extends StatelessWidget {
  final String termsAndConditionsText;
  final String privacyPolicyText;

  const FooterSection({
    super.key,
    required this.termsAndConditionsText,
    required this.privacyPolicyText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => LegalDialog(
                      title: 'Terms & Conditions',
                      content: termsAndConditionsText,
                    ),
                  );
                },
                child: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                ' • ',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => LegalDialog(
                      title: 'Privacy Policy',
                      content: privacyPolicyText,
                    ),
                  );
                },
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          color: Colors.black,
          child: Text(
            '© 2025 KNK Research AI. All rights reserved.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
