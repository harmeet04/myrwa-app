import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String _filter = 'All';
  final _categories = ['All', 'Announcement', 'AGM Minutes', 'Rules', 'Financial Report'];

  List<Notice> _applyFilter(List<Notice> notices) {
    var list = _filter == 'All' ? notices : notices.where((n) => n.category == _filter).toList();
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  bool _isNew(Notice n) => DateTime.now().difference(n.date).inDays < 3;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(title: const Text('Notice Board')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNotice(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_categories[i]),
                  selected: _filter == _categories[i],
                  onSelected: (_) => setState(() => _filter = _categories[i]),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.noticesStream(society),
              builder: (context, snapshot) {
                List<Notice> allNotices;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  allNotices = snapshot.data!.docs.map((d) => FirestoreService.noticeFromDoc(d)).toList();
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  // Fallback to mock data if Firestore is empty
                  allNotices = MockData.notices;
                }
                final filtered = _applyFilter(allNotices);
                if (filtered.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.campaign_outlined, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No notices yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                  ]));
                }
                return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final n = filtered[i];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showDetail(context, n),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    if (n.isPinned) Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Icon(Icons.push_pin, size: 16, color: cs.primary),
                                    ),
                                    Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    if (_isNew(n)) Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                                      child: Text(n.category, style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600)),
                                  if (n.attachmentName != null) ...[
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Icon(Icons.attach_file, size: 14, color: cs.primary),
                                      const SizedBox(width: 4),
                                      Text(n.attachmentName!, style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w500)),
                                    ]),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    CircleAvatar(radius: 12, backgroundColor: cs.primaryContainer,
                                      child: Text(n.author[0], style: TextStyle(fontSize: 12, color: cs.primary))),
                                    const SizedBox(width: 8),
                                    Text('${n.author} • ${n.authorFlat}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    // Share button
                                    InkWell(
                                      onTap: () => showSnack(context, 'Shared: ${n.title}'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.share, size: 16, color: Colors.grey.shade500),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (PrefsService.isAdmin) InkWell(
                                      onTap: () {
                                        FirestoreService.updateNotice(n.id, {'isPinned': !n.isPinned});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Icon(n.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 16,
                                          color: n.isPinned ? cs.primary : Colors.grey),
                                      ),
                                    ),
                                    Text(timeAgo(n.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () {
                                        FirestoreService.updateNotice(n.id, {'likes': n.likes + 1});
                                      },
                                      child: Row(children: [
                                        Icon(Icons.favorite_border, size: 16, color: Colors.red.shade300),
                                        const SizedBox(width: 4),
                                        Text('${n.likes}', style: const TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Notice n) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(n.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              if (n.isPinned) Icon(Icons.push_pin, color: cs.primary, size: 20),
            ]),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(n.category, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.person, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('${n.author} • ${n.authorFlat}', style: TextStyle(color: Colors.grey.shade600)),
              const Spacer(),
              Text(formatDate(n.date), style: TextStyle(color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 16),
            Text(n.body, style: const TextStyle(fontSize: 15, height: 1.5)),
            if (n.attachmentName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(children: [
                  Icon(Icons.description, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(n.attachmentName!, style: const TextStyle(fontWeight: FontWeight.w500))),
                  OutlinedButton.icon(
                    onPressed: () => showSnack(context, 'Download: ${n.attachmentName}'),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Icon(Icons.favorite, color: Colors.red.shade300),
              const SizedBox(width: 4),
              Text('${n.likes} likes'),
              const SizedBox(width: 16),
              Icon(Icons.comment, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${n.comments.length} comments'),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.share, color: Colors.grey.shade600),
                onPressed: () => showSnack(context, 'Shared: ${n.title}'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showAddNotice(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = 'Announcement';
    bool pin = false;
    String? attachmentName;
    bool isPolishing = false;
    bool isTranslating = false;
    String? hindiText;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Post Notice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: bodyCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                // AI Polish + Hindi Translation row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isPolishing ? null : () async {
                          if (bodyCtrl.text.trim().isEmpty) return;
                          setBS(() => isPolishing = true);
                          try {
                            final polished = await AiService.polishAnnouncement(bodyCtrl.text);
                            setBS(() { bodyCtrl.text = polished; isPolishing = false; });
                          } catch (_) {
                            setBS(() => isPolishing = false);
                          }
                        },
                        icon: isPolishing
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('✨', style: TextStyle(fontSize: 14)),
                        label: Text(isPolishing ? 'Polishing...' : 'AI Polish', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isTranslating ? null : () async {
                          if (bodyCtrl.text.trim().isEmpty) return;
                          setBS(() => isTranslating = true);
                          try {
                            final hindi = await AiService.translateToHindi(bodyCtrl.text);
                            setBS(() { hindiText = hindi; isTranslating = false; });
                          } catch (_) {
                            setBS(() => isTranslating = false);
                          }
                        },
                        icon: isTranslating
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('🇮🇳', style: TextStyle(fontSize: 14)),
                        label: Text(isTranslating ? 'Translating...' : 'Hindi', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                  ],
                ),
                if (hindiText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('हिंदी अनुवाद', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade800)),
                            const Spacer(),
                            InkWell(
                              onTap: () => setBS(() => hindiText = null),
                              child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(hindiText!, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setBS(() => category = v!),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setBS(() => attachmentName = attachmentName == null ? 'Document_${DateTime.now().millisecondsSinceEpoch}.pdf' : null),
                  icon: Icon(attachmentName != null ? Icons.check_circle : Icons.attach_file),
                  label: Text(attachmentName ?? 'Attach Document'),
                  style: OutlinedButton.styleFrom(foregroundColor: attachmentName != null ? Colors.green : null),
                ),
                if (PrefsService.isAdmin) CheckboxListTile(
                  title: const Text('Pin this notice'),
                  value: pin,
                  onChanged: (v) => setBS(() => pin = v!),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty && bodyCtrl.text.isNotEmpty) {
                      final fullBody = hindiText != null
                          ? '${bodyCtrl.text}\n\n---\n\n$hindiText'
                          : bodyCtrl.text;
                      await FirestoreService.addNotice(Notice(
                        id: '',
                        title: titleCtrl.text, body: fullBody,
                        author: PrefsService.userName.isEmpty ? 'You' : PrefsService.userName,
                        authorFlat: PrefsService.userFlat.isEmpty ? 'A-101' : PrefsService.userFlat,
                        date: DateTime.now(), category: category, isPinned: pin, attachmentName: attachmentName,
                      ));
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      showSnack(context, '✅ Notice posted!');
                    }
                  },
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
