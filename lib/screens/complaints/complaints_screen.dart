import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../chat/chat_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Complaint> _byStatus(List<Complaint> all, ComplaintStatus s) => all.where((c) => c.status == s).toList();

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddComplaint(context),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.complaintsStream(society),
        builder: (context, snapshot) {
          List<Complaint> complaints;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            complaints = snapshot.data!.docs.map((d) => FirestoreService.complaintFromDoc(d)).toList();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            complaints = MockData.complaints;
          }
          final open = _byStatus(complaints, ComplaintStatus.open);
          final inProgress = _byStatus(complaints, ComplaintStatus.inProgress);
          final resolved = _byStatus(complaints, ComplaintStatus.resolved);
          return Column(
            children: [
              TabBar(
                controller: _tabCtrl,
                tabs: [
                  Tab(text: 'Open (${open.length})'),
                  Tab(text: 'In Progress (${inProgress.length})'),
                  Tab(text: 'Resolved (${resolved.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildList(open),
                    _buildList(inProgress),
                    _buildList(resolved),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Complaint> items) {
    if (items.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No complaints here', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('All good! 🎉', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: items.length,
        itemBuilder: (_, i) => _ComplaintCard(
          complaint: items[i],
          onTap: () => _showDetail(context, items[i]),
          isAdmin: PrefsService.isAdmin,
          onRespond: () => _showAdminRespond(context, items[i]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Complaint c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(c.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              _StatusChip(status: c.status),
            ]),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.category, text: c.category),
            _InfoRow(icon: Icons.flag, text: 'Priority: ${c.priority.name.toUpperCase()}', color: priorityColor(c.priority.name)),
            _InfoRow(icon: Icons.person, text: '${c.raisedBy} • ${c.flat}'),
            _InfoRow(icon: Icons.calendar_today, text: formatDate(c.date)),
            const SizedBox(height: 12),
            Text(c.description, style: const TextStyle(height: 1.5)),
            if (c.hasPhoto) ...[
              const SizedBox(height: 12),
              Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text('Photo Attached', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (c.adminResponse != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text('Admin Response', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    ]),
                    const SizedBox(height: 6),
                    Text(c.adminResponse!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(otherName: 'Rajesh Sharma (Admin)', otherFlat: 'A-101', otherId: 'r_0'),
                  ));
                },
                icon: const Icon(Icons.chat),
                label: const Text('Discuss with Admin'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAdminRespond(BuildContext context, Complaint c) {
    final respCtrl = TextEditingController(text: c.adminResponse ?? '');
    ComplaintStatus newStatus = c.status;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Respond: ${c.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: respCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Admin Response')),
              const SizedBox(height: 12),
              DropdownButtonFormField<ComplaintStatus>(
                value: newStatus,
                decoration: const InputDecoration(labelText: 'Update Status'),
                items: ComplaintStatus.values.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s == ComplaintStatus.open ? 'Open' : s == ComplaintStatus.inProgress ? 'In Progress' : 'Resolved'),
                )).toList(),
                onChanged: (v) => setBS(() => newStatus = v!),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await FirestoreService.updateComplaint(c.id, {
                    'adminResponse': respCtrl.text,
                    'status': newStatus.name,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  showSnack(context, 'Response saved!');
                },
                child: const Text('Save Response'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddComplaint(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Plumbing';
    Priority priority = Priority.medium;
    bool addPhoto = false;
    bool isAiProcessing = false;
    bool aiApplied = false;
    String? aiRouteTo;
    // Voice
    final speech = stt.SpeechToText();
    bool isListening = false;
    String voiceTarget = ''; // 'title' or 'description'

    final categories = ['Plumbing', 'Electrical', 'Security', 'Parking', 'Noise', 'Cleanliness', 'Elevator', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) {

          Future<void> runAiCategorization() async {
            if (descCtrl.text.trim().isEmpty && titleCtrl.text.trim().isEmpty) return;
            setBS(() => isAiProcessing = true);
            try {
              final result = await AiService.categorizeComplaint(titleCtrl.text, descCtrl.text);
              final aiCat = result['category'] ?? 'Other';
              final aiPri = result['priority'] ?? 'medium';
              setBS(() {
                if (categories.contains(aiCat)) category = aiCat;
                priority = Priority.values.firstWhere((p) => p.name == aiPri, orElse: () => Priority.medium);
                aiRouteTo = result['routeTo'];
                aiApplied = true;
                isAiProcessing = false;
              });
            } catch (_) {
              setBS(() => isAiProcessing = false);
            }
          }

          Future<void> toggleListening(String target) async {
            if (isListening) {
              await speech.stop();
              setBS(() => isListening = false);
              return;
            }
            final available = await speech.initialize();
            if (!available) {
              if (context.mounted) showSnack(context, 'Speech recognition not available', isError: true);
              return;
            }
            setBS(() { isListening = true; voiceTarget = target; });
            await speech.listen(
              onResult: (result) {
                setBS(() {
                  if (voiceTarget == 'title') {
                    titleCtrl.text = result.recognizedWords;
                  } else {
                    descCtrl.text = result.recognizedWords;
                  }
                });
                if (result.finalResult) {
                  setBS(() => isListening = false);
                }
              },
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 3),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Raise Complaint', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Title with mic
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isListening && voiceTarget == 'title' ? Icons.mic : Icons.mic_none,
                          color: isListening && voiceTarget == 'title' ? Colors.red : null,
                        ),
                        onPressed: () => toggleListening('title'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description with mic
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isListening && voiceTarget == 'description' ? Icons.mic : Icons.mic_none,
                          color: isListening && voiceTarget == 'description' ? Colors.red : null,
                        ),
                        onPressed: () => toggleListening('description'),
                      ),
                    ),
                  ),
                  if (isListening) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 8),
                        Text('Listening... (${voiceTarget})', style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // AI Categorize button
                  OutlinedButton.icon(
                    onPressed: isAiProcessing ? null : runAiCategorization,
                    icon: isAiProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('✨', style: TextStyle(fontSize: 16)),
                    label: Text(isAiProcessing ? 'AI Analyzing...' : aiApplied ? 'AI Applied ✓' : '✨ AI Auto-Categorize'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: aiApplied ? Colors.green : null,
                      side: aiApplied ? const BorderSide(color: Colors.green) : null,
                    ),
                  ),
                  if (aiApplied && aiRouteTo != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.route, size: 16, color: Colors.purple.shade600),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Auto-routed to: $aiRouteTo', style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categories.contains(category) ? category : 'Other',
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setBS(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Priority>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: Priority.values.map((p) => DropdownMenuItem(value: p,
                      child: Row(children: [
                        Icon(Icons.circle, size: 12, color: priorityColor(p.name)),
                        const SizedBox(width: 8),
                        Text(p.name.toUpperCase(), style: TextStyle(color: priorityColor(p.name), fontWeight: FontWeight.w600)),
                      ]))).toList(),
                    onChanged: (v) => setBS(() => priority = v!),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setBS(() => addPhoto = !addPhoto),
                    icon: Icon(addPhoto ? Icons.check_circle : Icons.add_a_photo),
                    label: Text(addPhoto ? 'Photo Added ✓' : 'Attach Photo'),
                    style: OutlinedButton.styleFrom(foregroundColor: addPhoto ? Colors.green : null),
                  ),
                  if (addPhoto) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Icon(Icons.image, size: 32, color: Colors.grey.shade400)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (titleCtrl.text.isNotEmpty && descCtrl.text.isNotEmpty) {
                        final complaintData = {
                          'title': titleCtrl.text,
                          'description': descCtrl.text,
                          'category': category,
                          'status': ComplaintStatus.open.name,
                          'priority': priority.name,
                          'raisedBy': PrefsService.userName.isEmpty ? 'You' : PrefsService.userName,
                          'flat': PrefsService.userFlat.isEmpty ? 'A-101' : PrefsService.userFlat,
                          'date': Timestamp.fromDate(DateTime.now()),
                          'hasPhoto': addPhoto,
                          'society': PrefsService.societyName,
                          if (aiRouteTo != null) 'aiRouteTo': aiRouteTo,
                          'aiCategorized': aiApplied,
                        };
                        await FirestoreService.addComplaint(Complaint(
                          id: '',
                          title: titleCtrl.text, description: descCtrl.text,
                          category: category, status: ComplaintStatus.open, priority: priority,
                          raisedBy: PrefsService.userName.isEmpty ? 'You' : PrefsService.userName,
                          flat: PrefsService.userFlat.isEmpty ? 'A-101' : PrefsService.userFlat,
                          date: DateTime.now(), hasPhoto: addPhoto,
                        ));
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        showSnack(context, '✅ Complaint raised successfully!${aiApplied ? ' (AI categorized)' : ''}');
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;
  final bool isAdmin;
  final VoidCallback onRespond;
  const _ComplaintCard({required this.complaint, required this.onTap, required this.isAdmin, required this.onRespond});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final pColor = priorityColor(c.priority.name);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon(c.category), color: pColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      if (c.hasPhoto) Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.photo_camera, size: 16, color: Colors.grey.shade500),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('${c.raisedBy} • ${c.flat} • ${timeAgo(c.date)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                )),
              ]),
              const SizedBox(height: 10),
              Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: pColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (c.priority == Priority.high) _PulsingDot(color: pColor) else Icon(Icons.circle, size: 8, color: pColor),
                      const SizedBox(width: 4),
                      Text(c.priority.name.toUpperCase(), style: TextStyle(fontSize: 10, color: pColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: c.status),
                const Spacer(),
                if (isAdmin && c.status != ComplaintStatus.resolved)
                  InkWell(
                    onTap: onRespond,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text('Respond', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + _ctrl.value * 0.5),
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: _ctrl.value * 0.5), blurRadius: 4, spreadRadius: 1)],
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;
  const AnimatedBuilder({super.key, required Animation<double> animation, required this.builder, this.child})
      : super(listenable: animation);
  @override
  Widget build(BuildContext context) => builder(context, child);
}

class _StatusChip extends StatelessWidget {
  final ComplaintStatus status;
  const _StatusChip({required this.status});

  String get _label {
    switch (status) {
      case ComplaintStatus.open: return 'Open';
      case ComplaintStatus.inProgress: return 'In Progress';
      case ComplaintStatus.resolved: return 'Resolved';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(_label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(_label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color ?? Colors.grey.shade700)),
      ]),
    );
  }
}
