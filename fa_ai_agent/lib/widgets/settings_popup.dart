import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
import 'package:go_router/go_router.dart';
import 'settings/subscription_settings.dart';
import 'settings/general_settings.dart';

class SettingsPopup extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsPopup({
    super.key,
    required this.onLogout,
  });

  @override
  State<SettingsPopup> createState() => _SettingsPopupState();
}

class _SettingsPopupState extends State<SettingsPopup> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _emailUpdates = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark mode for the app'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Receive notifications for updates'),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Email Updates'),
            subtitle: const Text('Receive email updates about new features'),
            value: _emailUpdates,
            onChanged: (value) {
              setState(() {
                _emailUpdates = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Save settings
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
