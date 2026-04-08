import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary gradient
  static const Color primaryAmber = Color(0xFFF59E0B);
  static const Color primaryOrange = Color(0xFFEA580C);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAmber, primaryOrange],
  );

  // Backgrounds
  static const Color scaffoldLight = Color(0xFFFFFDF7);
  static const Color surfaceLight = Color(0xFFFFFBEB);
  static const Color cardLight = Colors.white;
  static const Color cardBorder = Color(0xFFE7E5E4);

  // Dark theme backgrounds
  static const Color scaffoldDark = Color(0xFF1C1917);
  static const Color surfaceDark = Color(0xFF292524);
  static const Color cardDark = Color(0xFF292524);

  // Category pastels (background / border)
  static const Color amberBg = Color(0xFFFEF3C7);
  static const Color amberBorder = Color(0xFFFDE68A);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color greenBorder = Color(0xFFA7F3D0);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color blueBorder = Color(0xFFBFDBFE);
  static const Color pinkBg = Color(0xFFFDF2F8);
  static const Color pinkBorder = Color(0xFFFBCFE8);
  static const Color purpleBg = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFFECACA);

  // Text (Stone scale)
  static const Color textPrimary = Color(0xFF292524);
  static const Color textSecondary = Color(0xFF78716C);
  static const Color textTertiary = Color(0xFFA8A29E);
  static const Color textOnPrimary = Color(0xFF451A03);

  // Dark text
  static const Color textPrimaryDark = Color(0xFFF5F5F4);
  static const Color textSecondaryDark = Color(0xFFA8A29E);

  // Status
  static const Color statusError = Color(0xFFDC2626);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusSuccess = Color(0xFF22C55E);

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> fabShadow = [
    BoxShadow(color: primaryAmber.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  // Helper: status color from enum/string
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open' || 'pending' || 'overdue':
        return statusError;
      case 'inprogress' || 'in progress' || 'in_progress' || 'approved':
        return statusWarning;
      case 'resolved' || 'completed' || 'paid':
        return statusSuccess;
      default:
        return textTertiary;
    }
  }

  // Helper: priority color
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return statusError;
      case 'medium':
        return statusWarning;
      case 'low':
        return statusSuccess;
      default:
        return textTertiary;
    }
  }
}
