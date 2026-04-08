import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packages & Deliveries'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Collected'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.collectionStream('packages', society),
        builder: (context, snapshot) {
          List<_Package> packages;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            packages = snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return _Package(
                id: doc.id,
                courierName: d['courierName'] ?? '',
                awbNumber: d['awbNumber'] ?? '',
                flat: d['flat'] ?? '',
                type: d['type'] ?? 'Parcel',
                receivedAt: (d['receivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                collectedAt: (d['collectedAt'] as Timestamp?)?.toDate(),
                isCollected: d['isCollected'] ?? false,
                receivedBy: d['receivedBy'] ?? '',
                notes: d['notes'],
              );
            }).toList();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            packages = _MockPackages.packages;
          }

          final pending = packages.where((p) => !p.isCollected).toList();
          final collected = packages.where((p) => p.isCollected).toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildList(pending, false),
              _buildList(collected, true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<_Package> items, bool isCollected) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isCollected ? Icons.inventory_2_outlined : Icons.markunread_mailbox_outlined, size: 72, color: AppColors.cardBorder),
          const SizedBox(height: 16),
          Text(isCollected ? 'No collected packages yet' : 'No pending packages! 🎉',
            style: TextStyle(fontSize: 16, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        return _PackageCard(
          package: p,
          onCollect: isCollected ? null : () async {
            if (p.id != null) {
              await FirestoreService.updateDoc('packages', p.id!, {
                'isCollected': true,
                'collectedAt': Timestamp.fromDate(DateTime.now()),
              });
            }
            if (mounted) showSnack(context, '✅ Package from ${p.courierName} marked as collected!');
          },
          onTap: () => _showDetail(p),
        );
      },
    );
  }

  void _showDetail(_Package p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: _courierColor(p.courierName).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_courierIcon(p.courierName), color: _courierColor(p.courierName), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.courierName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(p.type, style: TextStyle(color: AppColors.textSecondary)),
              ])),
            ]),
            const SizedBox(height: 20),
            _DetailRow(Icons.confirmation_number_outlined, 'AWB Number', p.awbNumber),
            _DetailRow(Icons.home_outlined, 'Flat', p.flat),
            _DetailRow(Icons.access_time, 'Received', formatDateTime(p.receivedAt)),
            if (p.collectedAt != null) _DetailRow(Icons.check_circle_outline, 'Collected', formatDateTime(p.collectedAt!)),
            _DetailRow(Icons.person_outline, 'Received by', p.receivedBy),
            if (p.notes != null) _DetailRow(Icons.note_outlined, 'Notes', p.notes!),
            const SizedBox(height: 20),
            if (!p.isCollected)
              SizedBox(
                width: double.infinity, height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (p.id != null) {
                      await FirestoreService.updateDoc('packages', p.id!, {
                        'isCollected': true,
                        'collectedAt': Timestamp.fromDate(DateTime.now()),
                      });
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    showSnack(ctx, '✅ Package collected!');
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Mark as Collected'),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _courierColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('amazon')) return const Color(0xFFFF9900);
    if (n.contains('flipkart')) return const Color(0xFF2874F0);
    if (n.contains('swiggy')) return const Color(0xFFFC8019);
    if (n.contains('zomato')) return const Color(0xFFE23744);
    if (n.contains('delhivery')) return const Color(0xFFD40511);
    if (n.contains('bluedart')) return AppColors.primaryAmber;
    return AppColors.textPrimary;
  }

  IconData _courierIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('swiggy') || n.contains('zomato')) return Icons.restaurant;
    if (n.contains('grocery')) return Icons.shopping_basket;
    return Icons.inventory_2;
  }
}

class _PackageCard extends StatelessWidget {
  final _Package package;
  final VoidCallback? onCollect;
  final VoidCallback onTap;

  const _PackageCard({required this.package, this.onCollect, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = package;
    final color = _courierColor(p.courierName);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(_courierIcon(p.courierName), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.courierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text('AWB: ${p.awbNumber}', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(p.type, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(timeAgo(p.receivedAt), style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ]),
            ]),
            if (onCollect != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCollect,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mark as Collected'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.statusSuccess, padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
            if (p.isCollected && p.collectedAt != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.statusSuccess),
                const SizedBox(width: 4),
                Text('Collected ${timeAgo(p.collectedAt!)}', style: TextStyle(fontSize: 12, color: AppColors.statusSuccess)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Color _courierColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('amazon')) return const Color(0xFFFF9900);
    if (n.contains('flipkart')) return const Color(0xFF2874F0);
    if (n.contains('swiggy')) return const Color(0xFFFC8019);
    if (n.contains('zomato')) return const Color(0xFFE23744);
    if (n.contains('delhivery')) return const Color(0xFFD40511);
    if (n.contains('bluedart')) return AppColors.primaryAmber;
    return AppColors.textPrimary;
  }

  IconData _courierIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('swiggy') || n.contains('zomato')) return Icons.restaurant;
    if (n.contains('grocery')) return Icons.shopping_basket;
    return Icons.inventory_2;
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textTertiary),
      const SizedBox(width: 12),
      SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textTertiary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _Package {
  final String? id;
  final String courierName;
  final String awbNumber;
  final String flat;
  final String type;
  final DateTime receivedAt;
  DateTime? collectedAt;
  bool isCollected;
  final String receivedBy;
  final String? notes;

  _Package({this.id, required this.courierName, required this.awbNumber, required this.flat,
    required this.type, required this.receivedAt, this.collectedAt, this.isCollected = false,
    required this.receivedBy, this.notes});
}

class _MockPackages {
  static List<_Package> get packages => [
    _Package(courierName: 'Amazon', awbNumber: 'AMZ-78945612', flat: 'A-101', type: 'Parcel', receivedAt: DateTime(2026, 3, 24, 10, 30), receivedBy: 'Guard - Bahadur Singh', notes: 'Large box'),
    _Package(courierName: 'Flipkart', awbNumber: 'FK-456123789', flat: 'A-101', type: 'Parcel', receivedAt: DateTime(2026, 3, 24, 14, 15), receivedBy: 'Guard - Bahadur Singh'),
    _Package(courierName: 'Delhivery', awbNumber: 'DL-998877665', flat: 'A-101', type: 'Parcel', receivedAt: DateTime(2026, 3, 23, 11, 0), collectedAt: DateTime(2026, 3, 23, 18, 30), isCollected: true, receivedBy: 'Guard - Bahadur Singh'),
  ];
}
