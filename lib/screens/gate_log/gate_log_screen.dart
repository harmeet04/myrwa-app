import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../utils/app_colors.dart';

class GateLogScreen extends StatefulWidget {
  const GateLogScreen({super.key});

  @override
  State<GateLogScreen> createState() => _GateLogScreenState();
}

class _GateLogScreenState extends State<GateLogScreen> {
  late List<GateEntry> _entries;
  bool _showMyFlat = false;

  @override
  void initState() {
    super.initState();
    _entries = MockData.gateEntries;
  }

  List<GateEntry> get _filtered {
    if (!_showMyFlat) return _entries;
    final myFlat = PrefsService.userFlat;
    return _entries.where((e) => e.flatVisiting == myFlat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Log / गेट लॉग'),
        actions: [
          FilterChip(
            label: Text(_showMyFlat ? 'My Flat' : 'All'),
            selected: _showMyFlat,
            onSelected: (v) => setState(() => _showMyFlat = v),
            backgroundColor: Colors.transparent,
            selectedColor: Colors.white24,
            labelStyle: const TextStyle(color: Colors.white),
            checkmarkColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _filtered.isEmpty
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.door_sliding, size: 64, color: Colors.grey), SizedBox(height: 8), Text('No entries found')],
            ))
          : RefreshIndicator(
              color: AppColors.primaryAmber,
              onRefresh: () async => setState(() {}),
              child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final e = _filtered[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline indicator
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: e.exited ? AppColors.cardBorder : AppColors.greenBg,
                              child: Icon(
                                e.exited ? Icons.logout : Icons.login,
                                size: 18,
                                color: e.exited ? AppColors.textSecondary : AppColors.statusSuccess,
                              ),
                            ),
                            if (i < _filtered.length - 1) Container(
                              width: 2, height: 30,
                              color: AppColors.cardBorder,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(e.visitorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: e.exited ? AppColors.cardBorder : AppColors.greenBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  e.exited ? 'Exited' : 'Inside',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                    color: e.exited ? AppColors.textSecondary : AppColors.statusSuccess),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.home, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('Flat ${e.flatVisiting}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              const SizedBox(width: 12),
                              Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('Approved: ${e.approvedBy}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.login, size: 14, color: AppColors.statusSuccess),
                              const SizedBox(width: 4),
                              Text('In: ${formatTime(e.timeIn)}', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                              if (e.timeOut != null) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.logout, size: 14, color: AppColors.statusError),
                                const SizedBox(width: 4),
                                Text('Out: ${formatTime(e.timeOut!)}', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                              ],
                            ]),
                            // Guard mark exit (mock)
                            if (!e.exited && PrefsService.isAdmin) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 28,
                                child: OutlinedButton.icon(
                                  onPressed: () => setState(() {
                                    e.exited = true;
                                    e.timeOut = DateTime.now();
                                  }),
                                  icon: const Icon(Icons.logout, size: 14),
                                  label: const Text('Mark Exit', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: AppColors.statusError,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )),
                      ],
                    ),
                  ),
                );
              },
              ),
            ),
    );
  }
}
