import 'package:flutter/material.dart';

class DynamicAppBarTitle extends StatelessWidget {
  const DynamicAppBarTitle({
    super.key,
    required this.showCompanyName,
    required this.companyName,
  });

  final ValueNotifier<bool> showCompanyName;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showCompanyName,
      builder: (context, value, child) {
        return Text(value ? companyName : "KNK Research");
      },
    );
  }
}
