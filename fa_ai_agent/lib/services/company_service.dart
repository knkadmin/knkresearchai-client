import 'package:fa_ai_agent/constants/company_data.dart';

/// Service for handling company-related business logic
class CompanyService {
  // Singleton instance
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  /// Checks if a company is part of the Magnificent 7
  Future<bool> isMag7Company(String tickerCode) async {
    try {
      final companies = await CompanyData.getMega7Companies();
      return companies.any((company) => company.keys.first == tickerCode);
    } catch (e) {
      print('Error checking if company is Mag 7: $e');
      return false;
    }
  }
}
