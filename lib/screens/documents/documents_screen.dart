import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _filter = 'All';

  static const _categories = ['All', 'Sale Deed', 'Rental Agreement', 'NOC', 'Society', 'Tax', 'Insurance'];

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(title: const Text('Property Documents / दस्तावेज')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadDoc,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload / अपलोड'),
      ),
      body: Column(
        children: [
          // Storage summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.folder, size: 40, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Documents / दस्तावेज', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Flat: ${PrefsService.userFlat} • Securely stored', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.lock, color: AppColors.statusSuccess),
              ],
            ),
          ),

          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                return FilterChip(
                  selected: cat == _filter,
                  label: Text(cat),
                  onSelected: (_) => setState(() => _filter = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.collectionStream('documents', society),
              builder: (context, snapshot) {
                List<_Document> docs;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  docs = snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _Document(
                      id: doc.id,
                      name: d['name'] ?? '',
                      category: d['category'] ?? 'Society',
                      size: d['size'] ?? '0 MB',
                      uploadDate: (d['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      flat: d['flat'] ?? '',
                      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate(),
                      notes: d['notes'],
                    );
                  }).toList();
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  docs = _MockDocs.docs;
                }

                final filtered = _filter == 'All' ? docs : docs.where((d) => d.category == _filter).toList();

                if (filtered.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.folder_open, size: 64, color: AppColors.cardBorder),
                    const SizedBox(height: 12),
                    Text('No documents in this category', style: TextStyle(color: AppColors.textTertiary)),
                  ]));
                }

                return RefreshIndicator(
                  color: AppColors.primaryAmber,
                  onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
                  child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final d = filtered[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: d.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(d.icon, color: d.color),
                        ),
                        title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${d.category} • ${d.size} • ${formatDate(d.uploadDate)}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'), dense: true)),
                            const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Share'), dense: true)),
                            const PopupMenuItem(value: 'download', child: ListTile(leading: Icon(Icons.download), title: Text('Download'), dense: true)),
                            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppColors.statusError), title: Text('Delete', style: TextStyle(color: AppColors.statusError)), dense: true)),
                          ],
                          onSelected: (v) {
                            switch (v) {
                              case 'view': _viewDoc(d); break;
                              case 'share': showSnack(context, '${d.name} shared!'); break;
                              case 'download': showSnack(context, '${d.name} downloaded!'); break;
                              case 'delete':
                                if (d.id != null) {
                                  FirestoreService.deleteDoc('documents', d.id!);
                                  showSnack(context, '${d.name} deleted');
                                }
                                break;
                            }
                          },
                        ),
                        onTap: () => _viewDoc(d),
                      ),
                    );
                  },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewDoc(_Document d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(d.icon, color: d.color, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ]),
            const Divider(height: 24),
            _detailRow('Category / श्रेणी', d.category),
            _detailRow('File Size', d.size),
            _detailRow('Uploaded / अपलोड', formatDate(d.uploadDate)),
            _detailRow('Flat / फ्लैट', d.flat),
            if (d.expiryDate != null) _detailRow('Expiry / समाप्ति', formatDate(d.expiryDate!)),
            if (d.notes != null) ...[
              const SizedBox(height: 8),
              Text('Notes / टिप्पणी', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(d.notes!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); showSnack(context, 'Shared!'); }, icon: const Icon(Icons.share), label: const Text('Share'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(onPressed: () { Navigator.pop(context); showSnack(context, 'Downloaded!'); }, icon: const Icon(Icons.download), label: const Text('Download'))),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  void _uploadDoc() {
    final nameCtrl = TextEditingController();
    String category = 'Sale Deed';

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
            Text('Upload Document / दस्तावेज अपलोड', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Document Name / नाम', prefixIcon: Icon(Icons.description))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category / श्रेणी', prefixIcon: Icon(Icons.category)),
              items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v ?? category,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 4),
                  Text('Tap to select file\nफ़ाइल चुनें', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) {
                    showSnack(context, 'Please enter document name', isError: true);
                    return;
                  }
                  await FirestoreService.addDoc('documents', {
                    'name': nameCtrl.text,
                    'category': category,
                    'size': '1.2 MB',
                    'uploadDate': Timestamp.fromDate(DateTime.now()),
                    'flat': PrefsService.userFlat,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  showSnack(ctx, '✅ ${nameCtrl.text} uploaded!');
                },
                icon: const Icon(Icons.upload),
                label: const Text('Upload Document', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Document {
  final String? id;
  final String name;
  final String category;
  final String size;
  final DateTime uploadDate;
  final String flat;
  final DateTime? expiryDate;
  final String? notes;

  const _Document({this.id, required this.name, required this.category, required this.size, required this.uploadDate, required this.flat, this.expiryDate, this.notes});

  IconData get icon {
    switch (category) {
      case 'Sale Deed': return Icons.gavel;
      case 'Rental Agreement': return Icons.handshake;
      case 'NOC': return Icons.verified;
      case 'Society': return Icons.apartment;
      case 'Tax': return Icons.receipt;
      case 'Insurance': return Icons.shield;
      default: return Icons.description;
    }
  }

  Color get color {
    switch (category) {
      case 'Sale Deed': return AppColors.primaryAmber;
      case 'Rental Agreement': return const Color(0xFF7C3AED);
      case 'NOC': return AppColors.statusSuccess;
      case 'Society': return AppColors.primaryOrange;
      case 'Tax': return AppColors.statusError;
      case 'Insurance': return AppColors.primaryAmber;
      default: return AppColors.textTertiary;
    }
  }
}

class _MockDocs {
  static List<_Document> get docs => [
    _Document(name: 'Sale Deed - A101', category: 'Sale Deed', size: '4.2 MB', uploadDate: DateTime(2025, 6, 15), flat: 'A-101', notes: 'Original sale deed from builder.'),
    _Document(name: 'Society Share Certificate', category: 'Society', size: '1.8 MB', uploadDate: DateTime(2025, 7, 1), flat: 'A-101'),
    _Document(name: 'Property Tax Receipt 2025', category: 'Tax', size: '0.5 MB', uploadDate: DateTime(2025, 4, 10), flat: 'A-101', expiryDate: DateTime(2026, 3, 31)),
    _Document(name: 'Home Insurance Policy', category: 'Insurance', size: '2.1 MB', uploadDate: DateTime(2025, 1, 20), flat: 'A-101', expiryDate: DateTime(2026, 1, 20)),
    _Document(name: 'NOC - Renovation', category: 'NOC', size: '0.8 MB', uploadDate: DateTime(2025, 9, 5), flat: 'A-101'),
  ];
}
