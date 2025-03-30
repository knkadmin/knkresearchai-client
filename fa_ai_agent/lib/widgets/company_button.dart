import 'package:flutter/material.dart';

class CompanyButton extends StatelessWidget {
  final String name;
  final String symbol;
  final VoidCallback onTap;

  const CompanyButton({
    super.key,
    required this.name,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                symbol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E4B6F),
                ),
              ),
              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFF2E4B6F).withOpacity(0.3),
              ),
              Text(
                name,
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
  }
}
