import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
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
    final currentDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final userId = _auth.currentUser?.uid ?? 'anonymous';

    await _firestore.collection('hedgeFundWizard').add({
      'question': base64Question,
      'questionPlainText': question,
      'createdDate': currentDate,
      'sessionId': sessionId,
      'userId': userId,
    });
  }
}
