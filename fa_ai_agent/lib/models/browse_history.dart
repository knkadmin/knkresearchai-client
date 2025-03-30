import 'package:cloud_firestore/cloud_firestore.dart';

class BrowseHistory {
  final String companyName;
  final String companyTicker;
  final String reportType;
  final DateTime viewedDate;

  BrowseHistory({
    required this.companyName,
    required this.companyTicker,
    required this.reportType,
    required this.viewedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyTicker': companyTicker,
      'reportType': reportType,
      'viewedDate': Timestamp.fromDate(viewedDate),
    };
  }

  factory BrowseHistory.fromMap(Map<String, dynamic> map) {
    return BrowseHistory(
      companyName: map['companyName'] ?? '',
      companyTicker: map['companyTicker'] ?? '',
      reportType: map['reportType'] ?? 'financial',
      viewedDate: (map['viewedDate'] as Timestamp).toDate(),
    );
  }
}
