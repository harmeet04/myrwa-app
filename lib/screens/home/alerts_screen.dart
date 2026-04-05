import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../utils/mock_data.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../visitors/visitors_screen.dart';
import '../complaints/complaints_screen.dart';
import '../packages/packages_screen.dart';
import '../sos/sos_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pendingVisitors = MockData.visitors.where((v) => v.status == VisitorStatus.pending).length;
    final openComplaints = MockData.complaints.where((c) => c.status == ComplaintStatus.open).length;

    final alerts = <_AlertItem>[
      if (pendingVisitors > 0) _AlertItem(
        Icons.person_add_rounded, 'Visitor Approval', '$pendingVisitors visitor(s) waiting for approval',
        Colors.orange, DateTime.now().subtract(const Duration(minutes: 5)), 'visitor',
      ),
      _AlertItem(
        Icons.inventory_2_rounded, 'Package Arrived', 'Amazon parcel received at gate',
        const Color(0xFFFF9900), DateTime.now().subtract(const Duration(hours: 1)), 'package',
      ),
      _AlertItem(
        Icons.inventory_2_rounded, 'Package Arrived', 'Flipkart delivery at gate',
        const Color(0xFF2874F0), DateTime.now().subtract(const Duration(hours: 3)), 'package',
      ),
      if (openComplaints > 0) _AlertItem(
        Icons.build_circle_rounded, 'Complaint Update', 'Water leakage fix in progress',
        Colors.blue, DateTime.now().subtract(const Duration(hours: 2)), 'complaint',
      ),
      _AlertItem(
        Icons.restaurant_rounded, 'Food Delivery', 'Zomato order waiting at gate',
        const Color(0xFFE23744), DateTime.now().subtract(const Duration(minutes: 30)), 'package',
      ),
      _AlertItem(
        Icons.campaign_rounded, 'New Notice', 'Water tank cleaning scheduled tomorrow',
        Colors.purple, DateTime.now().subtract(const Duration(hours: 6)), 'notice',
      ),
      _AlertItem(
        Icons.payment_rounded, 'Bill Due', 'Maintenance Q1 - ₹4,500 due in 5 days',
        Colors.red, DateTime.now().subtract(const Duration(days: 1)), 'bill',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => showSnack(context, 'All alerts marked as read ✓'),
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No alerts', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                  Text('You\'re all caught up! 🎉', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (_, i) {
                  final a = alerts[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Widget? screen;
                        if (a.type == 'visitor') screen = const VisitorsScreen();
                        if (a.type == 'package') screen = const PackagesScreen();
                        if (a.type == 'complaint') screen = const ComplaintsScreen();
                        if (screen != null) Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: a.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(a.icon, color: a.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(a.subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              ],
                            )),
                            Text(timeAgo(a.time), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _AlertItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final DateTime time;
  final String type;
  const _AlertItem(this.icon, this.title, this.subtitle, this.color, this.time, this.type);
}
