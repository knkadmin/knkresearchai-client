import 'package:flutter/material.dart';

class Section {
  final String title;
  final IconData icon;
  final Widget Function() buildContent;

  const Section({
    required this.title,
    required this.icon,
    required this.buildContent,
  });
}
