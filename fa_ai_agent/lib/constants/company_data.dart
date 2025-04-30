import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyData {
  // Singleton instance
  static final CompanyData _instance = CompanyData._internal();
  factory CompanyData() => _instance;
  CompanyData._internal();

  // Cached streams
  static Stream<List<Map<String, String>>>? _mega7CompaniesStream;
  static Stream<List<Map<String, String>>>? _mega7CompaniesForButtonsStream;

  static Stream<List<Map<String, String>>> streamMega7Companies() {
    _mega7CompaniesStream ??= FirebaseFirestore.instance
        .collection('mega7')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {data['ticker'] as String: data['name'] as String};
      }).toList();
    });
    return _mega7CompaniesStream!;
  }

  static Stream<List<Map<String, String>>> streamMega7CompaniesForButtons() {
    _mega7CompaniesForButtonsStream ??= FirebaseFirestore.instance
        .collection('mega7')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // For buttons, we use shorter names
        final name = (data['name'] as String).split(' ')[0];
        return {data['ticker'] as String: name};
      }).toList();
    });
    return _mega7CompaniesForButtonsStream!;
  }

  static Future<List<Map<String, String>>> getMega7Companies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mega7')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {data['ticker'] as String: data['name'] as String};
      }).toList();
    } catch (e) {
      print('Error fetching mega7 companies: $e');
      // Return empty list in case of error
      return [];
    }
  }

  static Future<List<Map<String, String>>> getMega7CompaniesForButtons() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mega7')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // For buttons, we use shorter names
        final name = (data['name'] as String).split(' ')[0];
        return {data['ticker'] as String: name};
      }).toList();
    } catch (e) {
      print('Error fetching mega7 companies for buttons: $e');
      // Return empty list in case of error
      return [];
    }
  }
}
