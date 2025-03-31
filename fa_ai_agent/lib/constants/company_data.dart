import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyData {
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
