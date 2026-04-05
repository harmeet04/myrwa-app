import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _selectedMonth = 'March 2026';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Accounts / हिसाब'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildSummary(society),
          _buildLedger(society, 'income', Colors.green),
          _buildLedger(society, 'expense', Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummary(String society) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.collection('accounting_summary').where('society', isEqualTo: society).snapshots(),
      builder: (context, snapshot) {
        // Use Firestore data if available, otherwise mock
        String totalIncome = '₹7,20,000';
        String totalExpense = '₹5,85,000';
        String netSurplus = '₹1,35,000';
        String pendingDues = '₹1,08,000';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final d = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          totalIncome = formatCurrency((d['totalIncome'] ?? 720000).toDouble());
          totalExpense = formatCurrency((d['totalExpense'] ?? 585000).toDouble());
          netSurplus = formatCurrency((d['netSurplus'] ?? 135000).toDouble());
          pendingDues = formatCurrency((d['pendingDues'] ?? 108000).toDouble());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: const InputDecoration(labelText: 'Month / महीना', prefixIcon: Icon(Icons.calendar_month)),
              items: ['January 2026', 'February 2026', 'March 2026']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _SummaryCard(title: 'Total Income\nकुल आय', amount: totalIncome, icon: Icons.arrow_downward, color: Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Total Expense\nकुल खर्च', amount: totalExpense, icon: Icons.arrow_upward, color: Colors.red)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SummaryCard(title: 'Net Surplus\nबचत', amount: netSurplus, icon: Icons.savings, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Pending Dues\nबकाया', amount: pendingDues, icon: Icons.warning, color: Colors.orange)),
            ]),
            const SizedBox(height: 24),
            Text('Collection Status / वसूली', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const _CollectionBar(label: 'Maintenance', collected: 85),
            const _CollectionBar(label: 'Water Charges', collected: 92),
            const _CollectionBar(label: 'Electricity', collected: 78),
            const _CollectionBar(label: 'Parking', collected: 95),
            const _CollectionBar(label: 'Sinking Fund', collected: 70),
            const SizedBox(height: 24),
            Text('Expense Breakdown / खर्च विवरण', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._expenseBreakdown.map((e) => Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: e.$3.withValues(alpha: 0.15), child: Icon(e.$4, color: e.$3)),
                title: Text(e.$1),
                trailing: Text(e.$2, style: TextStyle(fontWeight: FontWeight.bold, color: e.$3)),
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showSnack(context, 'Report downloaded as PDF!'),
                icon: const Icon(Icons.download),
                label: const Text('Download Report / रिपोर्ट डाउनलोड'),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildLedger(String society, String type, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.collection('ledger_entries')
          .where('society', isEqualTo: society)
          .where('type', isEqualTo: type)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        List<_LedgerEntry> entries;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          entries = snapshot.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _LedgerEntry(
              description: d['description'] ?? '',
              amount: (d['amount'] ?? 0).toDouble(),
              date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
              category: d['category'] ?? '',
              icon: _categoryIcon(d['category'] ?? ''),
            );
          }).toList();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          entries = type == 'income' ? _incomeEntries : _expenseEntries;
        }

        if (entries.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No ${type} entries yet', style: TextStyle(color: Colors.grey.shade500)),
          ]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(e.icon, color: color)),
                title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${formatDate(e.date)} • ${e.category}'),
                trailing: Text('${color == Colors.green ? '+' : '-'}${formatCurrency(e.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
              ),
            );
          },
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance': return Icons.apartment;
      case 'parking': return Icons.local_parking;
      case 'facility': return Icons.meeting_room;
      case 'water': return Icons.water_drop;
      case 'interest': return Icons.savings;
      case 'penalty': return Icons.gavel;
      case 'security': return Icons.security;
      case 'housekeeping': return Icons.cleaning_services;
      case 'electricity': return Icons.bolt;
      case 'garden': return Icons.park;
      case 'repairs': return Icons.build;
      default: return Icons.receipt;
    }
  }

  static const _expenseBreakdown = [
    ('Security / सुरक्षा', '₹1,80,000', Colors.indigo, Icons.security),
    ('Housekeeping / सफाई', '₹95,000', Colors.teal, Icons.cleaning_services),
    ('Electricity / बिजली', '₹1,20,000', Colors.amber, Icons.bolt),
    ('Water / पानी', '₹45,000', Colors.blue, Icons.water_drop),
    ('Garden / बगीचा', '₹25,000', Colors.green, Icons.park),
    ('Lift Maintenance', '₹40,000', Colors.purple, Icons.elevator),
    ('Repairs / मरम्मत', '₹55,000', Colors.orange, Icons.build),
    ('Admin & Misc', '₹25,000', Colors.grey, Icons.receipt),
  ];

  static final _incomeEntries = [
    _LedgerEntry(description: 'Maintenance - Tower A', amount: 72000, date: DateTime(2026, 3, 1), category: 'Maintenance', icon: Icons.apartment),
    _LedgerEntry(description: 'Maintenance - Tower B', amount: 72000, date: DateTime(2026, 3, 1), category: 'Maintenance', icon: Icons.apartment),
    _LedgerEntry(description: 'Parking Charges', amount: 48000, date: DateTime(2026, 3, 3), category: 'Parking', icon: Icons.local_parking),
    _LedgerEntry(description: 'Community Hall Booking', amount: 5000, date: DateTime(2026, 3, 5), category: 'Facility', icon: Icons.meeting_room),
    _LedgerEntry(description: 'Water Charges', amount: 32000, date: DateTime(2026, 3, 1), category: 'Water', icon: Icons.water_drop),
  ];

  static final _expenseEntries = [
    _LedgerEntry(description: 'Security Guard Salary', amount: 60000, date: DateTime(2026, 3, 1), category: 'Security', icon: Icons.security),
    _LedgerEntry(description: 'Housekeeping Staff', amount: 32000, date: DateTime(2026, 3, 1), category: 'Housekeeping', icon: Icons.cleaning_services),
    _LedgerEntry(description: 'Electricity Bill - Common', amount: 45000, date: DateTime(2026, 3, 5), category: 'Electricity', icon: Icons.bolt),
    _LedgerEntry(description: 'Water Supply', amount: 15000, date: DateTime(2026, 3, 5), category: 'Water', icon: Icons.water_drop),
    _LedgerEntry(description: 'Garden Maintenance', amount: 8000, date: DateTime(2026, 3, 8), category: 'Garden', icon: Icons.park),
  ];
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, size: 18, color: color)),
        const SizedBox(height: 8),
        Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]),
    ),
  );
}

class _CollectionBar extends StatelessWidget {
  final String label;
  final int collected;
  const _CollectionBar({required this.label, required this.collected});

  @override
  Widget build(BuildContext context) {
    final color = collected > 90 ? Colors.green : (collected > 75 ? Colors.orange : Colors.red);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text('$collected%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: collected / 100, backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
        ),
      ]),
    );
  }
}

class _LedgerEntry {
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final IconData icon;
  _LedgerEntry({required this.description, required this.amount, required this.date, required this.category, required this.icon});
}
