import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirestoreService() {
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
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  // Stream user data changes
  Stream<Map<String, dynamic>?> streamUserData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  // Stream only the subscription field from user document
  Stream<String?> streamUserSubscription(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['subscription'] as String?);
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Convert any FieldValue.delete() to a proper Firestore delete operation
        final Map<String, dynamic> processedData = Map.from(data);
        processedData.removeWhere((key, value) => value == FieldValue.delete());

        // If there are any FieldValue.delete() values, we need to handle them separately
        final deleteFields = data.entries
            .where((entry) => entry.value == FieldValue.delete())
            .map((entry) => entry.key)
            .toList();

        if (deleteFields.isNotEmpty) {
          // Create a map with FieldValue.delete() for the fields to delete
          final deleteData = {
            for (var field in deleteFields) field: FieldValue.delete()
          };

          // Update with both the regular data and the delete operations
          await _firestore.collection('users').doc(user.uid).update({
            ...processedData,
            ...deleteData,
          });
        } else {
          // If no fields to delete, just update normally
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update(processedData);
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}
