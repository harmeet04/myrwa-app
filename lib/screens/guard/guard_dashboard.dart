import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../widgets/section_header.dart';
import '../../widgets/warm_card.dart';
import '../auth/auth_screen.dart';

class GuardDashboard extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const GuardDashboard({super.key, required this.onThemeToggle});

  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  final _otpController = TextEditingController();
  final _qrController = TextEditingController();
  String? _otpResult;
  Map<String, dynamic>? _otpMatchedVisitor;
  String? _qrResult;
  Map<String, dynamic>? _qrMatchedPass;

  String get _society => PrefsService.societyName;

  @override
  void dispose() {
    _otpController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  // ── Gate entry logging ──
  void _logGateEntry(Visitor v) {
    FirestoreService.addDoc('gate_log', {
      'visitorName': v.name,
      'flatVisiting': v.flat,
      'purpose': v.purpose,
      'timeIn': Timestamp.fromDate(DateTime.now()),
      'exited': false,
      'society': _society,
    });
  }

  void _allowEntry(String docId, Visitor v) async {
    await FirestoreService.updateVisitor(docId, {'status': 'approved'});
    _logGateEntry(v);
    if (mounted) showSnack(context, '${v.name} allowed entry');
  }

  void _denyEntry(String docId) async {
    await FirestoreService.updateVisitor(docId, {'status': 'rejected'});
    if (mounted) showSnack(context, 'Visitor denied');
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthScreen(onThemeToggle: widget.onThemeToggle),
      ),
      (_) => false,
    );
  }

  // ── OTP verification ──
  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    final snap = await FirebaseFirestore.instance
        .collection('visitors')
        .where('society', isEqualTo: _society)
        .where('otp', isEqualTo: otp)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      setState(() {
        _otpResult = 'invalid';
        _otpMatchedVisitor = null;
      });
    } else {
      final doc = snap.docs.first;
      setState(() {
        _otpResult = 'found';
        _otpMatchedVisitor = {'id': doc.id, ...doc.data()};
      });
    }
  }

  void _allowOtpVisitor() async {
    if (_otpMatchedVisitor == null) return;
    final id = _otpMatchedVisitor!['id'] as String;
    final v = Visitor(
      id: id,
      name: _otpMatchedVisitor!['name'] ?? '',
      purpose: _otpMatchedVisitor!['purpose'] ?? '',
      flat: _otpMatchedVisitor!['flat'] ?? '',
      date: DateTime.now(),
      otp: _otpMatchedVisitor!['otp'] ?? '',
    );
    await FirestoreService.updateVisitor(id, {'status': 'approved'});
    _logGateEntry(v);
    setState(() {
      _otpResult = null;
      _otpMatchedVisitor = null;
      _otpController.clear();
    });
    if (mounted) showSnack(context, '${v.name} allowed entry via OTP');
  }

  // ── QR verification ──
  void _verifyQr() async {
    final code = _qrController.text.trim();
    if (code.isEmpty) return;

    final snap = await FirebaseFirestore.instance
        .collection('qr_passes')
        .where('society', isEqualTo: _society)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      setState(() {
        _qrResult = 'invalid';
        _qrMatchedPass = null;
      });
    } else {
      final doc = snap.docs.first;
      final data = doc.data();
      if (data['used'] == true) {
        setState(() {
          _qrResult = 'used';
          _qrMatchedPass = null;
        });
      } else {
        setState(() {
          _qrResult = 'valid';
          _qrMatchedPass = {'id': doc.id, ...data};
        });
      }
    }
  }

  void _markQrUsed() async {
    if (_qrMatchedPass == null) return;
    final id = _qrMatchedPass!['id'] as String;
    await FirebaseFirestore.instance.collection('qr_passes').doc(id).update({'used': true});
    setState(() {
      _qrResult = null;
      _qrMatchedPass = null;
      _qrController.clear();
    });
    if (mounted) showSnack(context, 'QR pass marked as used');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Guard Panel \u2014 $_society',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPendingVisitors(),
            _buildVerifyOtp(),
            _buildScanQr(),
            _buildTodayGateLog(),
            _buildEmergencyAlerts(),
          ],
        ),
      ),
    );
  }

  // ── Section 1: Pending Visitors ──
  Widget _buildPendingVisitors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '\u{1F6B6}', title: 'Pending Visitors'),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.visitorsStream(_society),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data?.docs ?? [];
            final pending = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return (data['status'] ?? 'pending') == 'pending';
            }).toList();

            if (pending.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Text('No pending visitors', style: TextStyle(color: AppColors.textTertiary)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: pending.length,
              itemBuilder: (context, i) {
                final doc = pending[i];
                final v = FirestoreService.visitorFromDoc(doc);
                return WarmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.amberBg,
                            child: const Icon(Icons.person, color: AppColors.primaryAmber),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${v.purpose} \u2022 Flat ${v.flat}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          _statusChip('pending'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text('OTP: ${v.otp}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryOrange)),
                          const SizedBox(width: AppSpacing.md),
                          Text(formatTime(v.date), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _allowEntry(doc.id, v),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Allow Entry'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.statusSuccess,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _denyEntry(doc.id),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Deny'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.statusError),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── Section 2: Verify OTP ──
  Widget _buildVerifyOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '\u{1F511}', title: 'Verify OTP'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: WarmCard(
            child: Column(
              children: [
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter visitor OTP',
                    prefixIcon: const Icon(Icons.pin),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: AppColors.primaryAmber),
                      onPressed: _verifyOtp,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
                  ),
                ),
                if (_otpResult == 'invalid') ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.redBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error, color: AppColors.statusError, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Invalid OTP \u2014 no matching pending visitor', style: TextStyle(color: AppColors.statusError, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                if (_otpResult == 'found' && _otpMatchedVisitor != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Match found!', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusSuccess)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Name: ${_otpMatchedVisitor!['name']}'),
                        Text('Purpose: ${_otpMatchedVisitor!['purpose']}'),
                        Text('Flat: ${_otpMatchedVisitor!['flat']}'),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _allowOtpVisitor,
                            icon: const Icon(Icons.check),
                            label: const Text('Allow Entry'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.statusSuccess,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Section 3: Scan QR ──
  Widget _buildScanQr() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '\u{1F4F1}', title: 'Scan QR'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: WarmCard(
            child: Column(
              children: [
                TextField(
                  controller: _qrController,
                  decoration: InputDecoration(
                    labelText: 'Enter QR code manually',
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.primaryAmber),
                      onPressed: _verifyQr,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
                  ),
                ),
                if (_qrResult == 'invalid') ...[
                  const SizedBox(height: AppSpacing.md),
                  _resultBanner(
                    color: AppColors.redBg,
                    icon: Icons.error,
                    iconColor: AppColors.statusError,
                    text: 'Invalid QR code \u2014 no matching pass found',
                    textColor: AppColors.statusError,
                  ),
                ],
                if (_qrResult == 'used') ...[
                  const SizedBox(height: AppSpacing.md),
                  _resultBanner(
                    color: AppColors.amberBg,
                    icon: Icons.warning,
                    iconColor: AppColors.statusWarning,
                    text: 'This QR pass has already been used',
                    textColor: AppColors.primaryOrange,
                  ),
                ],
                if (_qrResult == 'valid' && _qrMatchedPass != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Valid pass!', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusSuccess)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Visitor: ${_qrMatchedPass!['visitorName'] ?? 'Unknown'}'),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _markQrUsed,
                            icon: const Icon(Icons.check),
                            label: const Text('Mark as Used'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.statusSuccess,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultBanner({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: TextStyle(color: textColor, fontSize: 13))),
        ],
      ),
    );
  }

  // ── Section 4: Today's Gate Log ──
  Widget _buildTodayGateLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '\u{1F4CB}', title: "Today's Gate Log"),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.gateLogStream(_society),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Text('No gate entries today', style: TextStyle(color: AppColors.textTertiary)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc = docs[i];
                final entry = FirestoreService.gateEntryFromDoc(doc);
                return WarmCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: entry.exited ? AppColors.cardBorder : AppColors.greenBg,
                        child: Icon(
                          entry.exited ? Icons.logout : Icons.login,
                          color: entry.exited ? AppColors.textTertiary : AppColors.statusSuccess,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.visitorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              'Flat ${entry.flatVisiting} \u2022 In: ${formatTime(entry.timeIn)}${entry.timeOut != null ? " \u2022 Out: ${formatTime(entry.timeOut!)}" : ""}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!entry.exited)
                        FilledButton.tonal(
                          onPressed: () async {
                            await FirestoreService.updateGateEntry(doc.id, {
                              'exited': true,
                              'timeOut': Timestamp.fromDate(DateTime.now()),
                            });
                            if (mounted) showSnack(context, '${entry.visitorName} marked as exited');
                          },
                          child: const Text('Mark Exit', style: TextStyle(fontSize: 12)),
                        )
                      else
                        const Chip(
                          label: Text('Exited', style: TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── Section 5: Emergency Alerts ──
  Widget _buildEmergencyAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '\u{1F6A8}', title: 'Emergency Alerts'),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.sosAlertsStream(_society),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data?.docs ?? [];
            final active = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['isActive'] == true;
            }).toList();

            if (active.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.statusSuccess),
                      SizedBox(width: AppSpacing.md),
                      Text('No active alerts. All clear.', style: TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: active.length,
              itemBuilder: (context, i) {
                final doc = active[i];
                final data = doc.data() as Map<String, dynamic>;
                final type = data['type'] ?? 'Emergency';
                final flat = data['flat'] ?? '';
                final time = (data['time'] as Timestamp?)?.toDate() ?? DateTime.now();
                return WarmCard(
                  pastelColor: AppColors.redBg,
                  borderColor: AppColors.redBorder,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.statusError,
                        child: Icon(
                          _sosIcon(type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$type Emergency \u2014 Flat $flat',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusError),
                            ),
                            Text(formatDateTime(time), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      _statusChip('active'),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  IconData _sosIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'medical':
        return Icons.medical_services;
      case 'thief':
      case 'security':
        return Icons.shield;
      default:
        return Icons.warning;
    }
  }
}
