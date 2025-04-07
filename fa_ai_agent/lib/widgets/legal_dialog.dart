import 'package:flutter/material.dart';

class LegalDialog extends StatelessWidget {
  final String title;
  final String content;
  final double width;

  const LegalDialog({
    super.key,
    required this.title,
    required this.content,
    this.width = 600,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
