import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import 'error_retry.dart';

/// A reusable widget that handles Firestore stream loading/error/empty states
class FirestoreStreamBuilder<T> extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final T Function(DocumentSnapshot doc) fromDoc;
  final Widget Function(BuildContext context, List<T> items) builder;
  final String emptyMessage;
  final IconData emptyIcon;

  const FirestoreStreamBuilder({
    super.key,
    required this.stream,
    required this.fromDoc,
    required this.builder,
    this.emptyMessage = 'Nothing here yet',
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorRetry(message: 'Failed to load data', onRetry: () {});
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 64, color: AppColors.cardBorder),
                const SizedBox(height: 12),
                Text(emptyMessage, style: TextStyle(fontSize: 15, color: AppColors.textTertiary), textAlign: TextAlign.center),
              ],
            ),
          );
        }

        final items = docs.map((d) {
          try {
            return fromDoc(d);
          } catch (_) {
            return null;
          }
        }).whereType<T>().toList();

        return builder(context, items);
      },
    );
  }
}
