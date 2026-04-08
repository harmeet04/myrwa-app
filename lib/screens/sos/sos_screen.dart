import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  bool _alertSent = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS / Emergency / आपातकाल'),
        backgroundColor: AppColors.statusError,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Big SOS Button
            const SizedBox(height: 20),
            Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _alertSent ? 1.0 : _pulse.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onLongPress: _triggerSos,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _alertSent ? AppColors.statusSuccess : AppColors.statusError,
                      boxShadow: [
                        BoxShadow(
                          color: (_alertSent ? AppColors.statusSuccess : AppColors.statusError).withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_alertSent ? Icons.check : Icons.sos, size: 56, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          _alertSent ? 'ALERT SENT!\nसूचना भेजी गई' : 'LONG PRESS\nदबाकर रखें',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _alertSent ? 'Help is on the way! / मदद आ रही है!' : 'Long press the button in emergency\nआपातकाल में बटन को दबाकर रखें',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
            ),
            if (_alertSent) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => setState(() => _alertSent = false),
                child: const Text('Reset / रीसेट'),
              ),
            ],

            const SizedBox(height: 32),

            // Quick Emergency Actions
            Text('Quick Emergency Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _EmergencyCard(icon: Icons.local_police, label: 'Police\nपुलिस', number: '100', color: AppColors.primaryAmber, onTap: () => showSnack(context, 'Calling Police (100)...'))),
                const SizedBox(width: 8),
                Expanded(child: _EmergencyCard(icon: Icons.fire_truck, label: 'Fire\nदमकल', number: '101', color: AppColors.primaryOrange, onTap: () => showSnack(context, 'Calling Fire Brigade (101)...'))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _EmergencyCard(icon: Icons.emergency, label: 'Ambulance\nएम्बुलेंस', number: '108', color: AppColors.statusError, onTap: () => showSnack(context, 'Calling Ambulance (108)...'))),
                const SizedBox(width: 8),
                Expanded(child: _EmergencyCard(icon: Icons.security, label: 'Guard\nगार्ड', number: 'Gate', color: AppColors.primaryAmber, onTap: () => showSnack(context, 'Alerting society guard...'))),
              ],
            ),

            const SizedBox(height: 24),

            // Emergency Contacts
            Text('My Emergency Contacts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._emergencyContacts.map((c) => Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.redBg, child: Icon(Icons.person, color: AppColors.statusError)),
                title: Text(c.$1),
                subtitle: Text(c.$2),
                trailing: IconButton(icon: const Icon(Icons.call, color: AppColors.statusSuccess), onPressed: () => showSnack(context, 'Calling ${c.$1}...')),
              ),
            )),

            const SizedBox(height: 24),

            // Recent Alerts from Firestore
            Text('Recent Emergency Alerts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.sosAlertsStream(society),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No recent alerts', style: TextStyle(color: AppColors.textTertiary)),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final type = d['type'] ?? 'SOS';
                    final flat = d['flat'] ?? '';
                    final time = (d['time'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final isActive = d['isActive'] ?? false;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.amberBg,
                          child: Icon(Icons.warning, color: AppColors.statusWarning),
                        ),
                        title: Text('$type Emergency - Flat $flat'),
                        subtitle: Text('${formatDateTime(time)} • ${isActive ? "Active" : "Resolved"}'),
                        trailing: Icon(
                          isActive ? Icons.warning : Icons.check_circle,
                          color: isActive ? AppColors.statusWarning : AppColors.statusSuccess,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSos() async {
    setState(() => _alertSent = true);
    await FirestoreService.sendSosAlert('SOS');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning, color: AppColors.statusError, size: 48),
        title: const Text('🚨 SOS Alert Sent!'),
        content: const Text(
          '✅ Guards alerted\n'
          '✅ Nearby residents notified\n'
          '✅ Emergency contacts called\n\n'
          'Stay calm. Help is on the way!\n'
          'शांत रहें, मदद आ रही है!',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  static const _emergencyContacts = [
    ('Priya Sharma (Wife)', '9876543210'),
    ('Rajesh Sharma (Father)', '9876543211'),
    ('Dr. Anita Kulkarni', '9800000003'),
  ];
}

class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyCard({required this.icon, required this.label, required this.number, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(radius: 24, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 28)),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(number, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
