import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/app_colors.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _alertSent = false;
  String _alertType = '';
  List<String> _contacts = [];

  @override
  void initState() {
    super.initState();
    _contacts = List.from(PrefsService.emergencyContacts);
  }

  void _triggerSos(String type) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _alertSent = true;
      _alertType = type;
    });
    AnalyticsService.logSosTriggered();
    await FirestoreService.sendSosAlert(type);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning, color: AppColors.statusError, size: 48),
        title: Text('\u{1F6A8} $type Alert Sent!'),
        content: Text(
          'All residents and emergency contacts have been notified.\n\n'
          '\u2705 Nearby residents notified\n'
          '\u2705 Emergency contacts called\n'
          '${PrefsService.isGatedCommunity ? '\u2705 Guards alerted\n' : ''}\n'
          'Stay calm. Help is on the way!\n'
          '\u0936\u093E\u0902\u0924 \u0930\u0939\u0947\u0902, \u092E\u0926\u0926 \u0906 \u0930\u0939\u0940 \u0939\u0948!',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _makeCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) showSnack(context, 'Cannot make call to $number');
    }
  }

  void _addContact() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Emergency Contact', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  showSnack(ctx, 'Please fill both fields');
                  return;
                }
                setState(() {
                  _contacts.add('$name|$phone');
                });
                PrefsService.setEmergencyContacts(_contacts);
                Navigator.pop(ctx);
                showSnack(context, '$name added to emergency contacts');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteContact(int index) {
    final parts = _contacts[index].split('|');
    final name = parts.isNotEmpty ? parts[0] : 'Contact';
    setState(() {
      _contacts.removeAt(index);
    });
    PrefsService.setEmergencyContacts(_contacts);
    showSnack(context, '$name removed');
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    final isGated = PrefsService.isGatedCommunity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: AppColors.statusError,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Select Emergency Type --
            Text('Select Emergency Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Tap a card to send alert / \u0906\u092A\u093E\u0924\u0915\u093E\u0932 \u092E\u0947\u0902 \u0915\u093E\u0930\u094D\u0921 \u0926\u092C\u093E\u090F\u0902', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            _EmergencyTypeCard(
              emoji: '\u{1F534}',
              title: 'Thief / Intruder',
              subtitle: 'Someone suspicious / \u091A\u094B\u0930',
              color: const Color(0xFFDC2626),
              onTap: () => _triggerSos('Thief/Intruder'),
            ),
            const SizedBox(height: 8),
            _EmergencyTypeCard(
              emoji: '\u{1F525}',
              title: 'Fire',
              subtitle: 'Fire emergency / \u0906\u0917',
              color: const Color(0xFFEA580C),
              onTap: () => _triggerSos('Fire'),
            ),
            const SizedBox(height: 8),
            _EmergencyTypeCard(
              emoji: '\u{1F3E5}',
              title: 'Medical',
              subtitle: 'Medical emergency / \u092E\u0947\u0921\u093F\u0915\u0932',
              color: const Color(0xFF2563EB),
              onTap: () => _triggerSos('Medical'),
            ),

            // -- Alert sent feedback --
            if (_alertSent) ...[
              const SizedBox(height: 16),
              Card(
                color: AppColors.statusSuccess.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.statusSuccess, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\u{1F6A8} $_alertType Alert Sent!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            const Text('All residents notified. Help is on the way!', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() { _alertSent = false; _alertType = ''; }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // -- Quick Emergency Actions --
            Text('Quick Emergency Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _EmergencyCard(icon: Icons.local_police, label: 'Police\n\u092A\u0941\u0932\u093F\u0938', number: '100', color: AppColors.primaryAmber, onTap: () => _makeCall('100'))),
                const SizedBox(width: 8),
                Expanded(child: _EmergencyCard(icon: Icons.fire_truck, label: 'Fire\n\u0926\u092E\u0915\u0932', number: '101', color: AppColors.primaryOrange, onTap: () => _makeCall('101'))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _EmergencyCard(icon: Icons.emergency, label: 'Ambulance\n\u090F\u092E\u094D\u092C\u0941\u0932\u0947\u0902\u0938', number: '108', color: AppColors.statusError, onTap: () => _makeCall('108'))),
                const SizedBox(width: 8),
                if (isGated)
                  Expanded(child: _EmergencyCard(icon: Icons.security, label: 'Guard\n\u0917\u093E\u0930\u094D\u0921', number: 'Gate', color: AppColors.primaryAmber, onTap: () => showSnack(context, 'Alerting society guard...')))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // -- My Emergency Contacts --
            Row(
              children: [
                Expanded(
                  child: Text('My Emergency Contacts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Contact'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No emergency contacts added yet.\nTap "Add Contact" to add one.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              ),
            ..._contacts.asMap().entries.map((entry) {
              final idx = entry.key;
              final parts = entry.value.split('|');
              final name = parts.isNotEmpty ? parts[0] : '';
              final phone = parts.length > 1 ? parts[1] : '';
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.redBg, child: Icon(Icons.person, color: AppColors.statusError)),
                  title: Text(name),
                  subtitle: Text(phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call, color: AppColors.statusSuccess),
                        onPressed: () => _makeCall(phone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.statusError),
                        onPressed: () => _deleteContact(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // -- Recent Emergency Alerts --
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
                        subtitle: Text('${formatDateTime(time)} \u2022 ${isActive ? "Active" : "Resolved"}'),
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
}

class _EmergencyTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyTypeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
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
