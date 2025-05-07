import 'dart:async'; // Added for Timer

import 'package:fa_ai_agent/config/environment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// firebase_auth import is not strictly needed here anymore if AuthService handles all user interactions
// import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:fa_ai_agent/services/auth_service.dart';

// Changed class name to reflect it's a dialog
class PendingVerificationDialog extends StatefulWidget {
  // Added a callback for when verification is successful to notify the calling page
  final VoidCallback? onVerified;

  const PendingVerificationDialog({super.key, this.onVerified});

  @override
  State<PendingVerificationDialog> createState() =>
      _PendingVerificationDialogState();
}

class _PendingVerificationDialogState extends State<PendingVerificationDialog> {
  bool _isCooldownActive = false;
  int _cooldownSeconds = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _isCooldownActive = true;
      _cooldownSeconds = 60;
    });
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          _timer?.cancel();
          _isCooldownActive = false;
        }
      });
    });
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    if (_isCooldownActive) {
      return; // Do nothing if cooldown is active
    }
    try {
      final user = AuthService().currentUser;
      if (user != null && !user.emailVerified) {
        // Optimistically assume email will be sent.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sending verification email...'),
            backgroundColor: Colors.blue,
          ),
        );
        final actionCodeSettings = ActionCodeSettings(
          url: EnvironmentConfig.current.environment == Environment.staging ||
                  EnvironmentConfig.current.environment ==
                      Environment.development
              ? 'https://knkresearchai-staging.web.app/verify-email?email=${user.email}'
              : 'https://knkresearchai.com/verify-email?email=${user.email}', // Replace with your app's deep link
          handleCodeInApp: false,
        );

        await user.sendEmailVerification(actionCodeSettings);
        _startCooldown(); // Start cooldown after sending
        if (context.mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Verification email sent! Please check your inbox (and spam folder).'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (user != null && user.emailVerified) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your email is already verified.'),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.pop(context); // Close dialog
          widget.onVerified?.call(); // Notify listener
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error resending verification email: Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        context.go('/signin'); // Navigate to sign-in after sign out
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final userEmail = user?.email ?? 'your email address';
    final Color primaryColor =
        Theme.of(context).primaryColor; // Example: Color(0xFF1E3A8A)
    final Color textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;
    final Color titleColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Verification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                // IconButton(
                //   icon: const Icon(Icons.close),
                //   tooltip: 'Close',
                //   onPressed: () => Navigator.pop(context),
                //   color: textColor,
                // ),
              ],
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.mark_email_unread_outlined,
              size: 60,
              color: primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Verify Your Email Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We have sent a verification link to $userEmail. Please click the link in the email to activate your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.3),
                    width: 1,
                  )),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you don\'t see the email, please check your spam or junk folder.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text(_isCooldownActive
                  ? 'Resend Email ($_cooldownSeconds\s)'
                  : 'Resend Verification Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize:
                    const Size(double.infinity, 48), // Make button wider
              ),
              onPressed: _isCooldownActive
                  ? null
                  : () => _resendVerificationEmail(context),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _signOut(context),
              style: TextButton.styleFrom(
                foregroundColor: textColor.withOpacity(0.7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Switch to Different Account'),
            ),
          ],
        ),
      ),
    );
  }
}
