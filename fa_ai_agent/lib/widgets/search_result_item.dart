import 'package:flutter/material.dart';

class SearchResultItem extends StatefulWidget {
  final String name;
  final String symbol;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.name,
    required this.symbol,
    required this.onTap,
  });

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: isHovered
              ? const Color(0xFF2563EB).withOpacity(0.1)
              : Colors.transparent,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              widget.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              widget.symbol,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E4B6F),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF2E4B6F),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
