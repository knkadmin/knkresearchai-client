import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constructor to initialize persistence
  AuthService() {
    if (kIsWeb) {
      // Set persistence to LOCAL for web to remember the user between sessions
      FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      print('Firebase Auth persistence set to LOCAL');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get redirect result (important to call when app initializes on web)
  Future<UserCredential?> getRedirectResult() async {
    if (kIsWeb) {
      try {
        // Check if we have pending redirect operation
        return await _auth.getRedirectResult();
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

      // Set custom parameters - do not set client_id here
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      print('Starting Google sign-in process...');

      if (kIsWeb) {
        try {
          // Try popup first (works better for development)
          print('Attempting sign-in with popup...');
          return await _auth.signInWithPopup(googleProvider);
        } catch (e) {
          print('Popup sign-in failed: $e');

          // If popup fails, try redirect
          print('Attempting sign-in with redirect...');
          await _auth.signInWithRedirect(googleProvider);

          // This line won't execute if redirect is successful as page will refresh
          return null;
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
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      rethrow;
    }
  }
}
