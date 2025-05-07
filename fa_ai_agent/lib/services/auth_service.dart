import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.userChanges();

  // Get redirect result (important to call when app initializes on web)
  Future<UserCredential?> getRedirectResult() async {
    if (kIsWeb) {
      try {
        // Check if we have pending redirect operation
        final result = await _auth.getRedirectResult();
        if (result.user != null) {
          print(
              'Successfully signed in with redirect: ${result.user?.displayName}');
        }
        return result;
      } catch (e) {
        print('Error getting redirect result: $e');
        return null;
      }
    }
    return null;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Configure Google Sign-in
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add scopes
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
      googleProvider
          .addScope('https://www.googleapis.com/auth/userinfo.profile');

      // Set custom parameters
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
        'access_type': 'offline',
      });

      print('Starting Google sign-in process...');

      if (kIsWeb) {
        try {
          // Try popup first (works better for development)
          print('Attempting sign-in with popup...');
          final result = await _auth.signInWithPopup(googleProvider);
          print(
              'Successfully signed in with popup: ${result.user?.displayName}');
          return result;
        } catch (e) {
          print('Popup sign-in failed: $e');

          // If popup fails, try redirect
          print('Attempting sign-in with redirect...');
          await _auth.signInWithRedirect(googleProvider);
          return null; // Will be handled by getRedirectResult
        }
      } else {
        // For mobile platforms
        return await _auth.signInWithProvider(googleProvider);
      }
    } catch (e) {
      print('Error during Google sign in: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Successfully signed in with email: ${result.user?.email}');
      return result;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Successfully registered user: ${result.user?.email}');
      return result;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear any pending operations
      await _auth.currentUser?.reload();

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Clear any cached data
      await _auth.currentUser?.reload();

      print('Successfully signed out');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (displayName != null) {
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }
      print('Successfully updated user profile');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Stream user data from Firestore
  Stream<DocumentSnapshot> get userDocumentStream {
    final user = currentUser;
    if (user == null) {
      // Return an empty stream or throw an error if no user is logged in
      return Stream.empty();
      // Or: throw Exception("User not logged in");
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // Generate a 6-digit verification code
  String generateVerificationCode() {
    final random = Random();
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  // Send verification email (placeholder)
  Future<void> sendVerificationEmail(String email, String code) async {
    // In a real application, you would integrate an email service here.
    // For example, using a Firebase Function, SendGrid, AWS SES, etc.
    print('Sending verification email to: $email with code: $code');
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // For now, we just print it. You'll need to implement actual email sending.
  }
}
