import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/error_retry.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_provider.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  int _selectedTab = 0; // 0 = Pending, 1 = History

  List<Bill> _pendingBills(List<Bill> allBills) {
    final paidIds = PrefsService.paidBillIds;
    return allBills
        .where((b) =>
            (b.status == BillStatus.pending || b.status == BillStatus.overdue) &&
            !paidIds.contains(b.id))
        .toList();
  }

  List<Bill> _historyBills(List<Bill> allBills) {
    final paidIds = PrefsService.paidBillIds;
    return allBills
        .where((b) => b.status == BillStatus.paid || paidIds.contains(b.id))
        .toList();
  }

  void _markAsPaid(Bill b) {
    PrefsService.markBillPaid(b.id);
    AnalyticsService.logBillPaid(b.amount.toDouble());
    setState(() {});
    showSnack(context, '${b.title} marked as paid');
  }

  Color _billColor(Bill b) {
    switch (b.status) {
      case BillStatus.paid:
        return AppColors.statusSuccess;
      case BillStatus.pending:
        return AppColors.statusWarning;
      case BillStatus.overdue:
        return AppColors.statusError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.read<LocaleProvider>().get('reminders')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.billsStream(society),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'Failed to load data',
              onRetry: () => setState(() {}),
            );
          }
          List<Bill> allBills;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            allBills = snapshot.data!.docs
                .map((d) => FirestoreService.billFromDoc(d))
                .toList();
          } else {
            allBills = MockData.bills;
          }

          final bills = _selectedTab == 0
              ? _pendingBills(allBills)
              : _historyBills(allBills);

          return Column(
            children: [
              // Tab selector
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Pending',
                      active: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _TabButton(
                      label: 'History',
                      active: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ],
                ),
              ),

              // Bill list
              Expanded(
                child: bills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedTab == 0
                                  ? Icons.check_circle_outline
                                  : Icons.receipt_long_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTab == 0
                                  ? 'All caught up! No pending bills.'
                                  : 'No payment history yet.',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryAmber,
                        onRefresh: () async => setState(() {}),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: bills.length,
                          itemBuilder: (_, i) => _BillCard(
                            bill: bills[i],
                            isPaid: _selectedTab == 1,
                            billColor: _billColor(bills[i]),
                            onMarkPaid: () => _markAsPaid(bills[i]),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Tab Button ───
class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryAmber : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bill Card ───
class _BillCard extends StatelessWidget {
  final Bill bill;
  final bool isPaid;
  final Color billColor;
  final VoidCallback onMarkPaid;

  const _BillCard({
    required this.bill,
    required this.isPaid,
    required this.billColor,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = bill.dueDate.difference(DateTime.now()).inDays;
    final isDueSoon = !isPaid && daysUntilDue >= 0 && daysUntilDue <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: billColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(categoryIcon(bill.category), color: billColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Title + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPaid
                            ? (bill.paidDate != null
                                ? 'Paid on ${formatDate(bill.paidDate!)}'
                                : 'Paid')
                            : 'Due: ${formatDate(bill.dueDate)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  formatCurrency(bill.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: billColor),
                ),
              ],
            ),

            // Smart reminder tip for pending bills not yet overdue
            if (!isPaid && daysUntilDue > 7) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blueBorder),
                ),
                child: Row(
                  children: [
                    const Text('\uD83D\uDCA1', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Tip: You usually pay around the 5th. Set a reminder?',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Due-soon warning chip
            if (isDueSoon) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.statusError.withValues(alpha: 0.3)),
                ),
                child: Text(
                  daysUntilDue == 0
                      ? '\u26A0\uFE0F Due today!'
                      : '\u26A0\uFE0F Due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusError),
                ),
              ),
            ],

            // Action row
            const SizedBox(height: 10),
            if (isPaid)
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.statusSuccess, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Paid',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusSuccess),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: onMarkPaid,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAmber,
                    side: const BorderSide(color: AppColors.primaryAmber),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Mark as Paid',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
