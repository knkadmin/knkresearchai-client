import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function()? onClear;
  final String hintText;
  final double width;
  final double height;
  final bool showBorder;
  final bool showShadow;
  final EdgeInsets? contentPadding;
  final double? fontSize;
  final double? iconSize;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onClear,
    required this.hintText,
    this.width = 500,
    this.height = 48,
    this.showBorder = true,
    this.showShadow = true,
    this.contentPadding,
    this.fontSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: showBorder
              ? Border.all(
                  color: const Color(0xFF1E293B).withOpacity(0.1),
                  width: 1,
                )
              : null,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: fontSize ?? 18,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: fontSize ?? 18,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: iconSize ?? 24,
              color: Colors.grey[400],
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: iconSize ?? 24,
                      color: Colors.grey[400],
                    ),
                    onPressed: onClear ??
                        () {
                          controller.clear();
                        },
                  )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}
