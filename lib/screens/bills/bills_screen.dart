import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late List<Bill> _bills;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _bills = MockData.bills;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pending = _bills.where((b) => b.status != BillStatus.paid).toList();
    final paid = _bills.where((b) => b.status == BillStatus.paid).toList();
    final totalDue = pending.fold<double>(0, (s, b) => s + b.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Payments'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Paid')],
        ),
      ),
      body: Column(
        children: [
          if (pending.isNotEmpty) Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Due', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 4),
                    Text(formatCurrency(totalDue), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => showSnack(context, 'Payment gateway coming soon!'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: cs.primary),
                  child: const Text('Pay All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBillList(pending, false),
                _buildBillList(paid, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillList(List<Bill> bills, bool isPaid) {
    if (bills.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPaid ? Icons.receipt_long : Icons.check_circle, size: 64, color: Colors.grey),
          const SizedBox(height: 8),
          Text(isPaid ? 'No payment history' : 'All bills paid! 🎉'),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: bills.length,
      itemBuilder: (_, i) {
        final b = bills[i];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showBillDetail(context, b),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _billColor(b).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon(b.category), color: _billColor(b)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(b.status == BillStatus.paid
                          ? 'Paid on ${formatDate(b.paidDate!)}'
                          : 'Due: ${formatDate(b.dueDate)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(b.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _billColor(b))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _billColor(b).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(b.status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _billColor(b))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _billColor(Bill b) {
    switch (b.status) {
      case BillStatus.paid: return Colors.green;
      case BillStatus.pending: return Colors.orange;
      case BillStatus.overdue: return Colors.red;
    }
  }

  void _showBillDetail(BuildContext context, Bill b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(b.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(formatCurrency(b.amount), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _billColor(b))),
            const SizedBox(height: 12),
            Text(b.description, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Category: ${b.category}'),
            Text('Due: ${formatDate(b.dueDate)}'),
            if (b.paidDate != null) Text('Paid: ${formatDate(b.paidDate!)}'),
            const SizedBox(height: 20),
            if (b.status != BillStatus.paid) FilledButton(
              onPressed: () {
                setState(() {
                  b.status = BillStatus.paid;
                  b.paidDate = DateTime.now();
                });
                Navigator.pop(context);
                showSnack(context, 'Payment successful!');
              },
              child: Text('Pay ${formatCurrency(b.amount)}'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
