import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/app_colors.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.admin_panel_settings),
          SizedBox(width: 8),
          Text('Admin Panel'),
        ]),
      ),
      body: ListView(
        children: [
          _AdminTile(icon: Icons.receipt_long, title: 'Society Bill Summary',
            subtitle: 'View who paid, who hasn\'t', color: AppColors.statusSuccess,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _BillSummaryPage()))),
          _AdminTile(icon: Icons.people, title: 'Manage Residents',
            subtitle: 'View all, remove members', color: AppColors.primaryAmber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ManageResidentsPage()))),
          _AdminTile(icon: Icons.report, title: 'All Complaints',
            subtitle: 'Respond and manage complaints', color: AppColors.statusWarning,
            onTap: () => Navigator.pop(context)),
          _AdminTile(icon: Icons.campaign, title: 'Manage Notices',
            subtitle: 'Pin/unpin, post announcements', color: AppColors.primaryAmber,
            onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AdminTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _BillSummaryPage extends StatelessWidget {
  const _BillSummaryPage();

  @override
  Widget build(BuildContext context) {
    final bills = MockData.allSocietyBills;
    final paid = bills.where((b) => b.status == BillStatus.paid).toList();
    final unpaid = bills.where((b) => b.status != BillStatus.paid).toList();
    final totalCollected = paid.fold<double>(0, (s, b) => s + b.amount);
    final totalPending = unpaid.fold<double>(0, (s, b) => s + b.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Society Bill Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _SummaryCard('Collected', formatCurrency(totalCollected), AppColors.statusSuccess)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard('Pending', formatCurrency(totalPending), AppColors.statusWarning)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _SummaryCard('Paid', '${paid.length} flats', AppColors.statusSuccess)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard('Unpaid', '${unpaid.length} flats', AppColors.statusError)),
          ]),
          const SizedBox(height: 20),
          const Text('Paid ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.statusSuccess)),
          const SizedBox(height: 8),
          ...paid.map((b) => ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 20),
            title: Text('Flat ${b.flat}', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(b.title),
            trailing: Text(formatCurrency(b.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusSuccess)),
          )),
          const SizedBox(height: 16),
          const Text('Unpaid ❌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.statusError)),
          const SizedBox(height: 8),
          ...unpaid.map((b) => ListTile(
            dense: true,
            leading: Icon(
              b.status == BillStatus.overdue ? Icons.error : Icons.pending,
              color: b.status == BillStatus.overdue ? AppColors.statusError : AppColors.statusWarning, size: 20,
            ),
            title: Text('Flat ${b.flat}', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('${b.title} • Due: ${formatDate(b.dueDate)}'),
            trailing: Text(formatCurrency(b.amount), style: TextStyle(
              fontWeight: FontWeight.bold, color: b.status == BillStatus.overdue ? AppColors.statusError : AppColors.statusWarning)),
          )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    ),
  );
}

class _ManageResidentsPage extends StatefulWidget {
  const _ManageResidentsPage();

  @override
  State<_ManageResidentsPage> createState() => _ManageResidentsPageState();
}

class _ManageResidentsPageState extends State<_ManageResidentsPage> {
  late List<Resident> _residents;

  @override
  void initState() {
    super.initState();
    _residents = List.from(MockData.residents);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Residents (${_residents.length})'),
      ),
      body: ListView.builder(
        itemCount: _residents.length,
        itemBuilder: (_, i) {
          final r = _residents[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(r.avatarColor),
              child: Text(r.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Row(children: [
              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (r.isAdmin) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(4)),
                  child: Text('Admin', style: TextStyle(fontSize: 10, color: cs.primary)),
                ),
              ],
            ]),
            subtitle: Text('Flat ${r.flat} • ${r.phone}'),
            trailing: r.isAdmin ? null : IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.statusError),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Remove Resident'),
                    content: Text('Remove ${r.name} (${r.flat}) from society?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.statusError),
                        onPressed: () {
                          setState(() => _residents.removeAt(i));
                          Navigator.pop(context);
                          showSnack(context, '${r.name} removed');
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
