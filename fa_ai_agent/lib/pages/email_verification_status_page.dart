import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationStatusPage extends StatefulWidget {
  const EmailVerificationStatusPage({super.key});

  @override
  State<EmailVerificationStatusPage> createState() =>
      _EmailVerificationStatusPageState();
}

class _EmailVerificationStatusPageState
    extends State<EmailVerificationStatusPage> {
  String _statusMessage = 'Verifying your email...';
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Ensure we have the latest user status
      if (mounted) {
        setState(() {
          if (user.emailVerified) {
            _isVerified = true;
            _statusMessage =
                'Your email has been successfully verified. You can now sign in or proceed to the dashboard if you are already signed in.';
          } else {
            _isVerified = false;
            _statusMessage =
                'Email verification seems to have failed or is still pending. Please try signing in, or resend the verification email from the sign-in page if prompted.';
          }
        });
      }
    } else {
      // No user is signed in, but the link was processed by Firebase.
      // This state can happen if the user clicked the link on a different browser/device
      // where they weren't signed in after initiating the signup.
      // Or, Firebase handled the oobCode and then redirected here.
      // We can assume the oobCode was valid if they got here via the ActionCodeSettings URL.
      // For simplicity, we'll show a generic success and guide to sign in.
      if (mounted) {
        setState(() {
          _isVerified =
              true; // Optimistically assume verification happened if they hit this page.
          _statusMessage =
              'Your email verification link has been processed. Please continue.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0), // Increased padding
          child: Container(
            // Added Container for compactness
            constraints: const BoxConstraints(
                maxWidth: 400), // Max width for the content
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch button
              children: <Widget>[
                Icon(
                  _isVerified
                      ? Icons.check_circle_outline
                      : Icons.highlight_off,
                  color: _isVerified
                      ? Colors.green.shade600 // Slightly darker green
                      : Colors.blue.shade800, // Dark Blue
                  size: 100, // Increased icon size
                ),
                const SizedBox(height: 32), // Increased spacing
                Text(
                  _isVerified
                      ? 'Verification Successful!'
                      : 'Verification Pending',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isVerified
                        ? Colors.green.shade700
                        : Colors.blue.shade800, // Dark Blue
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48), // Increased spacing before button
                Container(
                  width: double
                      .infinity, // Make button take available width in the constrained container
                  height: 48, // Standard height
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2563EB), // Primary blue from sign-in
                        Color(0xFF1E3A8A), // Darker blue from sign-in
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(8), // Consistent border radius
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB)
                            .withOpacity(0.3), // Shadow color from sign-in
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset:
                            const Offset(0, 4), // Shadow offset from sign-in
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.go('/');
                      },
                      borderRadius: BorderRadius.circular(
                          8), // Match container's border radius for ink effect
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16), // Standard padding
                        child: Center(
                          // Center the text
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white, // White text like sign-in
                              fontSize: 16, // Standard font size
                              fontWeight:
                                  FontWeight.bold, // Bold text like sign-in
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
