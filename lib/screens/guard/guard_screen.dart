import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart' show VisitorStatus;
import '../../utils/helpers.dart';
import '../../utils/mock_data.dart';
import '../../utils/app_colors.dart';

class GuardScreen extends StatefulWidget {
  const GuardScreen({super.key});

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final List<_GuardEntry> _entries = _MockGuardEntries.entries;
  final List<_SosAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guard Panel / गार्ड पैनल', style: TextStyle(fontSize: 16)),
            Text('Bahadur Singh • Main Gate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: AppColors.primaryOrange,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
            Tab(icon: Icon(Icons.people), text: 'Visitors'),
            Tab(icon: Icon(Icons.list_alt), text: 'Entry Log'),
            Tab(icon: Icon(Icons.sos), text: 'SOS Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildScanTab(),
          _buildVisitorsTab(),
          _buildEntryLogTab(),
          _buildSosTab(),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Simulated camera view
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scan frame
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryAmber, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Corner markers
                ..._cornerMarkers(),
                const Positioned(
                  bottom: 20,
                  child: Text('Point camera at QR code\nक्यूआर कोड पर कैमरा रखें', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
                const Positioned(
                  top: 20,
                  child: Icon(Icons.qr_code_scanner, color: AppColors.primaryAmber, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Manual entry
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _simulateScan,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAmber),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Simulate QR Scan', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),

          // Manual code entry
          TextField(
            decoration: InputDecoration(
              labelText: 'Enter Code Manually / कोड डालें',
              prefixIcon: const Icon(Icons.pin),
              suffixIcon: IconButton(icon: const Icon(Icons.check_circle, color: AppColors.primaryAmber), onPressed: _simulateScan),
            ),
          ),
          const SizedBox(height: 24),

          // Recent scans
          Align(alignment: Alignment.centerLeft, child: Text('Recent Scans / हाल के स्कैन', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          ...List.generate(3, (i) => Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: AppColors.greenBg, child: const Icon(Icons.check, color: AppColors.statusSuccess)),
              title: Text(['Ramesh Kumar', 'Amazon Delivery', 'Dr. Anita'][i]),
              subtitle: Text(['Code: 482916 • A-101', 'Code: 731054 • B-102', 'Code: 295837 • A-201'][i]),
              trailing: Text(['2 min ago', '15 min ago', '1 hr ago'][i], style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ),
          )),
        ],
      ),
    );
  }

  void _simulateScan() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 48),
        title: const Text('✅ QR Verified!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _scanRow('Visitor', 'Ramesh Kumar'),
            _scanRow('Purpose', 'Family Visit'),
            _scanRow('Flat', 'A-101'),
            _scanRow('Host', 'Rajesh Sharma'),
            _scanRow('Valid Until', formatDate(DateTime.now())),
            const Divider(),
            const Text('✅ Pass is valid. Allow entry.', style: TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.bold)),
            const Text('पास मान्य है। प्रवेश दें।', style: TextStyle(color: AppColors.statusSuccess, fontSize: 13)),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Reject')),
          FilledButton(
            onPressed: () {
              setState(() {
                _entries.insert(0, _GuardEntry(name: 'Ramesh Kumar', flat: 'A-101', timeIn: DateTime.now(), type: 'QR Pass', approvedBy: 'QR Verified'));
              });
              Navigator.pop(context);
              showSnack(context, 'Entry logged for Ramesh Kumar');
            },
            child: const Text('Allow Entry / प्रवेश दें'),
          ),
        ],
      ),
    );
  }

  Widget _scanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  List<Widget> _cornerMarkers() {
    const size = 20.0;
    const color = AppColors.primaryAmber;
    return [
      Positioned(left: 55, top: 50, child: Container(width: size, height: 3, color: color)),
      Positioned(left: 55, top: 50, child: Container(width: 3, height: size, color: color)),
      Positioned(right: 55, top: 50, child: Container(width: size, height: 3, color: color)),
      Positioned(right: 55, top: 50, child: Container(width: 3, height: size, color: color)),
      Positioned(left: 55, bottom: 50, child: Container(width: size, height: 3, color: color)),
      Positioned(left: 55, bottom: 50, child: Container(width: 3, height: size, color: color)),
      Positioned(right: 55, bottom: 50, child: Container(width: size, height: 3, color: color)),
      Positioned(right: 55, bottom: 50, child: Container(width: 3, height: size, color: color)),
    ];
  }

  Widget _buildVisitorsTab() {
    final visitors = MockData.visitors;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          color: AppColors.amberBg,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info, color: AppColors.statusWarning),
                const SizedBox(width: 8),
                Expanded(child: Text('${visitors.where((v) => v.status.name == 'pending').length} visitors waiting for approval', style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ),
        ...visitors.map((v) => Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor(v.status.name).withValues(alpha: 0.15),
              child: Icon(Icons.person, color: statusColor(v.status.name)),
            ),
            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${v.purpose} • ${v.flat} • OTP: ${v.otp}'),
            trailing: v.status.name == 'pending'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.check_circle, color: AppColors.statusSuccess), onPressed: () { setState(() => v.status = VisitorStatus.approved); showSnack(context, '${v.name} approved ✓'); }),
                      IconButton(icon: const Icon(Icons.cancel, color: AppColors.statusError), onPressed: () { setState(() => v.status = VisitorStatus.rejected); showSnack(context, '${v.name} rejected'); }),
                    ],
                  )
                : Chip(
                    label: Text(v.status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: statusColor(v.status.name))),
                    backgroundColor: statusColor(v.status.name).withValues(alpha: 0.1),
                    visualDensity: VisualDensity.compact,
                  ),
          ),
        )),
      ],
    );
  }

  Widget _buildEntryLogTab() {
    return Column(
      children: [
        // Summary strip
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.amberBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statChip('Today In', '${_entries.where((e) => !e.exited).length}', AppColors.statusSuccess),
              _statChip('Exited', '${_entries.where((e) => e.exited).length}', AppColors.primaryAmber),
              _statChip('Total', '${_entries.length}', AppColors.primaryAmber),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _entries.length,
            itemBuilder: (context, i) {
              final e = _entries[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: e.exited ? AppColors.cardBorder : AppColors.greenBg,
                    child: Icon(e.exited ? Icons.logout : Icons.login, color: e.exited ? AppColors.textTertiary : AppColors.statusSuccess),
                  ),
                  title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${e.flat} • ${e.type} • In: ${formatTime(e.timeIn)}${e.timeOut != null ? " • Out: ${formatTime(e.timeOut!)}" : ""}'),
                  trailing: e.exited
                      ? const Chip(label: Text('Exited', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact)
                      : FilledButton.tonal(
                          onPressed: () {
                            setState(() { e.exited = true; e.timeOut = DateTime.now(); });
                            showSnack(context, '${e.name} marked as exited');
                          },
                          child: const Text('Mark Exit', style: TextStyle(fontSize: 12)),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSosTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: _alerts.any((a) => a.isActive) ? AppColors.redBg : AppColors.greenBg,
          child: Row(
            children: [
              Icon(
                _alerts.any((a) => a.isActive) ? Icons.warning : Icons.check_circle,
                color: _alerts.any((a) => a.isActive) ? AppColors.statusError : AppColors.statusSuccess,
              ),
              const SizedBox(width: 12),
              Text(
                _alerts.any((a) => a.isActive) ? '🚨 ACTIVE ALERTS! Respond immediately!' : '✅ No active alerts. All clear.',
                style: TextStyle(fontWeight: FontWeight.bold, color: _alerts.any((a) => a.isActive) ? AppColors.statusError : AppColors.statusSuccess),
              ),
            ],
          ),
        ),
        // Simulate alert button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _alerts.insert(0, _SosAlert(
                    flat: 'B-${Random().nextInt(3) + 1}0${Random().nextInt(2) + 1}',
                    time: DateTime.now(),
                    type: ['Medical', 'Fire', 'Security', 'General'][Random().nextInt(4)],
                  ));
                });
                showSnack(context, '🚨 New SOS alert received!');
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.statusError),
              icon: const Icon(Icons.sos),
              label: const Text('Simulate SOS Alert'),
            ),
          ),
        ),
        Expanded(
          child: _alerts.isEmpty
              ? const Center(child: Text('No SOS alerts\nकोई SOS अलर्ट नहीं', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary)))
              : ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, i) {
                    final a = _alerts[i];
                    return Card(
                      color: a.isActive ? AppColors.redBg : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: a.isActive ? AppColors.statusError : AppColors.statusSuccess,
                          child: Icon(a.isActive ? Icons.warning : Icons.check, color: Colors.white),
                        ),
                        title: Text('${a.type} Emergency - Flat ${a.flat}', style: TextStyle(fontWeight: FontWeight.bold, color: a.isActive ? AppColors.statusError : null)),
                        subtitle: Text(formatDateTime(a.time)),
                        trailing: a.isActive
                            ? FilledButton(
                                onPressed: () => setState(() => a.isActive = false),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.statusSuccess),
                                child: const Text('Respond'),
                              )
                            : const Icon(Icons.check_circle, color: AppColors.statusSuccess),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GuardEntry {
  final String name;
  final String flat;
  final DateTime timeIn;
  DateTime? timeOut;
  final String type;
  final String approvedBy;
  bool exited;

  _GuardEntry({required this.name, required this.flat, required this.timeIn, this.timeOut, required this.type, required this.approvedBy, this.exited = false});
}

