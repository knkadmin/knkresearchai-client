import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:fa_ai_agent/models/user.dart';
import 'package:fa_ai_agent/models/subscription_type.dart';

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

  bool isCurrentUserAuthed() {
    return _auth.currentUser != null;
  }

  // Get current user's document reference
  DocumentReference<Map<String, dynamic>> get currentUserDoc {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    return _firestore.collection('users').doc(user.uid);
  }

  // Check Firestore connection
  Future<bool> checkConnection() async {
    try {
      print('Attempting to connect to Firestore...');

      // Check authentication state
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      // Try to read the user's own document first
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          print('User document does not exist');
          return false;
        }
      } catch (e) {
        print('Error reading user document: $e');
        return false;
      }

      // Try a simple query
      final result = await _firestore.collection('users').limit(1).get();
      print('Successfully connected to Firestore');
      return true;
    } catch (e) {
      print('Firestore connection check failed: $e');
      return false;
    }
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

      // Check connection
      final isConnected = await checkConnection();
      if (!isConnected) {
        throw Exception('No connection to Firestore');
      }

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
}
