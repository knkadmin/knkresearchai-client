import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/browse_history.dart';

class BrowseHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('browseHistory')
          .add(history.toMap());
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
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BrowseHistory.fromMap(doc.data()))
          .toList();
    });
  }
}
