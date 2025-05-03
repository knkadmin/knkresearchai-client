import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class HedgeFundWizardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getResponses(String sessionId) {
    return _firestore
        .collection('hedgeFundWizard')
        .where('sessionId', isEqualTo: sessionId)
        .where('result', isNotEqualTo: null)
        .snapshots();
  }

  Future<void> sendQuestion(String question, String sessionId) async {
    final base64Question = base64Encode(utf8.encode(question));
    final userId = _auth.currentUser?.uid ?? 'anonymous';

    await _firestore.collection('hedgeFundWizard').add({
      'question': base64Question,
      'questionPlainText': question,
      'createdDate': Timestamp.now(),
      'sessionId': sessionId,
      'userId': userId,
    });
  }

  Stream<List<Map<String, dynamic>>> getQuestionHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('hedgeFundWizard')
        .where('userId', isEqualTo: userId)
        .where('questionPlainText', isNotEqualTo: null)
        .where('result', isNotEqualTo: null)
        .orderBy('createdDate', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'question': data['questionPlainText'],
          'result': data['result'],
          'createdDate': data['createdDate'],
        };
      }).toList();
    });
  }
}
