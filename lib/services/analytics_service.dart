import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  static Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    await _analytics.logEvent(name: name, parameters: params);
  }

  // Convenience methods for common events
  static Future<void> logComplaintCreated(String category) async {
    await logEvent('complaint_created', params: {'category': category});
  }

  static Future<void> logVisitorAction(String action) async {
    await logEvent('visitor_action', params: {'action': action});
  }

  static Future<void> logBillPaid(double amount) async {
    await logEvent('bill_paid', params: {'amount': amount});
  }

  static Future<void> logPollVoted(String pollId) async {
    await logEvent('poll_voted', params: {'poll_id': pollId});
  }

  static Future<void> logSosTriggered() async {
    await logEvent('sos_triggered');
  }

  static Future<void> logNoticeCreated() async {
    await logEvent('notice_created');
  }

  static Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }
}
