import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management / कर्मचारी')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaff,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.collectionStream('staff', society),
        builder: (context, snapshot) {
          List<_Staff> staffList;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            staffList = snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return _Staff(
                id: doc.id,
                name: d['name'] ?? '',
                role: d['role'] ?? '',
                phone: d['phone'] ?? '',
                staffId: d['staffId'] ?? '',
                servesFlats: d['servesFlats'] ?? '',
                timing: d['timing'] ?? '',
                salary: d['salary'] ?? 0,
                weekAttendance: List<bool>.from(d['weekAttendance'] ?? [true, true, true, true, true, false, false]),
                isPresent: d['isPresent'] ?? true,
                lastEntry: (d['lastEntry'] as Timestamp?)?.toDate(),
              );
            }).toList();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            staffList = _MockStaff.staff;
          }

          if (staffList.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No staff registered yet', style: TextStyle(color: Colors.grey.shade500)),
            ]));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: staffList.length,
            itemBuilder: (context, i) {
              final s = staffList[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(radius: 28, backgroundColor: s.color.withValues(alpha: 0.15),
                          child: Icon(s.icon, color: s.color, size: 28)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: s.isPresent ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(s.isPresent ? '✅ Present' : '❌ Absent',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.isPresent ? Colors.green.shade800 : Colors.red.shade800)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text('${s.role} • ID: ${s.staffId}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          Text('📱 ${s.phone} • 🏠 Serves: ${s.servesFlats}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ])),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Text('This week: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ...s.weekAttendance.map((present) => Container(
                          width: 28, height: 28,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: present ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text(present ? 'P' : 'A',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: present ? Colors.green.shade800 : Colors.red.shade800))),
                        )),
                        const Spacer(),
                        Text('${s.weekAttendance.where((a) => a).length}/7 days', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 8),
                      if (s.lastEntry != null)
                        Text('Last entry: ${formatDateTime(s.lastEntry!)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () async {
                            final newPresent = !s.isPresent;
                            if (s.id != null) {
                              await FirestoreService.updateDoc('staff', s.id!, {'isPresent': newPresent});
                            }
                            if (mounted) showSnack(context, newPresent ? '${s.name} marked present ✓' : '${s.name} marked absent');
                          },
                          icon: Icon(s.isPresent ? Icons.close : Icons.check, size: 18),
                          label: Text(s.isPresent ? 'Mark Absent' : 'Mark Present'),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () => _showIdCard(s),
                          icon: const Icon(Icons.badge, size: 18),
                          label: const Text('View ID / पहचान'),
                        )),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showIdCard(_Staff s) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [s.color.withValues(alpha: 0.1), Colors.white]),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(Icons.apartment, color: s.color),
              const SizedBox(width: 8),
              const Text('Society Staff ID Card', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const Divider(),
            const SizedBox(height: 8),
            CircleAvatar(radius: 40, backgroundColor: s.color.withValues(alpha: 0.15), child: Icon(s.icon, size: 40, color: s.color)),
            const SizedBox(height: 12),
            Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(s.role, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            _idRow('Staff ID', s.staffId),
            _idRow('Phone', s.phone),
            _idRow('Serves', s.servesFlats),
            _idRow('Timing', s.timing),
            _idRow('Salary', '₹${s.salary}/month'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: s.color), borderRadius: BorderRadius.circular(8)),
              child: Text('VERIFIED ✓', style: TextStyle(color: s.color, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _idRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );

  void _addStaff() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'Maid';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Staff / कर्मचारी जोड़ें', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name / नाम', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone / फोन', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(labelText: 'Role / भूमिका', prefixIcon: Icon(Icons.work)),
            items: ['Maid', 'Driver', 'Cook', 'Watchman', 'Gardener', 'Sweeper'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => role = v ?? role,
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) { showSnack(context, 'Please enter name', isError: true); return; }
              await FirestoreService.addDoc('staff', {
                'name': nameCtrl.text,
                'role': role,
                'phone': phoneCtrl.text.isEmpty ? '9876543299' : phoneCtrl.text,
                'staffId': 'STF-${DateTime.now().millisecondsSinceEpoch}',
                'servesFlats': PrefsService.userFlat,
                'timing': '8 AM - 6 PM',
                'salary': 5000,
                'weekAttendance': [true, true, true, false, true, true, false],
                'isPresent': true,
              });
              if (!context.mounted) return;
              Navigator.pop(ctx);
              showSnack(context, '${nameCtrl.text} added as $role ✓');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Staff', style: TextStyle(fontSize: 16)),
          )),
        ]),
      ),
    );
  }
}

class _Staff {
  final String? id;
  final String name;
  final String role;
  final String phone;
  final String staffId;
  final String servesFlats;
  final String timing;
  final int salary;
  final List<bool> weekAttendance;
  bool isPresent;
  DateTime? lastEntry;

  _Staff({this.id, required this.name, required this.role, required this.phone, required this.staffId,
    required this.servesFlats, required this.timing, required this.salary,
    required this.weekAttendance, this.isPresent = true, this.lastEntry});

  IconData get icon {
    switch (role) {
      case 'Maid': return Icons.cleaning_services;
      case 'Driver': return Icons.directions_car;
      case 'Cook': return Icons.restaurant;
      case 'Watchman': return Icons.security;
      case 'Gardener': return Icons.park;
      case 'Sweeper': return Icons.cleaning_services;
      default: return Icons.person;
    }
  }

  Color get color {
    switch (role) {
      case 'Maid': return Colors.purple;
      case 'Driver': return Colors.blue;
      case 'Cook': return Colors.orange;
      case 'Watchman': return Colors.teal;
      case 'Gardener': return Colors.green;
      case 'Sweeper': return Colors.brown;
      default: return Colors.grey;
    }
  }
}

class _MockStaff {
  static List<_Staff> get staff => [
    _Staff(name: 'Sunita Bai', role: 'Maid', phone: '9800100001', staffId: 'STF-001', servesFlats: 'A-101, A-102, A-201', timing: '7 AM - 11 AM', salary: 4000, weekAttendance: [true, true, true, true, true, false, true], lastEntry: DateTime(2026, 3, 24, 7, 15)),
    _Staff(name: 'Ramesh Driver', role: 'Driver', phone: '9800100002', staffId: 'STF-002', servesFlats: 'A-101', timing: '8 AM - 8 PM', salary: 12000, weekAttendance: [true, true, false, true, true, true, true], lastEntry: DateTime(2026, 3, 24, 8, 0)),
    _Staff(name: 'Bahadur Singh', role: 'Watchman', phone: '9800100004', staffId: 'STF-004', servesFlats: 'Main Gate', timing: '6 PM - 6 AM', salary: 15000, weekAttendance: [true, true, true, true, true, true, true], lastEntry: DateTime(2026, 3, 24, 18, 0)),
  ];
}
