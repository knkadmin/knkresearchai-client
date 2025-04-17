import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:fa_ai_agent/models/user.dart';
import 'package:fa_ai_agent/models/subscription_type.dart';
import 'package:fa_ai_agent/models/financial_report.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  FirestoreService._internal() {
    // Configure Firestore settings
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      sslEnabled: true,
    );
  }

  // Add method to clean up Firestore listeners
  Future<void> cleanup() async {
    try {
      // Clear any pending operations
      await _firestore.terminate();
      await _firestore.clearPersistence();
    } catch (e) {
      print('Error cleaning up Firestore: $e');
    }
  }

  bool isCurrentUserAuthed() {
    return _auth.currentUser != null;
  }

  // Get current user's document reference
  DocumentReference<Map<String, dynamic>> get currentUserDoc {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    return _firestore.collection('users').doc(user.uid);
  }

  // Create or update user profile
  Future<void> createOrUpdateUserProfile({
    String? displayName,
    String? email,
    String? photoURL,
  }) async {
    try {
      // Check authentication first
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        throw Exception('No user logged in');
      }
      print('Attempting to create/update profile for user: ${user.uid}');

      // Check if user profile already exists
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        print('User profile already exists, skipping creation');
        return;
      }

      print('User profile does not exist, creating new profile');
      print('Writing to document path: ${userDocRef.path}');

      await userDocRef.set({
        'displayName': displayName ?? user.displayName,
        'email': email ?? user.email,
        'photoURL': photoURL ?? user.photoURL,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('User profile created successfully');
    } catch (e) {
      print('Error creating/updating user profile: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final doc = await currentUserDoc.get();
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  // Create a new document in a collection
  Future<DocumentReference> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _firestore.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating document: $e');
      rethrow;
    }
  }

  // Update a document
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating document: $e');
      rethrow;
    }
  }

  // Delete a document
  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  // Get a document
  Future<DocumentSnapshot> getDocument(
      String collection, String documentId) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      print('Error getting document: $e');
      rethrow;
    }
  }

  // Get a collection
  Future<QuerySnapshot> getCollection(String collection) async {
    try {
      return await _firestore.collection(collection).get();
    } catch (e) {
      print('Error getting collection: $e');
      rethrow;
    }
  }

  // Stream a collection
  Stream<QuerySnapshot> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // Stream a document
  Stream<DocumentSnapshot> streamDocument(
      String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  // Update user token
  Future<void> updateUserToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        throw Exception('No user logged in');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'token': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('User token updated successfully');
    } catch (e) {
      print('Error updating user token: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      rethrow;
    }
  }

  // Get user data
  Future<User?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return User.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Stream user data changes
  Stream<User?> streamUserData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? User.fromJson(doc.data()!) : null);
  }

  // Stream only the subscription field from user document
  Stream<String?> streamUserSubscription(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['subscription']?['type'] as String?);
  }

  // Update user profile
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserSubscription(
      String userId, Subscription subscription) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription': subscription.toJson(),
      });
    } catch (e) {
      print('Error updating user subscription: $e');
      rethrow;
    }
  }

  Future<bool> checkFirestoreConnection() async {
    try {
      await _firestore.collection('users').limit(1).get();
      return true;
    } catch (e) {
      print('Error checking Firestore connection: $e');
      return false;
    }
  }

  // Stream financial reports for a specific ticker
  Stream<FinancialReport?> streamFinancialReport(String ticker) {
    return _firestore
        .collection('financialReports')
        .doc(ticker.toLowerCase())
        .snapshots()
        .map(
            (doc) => doc.exists ? FinancialReport.fromJson(doc.data()!) : null);
  }

  // Update company document ticker field
  Future<void> checkCompanyExists(String ticker) async {
    try {
      final docRef =
          _firestore.collection('financialReports').doc(ticker.toLowerCase());
      final doc = await docRef.get();

      if (!doc.exists) {
        // Document doesn't exist, create it
        await docRef.set({
          'ticker': ticker,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating company ticker: $e');
      rethrow;
    }
  }

  // Increment the view count for a financial report
  Future<void> incrementReportViewCount(String ticker) async {
    try {
      final docRef =
          _firestore.collection('financialReports').doc(ticker.toLowerCase());
      await docRef.update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Log the error but don't rethrow, as failing to increment view count
      // shouldn't block the user from viewing the report.
      print('Error incrementing report view count for ticker $ticker: $e');
    }
  }
}
