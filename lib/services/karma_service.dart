import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/prefs_service.dart';
import '../utils/app_colors.dart';
import 'auth_service.dart';

class KarmaService {
  static final _db = FirebaseFirestore.instance;

  // Point values
  static const int pollVote = 5;
  static const int eventRsvp = 10;
  static const int eventAttend = 20;
  static const int billOnTime = 15;
  static const int complaintFiled = 10;
  static const int commentPosted = 5;
  static const int marketplaceListing = 5;
  static const int helpfulAction = 10;

  /// Add karma points for the current user
  static Future<void> addPoints(int points, String reason) async {
    final uid = AuthService.uid;
    if (uid.isEmpty) return;

    final ref = _db.collection('karma').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists ? (snap.data()?['totalPoints'] ?? 0) as int : 0;
      final history = snap.exists
          ? List<Map<String, dynamic>>.from(snap.data()?['history'] ?? [])
          : <Map<String, dynamic>>[];

      history.add({
        'points': points,
        'reason': reason,
        'date': Timestamp.now(),
      });

      // Keep last 50 history entries
      if (history.length > 50) history.removeRange(0, history.length - 50);

      tx.set(ref, {
        'uid': uid,
        'name': PrefsService.userName,
        'flat': PrefsService.userFlat,
        'society': PrefsService.societyName,
        'totalPoints': current + points,
        'history': history,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }

  /// Get leaderboard for the society
  static Stream<QuerySnapshot> leaderboardStream(String society) {
    return _db
        .collection('karma')
        .where('society', isEqualTo: society)
        .orderBy('totalPoints', descending: true)
        .limit(20)
        .snapshots();
  }

  /// Get current user's karma
  static Stream<DocumentSnapshot> myKarmaStream() {
    final uid = AuthService.uid;
    if (uid.isEmpty) return const Stream.empty();
    return _db.collection('karma').doc(uid).snapshots();
  }

  /// Get badge based on total points
  static String getBadge(int points) {
    if (points >= 500) return '🏆 Community Champion';
    if (points >= 300) return '⭐ Super Active';
    if (points >= 150) return '🌟 Active Member';
    if (points >= 50) return '👋 Getting Started';
    return '🌱 New Member';
  }

  /// Get badge color
  static int getBadgeColor(int points) {
    if (points >= 500) return 0xFFD97706;
    if (points >= 300) return 0xFF7C3AED;
    if (points >= 150) return 0xFF2563EB;
    if (points >= 50) return 0xFF16A34A;
    return 0xFF78716C;
  }

  /// Show a snackbar toast after earning karma
  static void showKarmaToast(BuildContext context, int points, String reason) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🌟 +$points karma — $reason'),
      backgroundColor: AppColors.primaryAmber,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}
