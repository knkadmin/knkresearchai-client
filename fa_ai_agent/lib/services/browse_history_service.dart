import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/browse_history.dart';

class BrowseHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int maxHistoryRecords = 50;

  Future<void> addHistory({
    required String companyName,
    required String companyTicker,
    String reportType = 'financial',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if an entry with the same ticker exists
    final existingQuery = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('browseHistory')
        .where('companyTicker', isEqualTo: companyTicker)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      // Update the existing document's viewedDate
      await existingQuery.docs.first.reference.update({
        'viewedDate': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      // Create new history entry
      final history = BrowseHistory(
        companyName: companyName,
        companyTicker: companyTicker,
        reportType: reportType,
        viewedDate: DateTime.now(),
      );

      // Add the new entry
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('browseHistory')
          .add(history.toMap());

      // Get total count of history records
      final totalCount = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('browseHistory')
          .count()
          .get();

      // If we exceed the limit, delete the oldest records
      if (totalCount.count! > maxHistoryRecords) {
        final oldestRecords = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('browseHistory')
            .orderBy('viewedDate')
            .limit(totalCount.count! - maxHistoryRecords)
            .get();

        // Delete the oldest records
        for (var doc in oldestRecords.docs) {
          await doc.reference.delete();
        }
      }
    }
  }

  Stream<List<BrowseHistory>> getHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('browseHistory')
        .orderBy('viewedDate', descending: true)
        .limit(maxHistoryRecords)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BrowseHistory.fromMap(doc.data()))
            .toList());
  }

  Future<BrowseHistory?> getMostRecentHistory() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('browseHistory')
        .orderBy('viewedDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return BrowseHistory.fromMap(snapshot.docs.first.data());
  }
}