class _SosAlert {
  final String flat;
  final DateTime time;
  final String type;
  bool isActive;

  // ignore: unused_element_parameter
  _SosAlert({required this.flat, required this.time, required this.type, this.isActive = true});
}

class _MockGuardEntries {
  static List<_GuardEntry> get entries => [
    _GuardEntry(name: 'Swiggy Delivery', flat: 'A-201', timeIn: DateTime(2026, 3, 24, 12, 30), timeOut: DateTime(2026, 3, 24, 12, 45), type: 'Delivery', approvedBy: 'Amit Kumar', exited: true),
    _GuardEntry(name: 'Amazon Courier', flat: 'B-102', timeIn: DateTime(2026, 3, 24, 14, 0), type: 'Delivery', approvedBy: 'Sneha Desai'),
    _GuardEntry(name: 'Ramesh Kumar', flat: 'A-101', timeIn: DateTime(2026, 3, 24, 17, 0), type: 'QR Pass', approvedBy: 'QR Verified'),
    _GuardEntry(name: 'Plumber Raju', flat: 'C-201', timeIn: DateTime(2026, 3, 24, 9, 0), timeOut: DateTime(2026, 3, 24, 11, 30), type: 'Vendor', approvedBy: 'Kavita Joshi', exited: true),
    _GuardEntry(name: 'Sunita Bai (Maid)', flat: 'A-101', timeIn: DateTime(2026, 3, 24, 7, 15), type: 'Staff', approvedBy: 'Auto'),
    _GuardEntry(name: 'Flipkart Delivery', flat: 'A-301', timeIn: DateTime(2026, 3, 24, 10, 15), timeOut: DateTime(2026, 3, 24, 10, 25), type: 'Delivery', approvedBy: 'Vikram Singh', exited: true),
  ];
}
