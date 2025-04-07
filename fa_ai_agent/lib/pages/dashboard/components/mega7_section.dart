import 'package:flutter/material.dart';

class Mega7Section extends StatelessWidget {
  final List<Map<String, String>> mega7Companies;
  final Function(String, String) onNavigateToReport;

  const Mega7Section({
    super.key,
    required this.mega7Companies,
    required this.onNavigateToReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const Text(
            "Quick Start with Mag 7 Companies for FREE. No Signup Required.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2C3D),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: 900,
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: mega7Companies.map((company) {
                  final companyName = company.values.toList().first;
                  final ticker = company.keys.toList().first;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onNavigateToReport(ticker, companyName),
                      borderRadius: BorderRadius.circular(25),
                      hoverColor: const Color(0xFF2E4B6F).withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF2E4B6F),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ticker,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E4B6F),
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              color: const Color(0xFF2E4B6F).withOpacity(0.3),
                            ),
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
