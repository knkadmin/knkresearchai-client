import 'package:shared_preferences/shared_preferences.dart';

class PublicUserLastViewedReportTracker {
  static const String _lastViewedReportKey = 'last_viewed_report';
  static final PublicUserLastViewedReportTracker _instance =
      PublicUserLastViewedReportTracker._internal();
  late SharedPreferences _prefs;
  bool _pendingWatchlistAddition = false;

  factory PublicUserLastViewedReportTracker() {
    return _instance;
  }

  PublicUserLastViewedReportTracker._internal();

  bool get pendingWatchlistAddition => _pendingWatchlistAddition;
  set pendingWatchlistAddition(bool value) => _pendingWatchlistAddition = value;

  Future<void> init() async {
    print('Initializing PublicUserLastViewedReportTracker...');
    _prefs = await SharedPreferences.getInstance();
    print('PublicUserLastViewedReportTracker initialized successfully');
  }

  Future<void> saveLastViewedReport(String tickerCode) async {
    print('Saving last viewed report: $tickerCode');
    await _prefs.setString(_lastViewedReportKey, tickerCode);
    print('Last viewed report saved successfully');
  }

  String? getLastViewedReport() {
    final report = _prefs.getString(_lastViewedReportKey);
    print('Getting last viewed report: ${report ?? 'none'}');
    return report;
  }

  Future<void> clearLastViewedReport() async {
    print('Clearing last viewed report from cache...');
    await _prefs.remove(_lastViewedReportKey);
    print('Last viewed report cleared successfully');
  }
}
