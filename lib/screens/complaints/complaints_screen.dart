import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/filter_chip_bar.dart';
import '../../widgets/warm_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/error_retry.dart';
import '../chat/chat_screen.dart';
import '../../services/analytics_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  int _filterIndex = 0;

  static const _filterOptions = ['All', '\u{1F534} Open', '\u{1F535} In Progress', '\u2705 Resolved'];

  List<Complaint> _filterList(List<Complaint> all) {
    switch (_filterIndex) {
      case 1:
        return all.where((c) => c.status == ComplaintStatus.open).toList();
      case 2:
        return all.where((c) => c.status == ComplaintStatus.inProgress).toList();
      case 3:
        return all.where((c) => c.status == ComplaintStatus.resolved).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Complaints'),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.fabShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddComplaint(context),
          icon: const Icon(Icons.add),
          label: const Text('New Complaint'),
          backgroundColor: AppColors.primaryAmber,
          foregroundColor: Colors.white,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.complaintsStream(society),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorRetry(
              message: 'Failed to load data',
              onRetry: () => setState(() {}),
            );
          }
          List<Complaint> complaints;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            complaints = snapshot.data!.docs.map((d) => FirestoreService.complaintFromDoc(d)).toList();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                FilterChipBar(
                  options: _filterOptions,
                  selectedIndex: _filterIndex,
                  onSelected: (i) => setState(() => _filterIndex = i),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Expanded(child: ShimmerLoader()),
              ],
            );
          } else {
            complaints = MockData.complaints;
          }

          final filtered = _filterList(complaints);

          return Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              FilterChipBar(
                options: _filterOptions,
                selectedIndex: _filterIndex,
                onSelected: (i) => setState(() => _filterIndex = i),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _buildList(filtered)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Complaint> items) {
    if (items.isEmpty) {
      if (_filterIndex == 0) {
        return const EmptyState(
          emoji: '\u{1F389}',
          title: 'No complaints \u2014 that\'s great!',
          subtitle: 'Your community is running smoothly.',
        );
      }
      final labels = ['', 'open', 'in progress', 'resolved'];
      return EmptyState(
        emoji: '\u2705',
        title: 'No ${labels[_filterIndex]} complaints',
        subtitle: 'Nothing here right now.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryAmber,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 80),
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
      backgroundColor: AppColors.scaffoldLight,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(c.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              StatusChip(label: _statusLabel(c.status)),
            ]),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.category, text: c.category),
            _InfoRow(icon: Icons.flag, text: 'Priority: ${c.priority.name.toUpperCase()}', color: AppColors.priorityColor(c.priority.name)),
            _InfoRow(icon: Icons.person, text: '${c.raisedBy} \u2022 ${c.flat}'),
            _InfoRow(icon: Icons.calendar_today, text: formatDate(c.date)),
            const SizedBox(height: 12),
            Text(c.description, style: const TextStyle(height: 1.5, color: AppColors.textSecondary)),
            if (c.hasPhoto) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                child: c.photoUrl != null
                    ? Image.network(
                        c.photoUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _photoPlaceholder(),
                      )
                    : _photoPlaceholder(),
              ),
            ],
            if (c.adminResponse != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.amberBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: AppColors.primaryOrange),
                      SizedBox(width: 6),
                      Text('Admin Response', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                    ]),
                    const SizedBox(height: 6),
                    Text(c.adminResponse!, style: const TextStyle(color: AppColors.textPrimary)),
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryAmber,
                  side: const BorderSide(color: AppColors.primaryAmber),
                ),
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
      backgroundColor: AppColors.scaffoldLight,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Respond: ${c.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              TextField(controller: respCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Admin Response')),
              const SizedBox(height: 12),
              DropdownButtonFormField<ComplaintStatus>(
                initialValue: newStatus,
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAmber),
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
    File? pickedImage;
    bool isAiProcessing = false;
    bool aiApplied = false;
    String? aiRouteTo;
    // Voice
    final speech = stt.SpeechToText();
    bool isListening = false;
    String voiceTarget = ''; // 'title' or 'description'
    // Noise-specific fields
    TimeOfDay? noiseTime;
    String noiseDuration = 'Less than 15 min';
    String noiseSource = 'Unknown';
    const noiseDurations = [
      'Less than 15 min',
      '15-30 min',
      '30-60 min',
      'More than 1 hour',
    ];
    const noiseSources = [
      'Above',
      'Below',
      'Left',
      'Right',
      'Outside',
      'Unknown',
    ];

    final categories = ['Plumbing', 'Electrical', 'Security', 'Parking', 'Noise/Nuisance', 'Cleanliness', 'Elevator', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.scaffoldLight,
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
                  const Text('Raise Complaint', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  // Title with mic
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      suffixIcon: IconButton(
                        icon: Icon(
                          isListening && voiceTarget == 'title' ? Icons.mic : Icons.mic_none,
                          color: isListening && voiceTarget == 'title' ? AppColors.statusError : null,
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
                          color: isListening && voiceTarget == 'description' ? AppColors.statusError : null,
                        ),
                        onPressed: () => toggleListening('description'),
                      ),
                    ),
                  ),
                  if (isListening) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAmber)),
                        const SizedBox(width: 8),
                        Text('Listening... ($voiceTarget)', style: const TextStyle(fontSize: 12, color: AppColors.statusError, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // AI Categorize button
                  OutlinedButton.icon(
                    onPressed: isAiProcessing ? null : runAiCategorization,
                    icon: isAiProcessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAmber))
                        : const Text('\u2728', style: TextStyle(fontSize: 16)),
                    label: Text(isAiProcessing ? 'AI Analyzing...' : aiApplied ? 'AI Applied \u2713' : '\u2728 AI Auto-Categorize'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: aiApplied ? AppColors.statusSuccess : AppColors.primaryAmber,
                      side: BorderSide(color: aiApplied ? AppColors.statusSuccess : AppColors.primaryAmber),
                    ),
                  ),
                  if (aiApplied && aiRouteTo != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.amberBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amberBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route, size: 16, color: AppColors.primaryOrange),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Auto-routed to: $aiRouteTo', style: const TextStyle(fontSize: 12, color: AppColors.primaryOrange, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(category) ? category : 'Other',
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setBS(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Priority>(
                    initialValue: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: Priority.values.map((p) => DropdownMenuItem(value: p,
                      child: Row(children: [
                        Icon(Icons.circle, size: 12, color: AppColors.priorityColor(p.name)),
                        const SizedBox(width: 8),
                        Text(p.name.toUpperCase(), style: TextStyle(color: AppColors.priorityColor(p.name), fontWeight: FontWeight.w600)),
                      ]))).toList(),
                    onChanged: (v) => setBS(() => priority = v!),
                  ),
                  // Noise-specific fields
                  if (category == 'Noise/Nuisance') ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.volume_up, size: 16, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      const Text('Noise Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED), fontSize: 13)),
                    ]),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setBS(() => noiseTime = picked);
                      },
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(noiseTime != null
                          ? 'Time: ${noiseTime!.format(ctx)}'
                          : 'Set Time of Occurrence'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryAmber,
                        side: const BorderSide(color: AppColors.primaryAmber),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: noiseDuration,
                      decoration: const InputDecoration(labelText: 'Duration'),
                      items: noiseDurations
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setBS(() => noiseDuration = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: noiseSource,
                      decoration: const InputDecoration(labelText: 'Source Direction'),
                      items: noiseSources
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setBS(() => noiseSource = v!),
                    ),
                    const SizedBox(height: 4),
                    const Divider(),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final file = await StorageService.showImagePicker(ctx);
                      if (file != null) setBS(() => pickedImage = file);
                    },
                    icon: Icon(pickedImage != null ? Icons.check_circle : Icons.camera_alt),
                    label: Text(pickedImage != null ? 'Photo attached' : 'Attach Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pickedImage != null ? AppColors.statusSuccess : AppColors.primaryAmber,
                      side: BorderSide(color: pickedImage != null ? AppColors.statusSuccess : AppColors.primaryAmber),
                    ),
                  ),
                  if (pickedImage != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      child: Image.file(
                        pickedImage!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (titleCtrl.text.isNotEmpty && descCtrl.text.isNotEmpty) {
                        HapticFeedback.mediumImpact();
                        String? photoUrl;
                        if (pickedImage != null) {
                          photoUrl = await StorageService.uploadImage(
                            pickedImage!,
                            'complaints/${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );
                        }
                        final Map<String, dynamic>? noiseExtra =
                            category == 'Noise/Nuisance'
                                ? {
                                    'noiseTime': noiseTime != null
                                        ? '${noiseTime!.hour}:${noiseTime!.minute.toString().padLeft(2, '0')}'
                                        : null,
                                    'noiseDuration': noiseDuration,
                                    'noiseSource': noiseSource,
                                  }
                                : null;
                        await FirestoreService.addComplaint(
                          Complaint(
                            id: '',
                            title: titleCtrl.text, description: descCtrl.text,
                            category: category, status: ComplaintStatus.open, priority: priority,
                            raisedBy: PrefsService.userName.isEmpty ? 'You' : PrefsService.userName,
                            flat: PrefsService.userFlat.isEmpty ? 'A-101' : PrefsService.userFlat,
                            date: DateTime.now(), hasPhoto: pickedImage != null,
                            photoUrl: photoUrl,
                          ),
                          extraFields: noiseExtra,
                        );
                        AnalyticsService.logComplaintCreated(category);
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        showSnack(context, '\u2705 Complaint raised successfully!${aiApplied ? ' (AI categorized)' : ''}');
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAmber),
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

  static Widget _photoPlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 40, color: AppColors.textTertiary),
          SizedBox(height: 4),
          Text('Photo Attached', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  static String _statusLabel(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.open:
        return 'Open';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
    }
  }
}

/// Returns a pastel background color for a complaint category.
Color _categoryBgColor(String category) {
  switch (category.toLowerCase()) {
    case 'plumbing' || 'water':
      return AppColors.blueBg;
    case 'electrical' || 'electricity':
      return AppColors.amberBg;
    case 'security':
      return AppColors.redBg;
    case 'cleaning' || 'cleanliness' || 'housekeeping':
      return AppColors.greenBg;
    case 'noise':
      return AppColors.purpleBg;
    case 'parking':
      return AppColors.blueBg;
    case 'lift' || 'elevator':
      return AppColors.pinkBg;
    default:
      return AppColors.amberBg;
  }
}

/// Returns a foreground icon color for a complaint category.
Color _categoryFgColor(String category) {
  switch (category.toLowerCase()) {
    case 'plumbing' || 'water':
      return const Color(0xFF2563EB);
    case 'electrical' || 'electricity':
      return AppColors.primaryAmber;
    case 'security':
      return AppColors.statusError;
    case 'cleaning' || 'cleanliness' || 'housekeeping':
      return AppColors.statusSuccess;
    case 'noise':
      return const Color(0xFF7C3AED);
    case 'parking':
      return const Color(0xFF2563EB);
    case 'lift' || 'elevator':
      return const Color(0xFFDB2777);
    default:
      return AppColors.primaryOrange;
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
    return WarmCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon + title/subtitle + priority badge
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _categoryBgColor(c.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(categoryIcon(c.category), size: 16, color: _categoryFgColor(c.category)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Flat ${c.flat} \u2022 ${timeAgo(c.date)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              )),
              const SizedBox(width: AppSpacing.sm),
              PriorityBadge(priority: c.priority.name),
            ],
          ),
          // Row 2: Description preview
          if (c.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          // Row 3: Status chip + reply indicator + admin respond
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusChip(label: _ComplaintsScreenState._statusLabel(c.status)),
              const Spacer(),
              if (c.adminResponse != null)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\u{1F4AC}', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 2),
                    Text('1', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              if (isAdmin && c.status != ComplaintStatus.resolved) ...[
                const SizedBox(width: AppSpacing.sm),
                InkWell(
                  onTap: onRespond,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.amberBorder),
                    ),
                    child: const Text('Respond', style: TextStyle(fontSize: 11, color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color ?? AppColors.textSecondary)),
      ]),
    );
  }
}
