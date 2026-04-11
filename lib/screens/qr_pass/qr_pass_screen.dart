import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class QrPassScreen extends StatefulWidget {
  const QrPassScreen({super.key});

  @override
  State<QrPassScreen> createState() => _QrPassScreenState();
}

class _QrPassScreenState extends State<QrPassScreen> {
  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(title: const Text('QR Visitor Pass / क्यूआर पास')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPass,
        icon: const Icon(Icons.add),
        label: const Text('Create Pass / पास बनाएं'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.collectionStream('qr_passes', society),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.qr_code_2, size: 72, color: AppColors.cardBorder),
              const SizedBox(height: 12),
              Text('No passes yet.\nTap + to create one.', textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;
              final visitorName = d['visitorName'] ?? '';
              final purpose = d['purpose'] ?? '';
              final validDate = (d['validDate'] as Timestamp?)?.toDate() ?? DateTime.now();
              final code = d['code'] ?? '';
              final isUsed = d['isUsed'] ?? false;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUsed ? AppColors.cardBorder : AppColors.amberBg,
                    child: Icon(isUsed ? Icons.check_circle : Icons.qr_code_2, color: isUsed ? AppColors.textTertiary : AppColors.primaryAmber),
                  ),
                  title: Text(visitorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$purpose • ${formatDate(validDate)}\nCode: $code'),
                  isThreeLine: true,
                  trailing: isUsed
                      ? Chip(label: const Text('Used', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.cardBorder)
                      : IconButton(
                          icon: const Icon(Icons.qr_code, size: 32, color: AppColors.primaryAmber),
                          onPressed: () => _showQr(docId, visitorName, purpose, validDate, code, isUsed),
                        ),
                  onTap: () => _showQr(docId, visitorName, purpose, validDate, code, isUsed),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQr(String docId, String visitorName, String purpose, DateTime validDate, String code, bool isUsed) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('Visitor QR Pass', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(visitorName, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text('Purpose: $purpose', style: TextStyle(color: AppColors.textSecondary)),
            Text('Valid: ${formatDate(validDate)}', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(8)),
              child: QrImageView(
                data: 'myrwa://pass/$code/$visitorName',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 8),
            Text('Show this to the guard at the gate\nगार्ड को यह दिखाएं', textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            if (!isUsed)
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { showSnack(ctx, 'QR Pass shared via WhatsApp!'); Navigator.pop(ctx); },
                  icon: const Icon(Icons.share), label: const Text('Share / शेयर'),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(
                  onPressed: () async {
                    await FirestoreService.updateDoc('qr_passes', docId, {'isUsed': true});
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    showSnack(ctx, 'Pass marked as used ✓');
                  },
                  icon: const Icon(Icons.check), label: const Text('Mark Used'),
                )),
              ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createPass() {
    final nameCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Visitor Pass / पास बनाएं', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Visitor Name / मेहमान का नाम', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose / कारण', prefixIcon: Icon(Icons.info_outline))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) {
                    showSnack(context, 'Please enter visitor name', isError: true);
                    return;
                  }
                  final code = (100000 + Random().nextInt(900000)).toString();
                  await FirestoreService.addDoc('qr_passes', {
                    'visitorName': nameCtrl.text,
                    'purpose': purposeCtrl.text.isEmpty ? 'Visit' : purposeCtrl.text,
                    'validDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
                    'code': code,
                    'isUsed': false,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  showSnack(ctx, 'QR Pass created! Code: $code');
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Generate QR Pass', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

