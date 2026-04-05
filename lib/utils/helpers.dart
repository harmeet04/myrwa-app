import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
String formatDateTime(DateTime d) => DateFormat('dd MMM, hh:mm a').format(d);
String formatCurrency(double amount) => '₹${NumberFormat('#,##0').format(amount)}';
String formatTime(DateTime d) => DateFormat('hh:mm a').format(d);

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays > 30) return formatDate(d);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open': return Colors.orange;
    case 'inprogress':
    case 'in progress': return Colors.blue;
    case 'resolved': return Colors.green;
    case 'pending': return Colors.orange;
    case 'approved': return Colors.green;
    case 'rejected': return Colors.red;
    default: return Colors.grey;
  }
}

Color priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high': return Colors.red;
    case 'medium': return Colors.orange;
    case 'low': return Colors.green;
    default: return Colors.grey;
  }
}

IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'plumbing': return Icons.plumbing;
    case 'electrical': return Icons.electrical_services;
    case 'security': return Icons.security;
    case 'parking': return Icons.local_parking;
    case 'maintenance': return Icons.build;
    case 'noise': return Icons.volume_up;
    case 'cleanliness': return Icons.cleaning_services;
    case 'elevator': return Icons.elevator;
    case 'electronics': return Icons.devices;
    case 'furniture': return Icons.chair;
    case 'kids': return Icons.child_care;
    case 'appliances': return Icons.kitchen;
    case 'electricity': return Icons.bolt;
    case 'water': return Icons.water_drop;
    case 'gas': return Icons.local_fire_department;
    case 'internet': return Icons.wifi;
    default: return Icons.category;
  }
}

void showSnack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
