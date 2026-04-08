import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
String formatDateTime(DateTime d) => DateFormat('dd MMM yyyy, hh:mm a').format(d);
String formatCurrency(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
String formatTime(DateTime d) => DateFormat('hh:mm a').format(d);

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(d);
}

Color statusColor(String s) => AppColors.statusColor(s);
Color priorityColor(String s) => AppColors.priorityColor(s);

IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'plumbing' || 'water':
      return Icons.plumbing;
    case 'electrical' || 'electricity':
      return Icons.electrical_services;
    case 'security':
      return Icons.security;
    case 'cleaning' || 'housekeeping':
      return Icons.cleaning_services;
    case 'noise':
      return Icons.volume_up;
    case 'parking':
      return Icons.local_parking;
    case 'lift' || 'elevator':
      return Icons.elevator;
    case 'maintenance':
      return Icons.build;
    case 'garden' || 'landscaping':
      return Icons.park;
    case 'pest control':
      return Icons.bug_report;
    default:
      return Icons.report_problem;
  }
}

void showSnack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.statusError : AppColors.statusSuccess,
      duration: const Duration(seconds: 2),
    ),
  );
}
