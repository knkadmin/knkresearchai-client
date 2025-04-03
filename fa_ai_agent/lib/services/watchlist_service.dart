import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fa_ai_agent/services/auth_service.dart';

class WatchlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get the watchlist collection reference for the current user
  CollectionReference<Map<String, dynamic>> _getWatchlistCollection() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('watchlist');
  }

  // Add a company to watchlist
  Future<void> addToWatchlist({
    required String companyName,
    required String companyTicker,
    String reportType = 'financial',
  }) async {
    try {
      final watchlistRef = _getWatchlistCollection();

      // Check if company is already in watchlist
      final existingDoc = await watchlistRef
          .where('companyTicker', isEqualTo: companyTicker)
          .get();

      if (existingDoc.docs.isEmpty) {
        await watchlistRef.add({
          'companyName': companyName,
          'companyTicker': companyTicker,
          'reportType': reportType,
          'createdDate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding to watchlist: $e');
      rethrow;
    }
  }

  // Remove a company from watchlist
  Future<void> removeFromWatchlist(String companyTicker) async {
    try {
      final watchlistRef = _getWatchlistCollection();

      final querySnapshot = await watchlistRef
          .where('companyTicker', isEqualTo: companyTicker)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error removing from watchlist: $e');
      rethrow;
    }
  }

  // Check if a company is in watchlist
  Stream<bool> isInWatchlist(String companyTicker) {
    final watchlistRef = _getWatchlistCollection();

    return watchlistRef
        .where('companyTicker', isEqualTo: companyTicker)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Get all watchlist items
  Stream<List<Map<String, dynamic>>> getWatchlist() {
    final watchlistRef = _getWatchlistCollection();

    return watchlistRef
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }
}
