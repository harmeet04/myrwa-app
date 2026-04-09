import 'package:flutter/material.dart';
import '../utils/mock_data.dart';
import '../utils/prefs_service.dart';
import '../models/models.dart';

class NotificationProvider extends ChangeNotifier {
  int _pendingVisitors = 0;
  int _pendingComplaints = 0;
  int _unreadNotices = 0;
  String? _latestMessage;

  int get pendingVisitors => _pendingVisitors;
  int get pendingComplaints => _pendingComplaints;
  int get unreadNotices => _unreadNotices;
  int get totalBadge => _pendingVisitors + _pendingComplaints + _unreadNotices;
  String? get latestMessage => _latestMessage;

  void init() {
    // Only count visitor notifications for gated communities
    _pendingVisitors = PrefsService.isGatedCommunity
        ? MockData.visitors
            .where((v) => v.status == VisitorStatus.pending)
            .length
        : 0;
    _pendingComplaints = MockData.complaints
        .where((c) => c.status == ComplaintStatus.open)
        .length;
    _unreadNotices = MockData.notices.where((n) {
      final age = DateTime.now().difference(n.date);
      return age.inDays < 3;
    }).length;
    notifyListeners();
  }

  void onNewMessage(String message) {
    _latestMessage = message;
    notifyListeners();
    // Clear after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (_latestMessage == message) {
        _latestMessage = null;
        notifyListeners();
      }
    });
  }

  void decrementVisitors() {
    if (_pendingVisitors > 0) _pendingVisitors--;
    notifyListeners();
  }

  void decrementComplaints() {
    if (_pendingComplaints > 0) _pendingComplaints--;
    notifyListeners();
  }
}
