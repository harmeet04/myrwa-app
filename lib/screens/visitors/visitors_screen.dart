import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  late List<Visitor> _visitors;

  @override
  void initState() {
    super.initState();
    _visitors = MockData.visitors;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVisitor(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Pre-approve'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _visitors.length,
        itemBuilder: (_, i) {
          final v = _visitors[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _statusColor(v.status).withValues(alpha: 0.15),
                        child: Icon(_purposeIcon(v.purpose), color: _statusColor(v.status)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(v.purpose, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(v.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(v.status.name.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(v.status))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.home, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Flat ${v.flat}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(formatTime(v.date), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('OTP: ${v.otp}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 2)),
                      ),
                    ],
                  ),
                  if (v.status == VisitorStatus.pending) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(() => v.status = VisitorStatus.rejected),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => setState(() => v.status = VisitorStatus.approved),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(VisitorStatus s) {
    switch (s) {
      case VisitorStatus.approved: return Colors.green;
      case VisitorStatus.pending: return Colors.orange;
      case VisitorStatus.rejected: return Colors.red;
      case VisitorStatus.completed: return Colors.grey;
    }
  }

  IconData _purposeIcon(String purpose) {
    if (purpose.toLowerCase().contains('delivery')) return Icons.delivery_dining;
    if (purpose.toLowerCase().contains('guest')) return Icons.person;
    return Icons.person_outline;
  }

  void _showAddVisitor(BuildContext context) {
    final nameCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Pre-approve Visitor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Visitor Name')),
            const SizedBox(height: 12),
            TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString().substring(0, 4);
                  setState(() {
                    _visitors.insert(0, Visitor(
                      id: 'v_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text,
                      purpose: purposeCtrl.text.isEmpty ? 'Guest Visit' : purposeCtrl.text,
                      flat: 'A-101',
                      date: DateTime.now(),
                      otp: otp,
                      status: VisitorStatus.approved,
                    ));
                  });
                  Navigator.pop(ctx);
                  showSnack(context, 'Visitor pre-approved! OTP: $otp');
                }
              },
              child: const Text('Approve & Generate OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
