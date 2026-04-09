import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth
  static bool get isLoggedIn => _prefs.getBool('isLoggedIn') ?? false;
  static set isLoggedIn(bool v) => _prefs.setBool('isLoggedIn', v);

  static bool get hasOnboarded => _prefs.getBool('hasOnboarded') ?? false;
  static set hasOnboarded(bool v) => _prefs.setBool('hasOnboarded', v);
  static Future<void> setOnboarded() async => await _prefs.setBool('hasOnboarded', true);

  // Profile
  static String get userName => _prefs.getString('userName') ?? '';
  static set userName(String v) => _prefs.setString('userName', v);

  static String get userFlat => _prefs.getString('userFlat') ?? '';
  static set userFlat(String v) => _prefs.setString('userFlat', v);

  static String get userPhone => _prefs.getString('userPhone') ?? '';
  static set userPhone(String v) => _prefs.setString('userPhone', v);

  static String get societyName => _prefs.getString('societyName') ?? '';
  static set societyName(String v) => _prefs.setString('societyName', v);

  static bool get isAdmin => _prefs.getBool('isAdmin') ?? false;
  static set isAdmin(bool v) => _prefs.setBool('isAdmin', v);

  static bool get isGatedCommunity => _prefs.getBool('isGatedCommunity') ?? true;
  static set isGatedCommunity(bool v) => _prefs.setBool('isGatedCommunity', v);

  static String get userId => _prefs.getString('userId') ?? '';
  static set userId(String v) => _prefs.setString('userId', v);

  // Community type: 'society' or 'sector'
  static String get communityType => _prefs.getString('communityType') ?? 'society';
  static set communityType(String v) => _prefs.setString('communityType', v);

  static bool get isSector => communityType == 'sector';

  // Language
  static String get languageCode => _prefs.getString('languageCode') ?? 'english';
  static set languageCode(String v) => _prefs.setString('languageCode', v);

  // Preferences
  static bool get isDarkMode => _prefs.getBool('isDarkMode') ?? false;
  static set isDarkMode(bool v) => _prefs.setBool('isDarkMode', v);

  static bool get notificationsEnabled => _prefs.getBool('notificationsEnabled') ?? true;
  static set notificationsEnabled(bool v) => _prefs.setBool('notificationsEnabled', v);

  // Font scaling: 0=small, 1=normal, 2=large
  static int get fontSizeIndex => _prefs.getInt('fontSizeIndex') ?? 1;
  static set fontSizeIndex(int v) => _prefs.setInt('fontSizeIndex', v);

  static double get textScaleFactor {
    switch (fontSizeIndex) {
      case 0: return 0.85;
      case 2: return 1.3;
      default: return 1.0;
    }
  }

  // Poll votes: pollId -> votedIndex
  static Map<String, int> get pollVotes {
    final s = _prefs.getString('pollVotes');
    if (s == null) return {};
    return (jsonDecode(s) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
  }
  static void savePollVote(String pollId, int index) {
    final m = pollVotes;
    m[pollId] = index;
    _prefs.setString('pollVotes', jsonEncode(m));
  }

  // RSVP status: eventId -> {rsvpd: bool, plusOnes: int}
  static Map<String, dynamic> get rsvpStatus {
    final s = _prefs.getString('rsvpStatus');
    if (s == null) return {};
    return jsonDecode(s) as Map<String, dynamic>;
  }
  static void saveRsvp(String eventId, bool rsvpd, int plusOnes) {
    final m = rsvpStatus;
    m[eventId] = {'rsvpd': rsvpd, 'plusOnes': plusOnes};
    _prefs.setString('rsvpStatus', jsonEncode(m));
  }

  // Bill payment status
  static List<String> get paidBillIds {
    return _prefs.getStringList('paidBillIds') ?? [];
  }
  static void markBillPaid(String billId) {
    final l = paidBillIds;
    if (!l.contains(billId)) l.add(billId);
    _prefs.setStringList('paidBillIds', l);
  }

  static void logout() {
    final dark = isDarkMode;
    final font = fontSizeIndex;
    _prefs.clear();
    isDarkMode = dark;
    fontSizeIndex = font;
  }
}
