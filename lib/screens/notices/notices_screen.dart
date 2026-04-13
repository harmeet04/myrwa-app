import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/filter_chip_bar.dart';
import '../../widgets/warm_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/error_retry.dart';
import '../../services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  int _filterIndex = 0;
  final _categories = ['All', 'Announcement', 'AGM Minutes', 'Rules', 'Financial'];

  String get _filter => _categories[_filterIndex];

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

  // Returns pastel bg + border colors per category
  (Color bg, Color border) _categoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'announcement':
        return (AppColors.amberBg, AppColors.amberBorder);
      case 'agm minutes':
        return (AppColors.blueBg, AppColors.blueBorder);
      case 'rules':
        return (AppColors.purpleBg, AppColors.purpleBorder);
      case 'financial' || 'financial report':
        return (AppColors.greenBg, AppColors.greenBorder);
      default:
        return (AppColors.amberBg, AppColors.amberBorder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldLight,
        title: const Text('Notice Board'),
        elevation: 0,
      ),
      floatingActionButton: PrefsService.isAdmin
          ? _buildFab()
          : null,
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          FilterChipBar(
            options: _categories,
            selectedIndex: _filterIndex,
            onSelected: (i) => setState(() => _filterIndex = i),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.noticesStream(society),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorRetry(
                    message: 'Failed to load data',
                    onRetry: () => setState(() {}),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoader(itemCount: 4);
                }
                List<Notice> allNotices;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  allNotices = snapshot.data!.docs
                      .map((d) => FirestoreService.noticeFromDoc(d))
                      .toList();
                } else {
                  allNotices = MockData.notices;
                }
                final filtered = _applyFilter(allNotices);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    emoji: '📭',
                    title: 'No notices yet',
                    subtitle: 'Check back later for community announcements.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _NoticeCard(
                    notice: filtered[i],
                    isNew: _isNew(filtered[i]),
                    categoryColors: _categoryColors(filtered[i].category),
                    onTap: () => _showDetail(context, filtered[i]),
                    onCommentTap: () => _showComments(context, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        boxShadow: AppColors.fabShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          onTap: () => _showAddNotice(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('➕', style: TextStyle(fontSize: 16)),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Add Notice',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Notice n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoticeDetailSheet(
        notice: n,
        onCommentTap: () => _showComments(context, n),
      ),
    );
  }

  void _showComments(BuildContext context, Notice n) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusModal)),
          ),
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Comments (${n.comments.length})',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (n.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: n.comments.length,
                    itemBuilder: (_, i) {
                      final c = n.comments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.amberBg,
                              child: Text(
                                c.author[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryAmber,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.author,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeAgo(c.date),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.text,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (commentCtrl.text.trim().isEmpty) return;
                      final comment = Comment(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        author: PrefsService.userName.isEmpty
                            ? 'You'
                            : PrefsService.userName,
                        text: commentCtrl.text.trim(),
                        date: DateTime.now(),
                      );
                      setBS(() {
                        n.comments.add(comment);
                      });
                      if (n.id.isNotEmpty) {
                        FirestoreService.updateDoc('notices', n.id, {
                          'comments': FieldValue.arrayUnion([{
                            'id': comment.id,
                            'author': comment.author,
                            'text': comment.text,
                            'date': Timestamp.fromDate(comment.date),
                          }]),
                        });
                      }
                      commentCtrl.clear();
                    },
                    icon: const Icon(Icons.send, color: AppColors.primaryAmber),
                  ),
                ],
              ),
            ],
          ),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusModal)),
          ),
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Post Notice',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: AppSpacing.md),
                TextField(
                    controller: bodyCtrl,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isPolishing
                            ? null
                            : () async {
                                if (bodyCtrl.text.trim().isEmpty) return;
                                setBS(() => isPolishing = true);
                                try {
                                  final polished =
                                      await AiService.polishAnnouncement(
                                          bodyCtrl.text);
                                  setBS(() {
                                    bodyCtrl.text = polished;
                                    isPolishing = false;
                                  });
                                } catch (_) {
                                  setBS(() => isPolishing = false);
                                }
                              },
                        icon: isPolishing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryAmber))
                            : const Text('✨',
                                style: TextStyle(fontSize: 14)),
                        label: Text(
                            isPolishing ? 'Polishing...' : 'AI Polish',
                            style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primaryAmber,
                          side: const BorderSide(
                              color: AppColors.amberBorder),
                          backgroundColor: AppColors.amberBg,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isTranslating
                            ? null
                            : () async {
                                if (bodyCtrl.text.trim().isEmpty) return;
                                setBS(() => isTranslating = true);
                                try {
                                  final hindi =
                                      await AiService.translateToHindi(
                                          bodyCtrl.text);
                                  setBS(() {
                                    hindiText = hindi;
                                    isTranslating = false;
                                  });
                                } catch (_) {
                                  setBS(() => isTranslating = false);
                                }
                              },
                        icon: isTranslating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryAmber))
                            : const Text('🇮🇳',
                                style: TextStyle(fontSize: 14)),
                        label: Text(
                            isTranslating ? 'Translating...' : 'Hindi',
                            style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primaryAmber,
                          side: const BorderSide(
                              color: AppColors.amberBorder),
                          backgroundColor: AppColors.amberBg,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hindiText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.amberBg,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                      border:
                          Border.all(color: AppColors.amberBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'हिंदी अनुवाद',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textOnPrimary),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => setBS(() => hindiText = null),
                              child: const Icon(Icons.close,
                                  size: 16,
                                  color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(hindiText!,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setBS(() => category = v!),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => setBS(() => attachmentName =
                      attachmentName == null
                          ? 'Document_${DateTime.now().millisecondsSinceEpoch}.pdf'
                          : null),
                  icon: Icon(attachmentName != null
                      ? Icons.check_circle
                      : Icons.attach_file),
                  label: Text(attachmentName ?? 'Attach Document'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: attachmentName != null
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary,
                  ),
                ),
                if (PrefsService.isAdmin)
                  CheckboxListTile(
                    title: const Text('Pin this notice'),
                    value: pin,
                    onChanged: (v) => setBS(() => pin = v!),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primaryAmber,
                  ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusButton),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusButton),
                      onTap: () async {
                        if (titleCtrl.text.isNotEmpty &&
                            bodyCtrl.text.isNotEmpty) {
                          final fullBody = hindiText != null
                              ? '${bodyCtrl.text}\n\n---\n\n$hindiText'
                              : bodyCtrl.text;
                          await FirestoreService.addNotice(Notice(
                            id: '',
                            title: titleCtrl.text,
                            body: fullBody,
                            author: PrefsService.userName.isEmpty
                                ? 'You'
                                : PrefsService.userName,
                            authorFlat: PrefsService.userFlat.isEmpty
                                ? 'A-101'
                                : PrefsService.userFlat,
                            date: DateTime.now(),
                            category: category,
                            isPinned: pin,
                            attachmentName: attachmentName,
                          ));
                          AnalyticsService.logNoticeCreated();
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          showSnack(context, '✅ Notice posted!');
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'Post',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notice Card ────────────────────────────────────────────────────────────────

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final bool isNew;
  final (Color bg, Color border) categoryColors;
  final VoidCallback onTap;
  final VoidCallback onCommentTap;

  const _NoticeCard({
    required this.notice,
    required this.isNew,
    required this.categoryColors,
    required this.onTap,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    final (catBg, catBorder) = categoryColors;
    return WarmCard(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: pin + category chip + spacer + time/NEW badge
              Row(
                children: [
                  if (notice.isPinned) ...[
                    const Text('📌', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catBg,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusChip),
                      border: Border.all(color: catBorder, width: 0.5),
                    ),
                    child: Text(
                      notice.category,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary),
                    ),
                  ),
                  const Spacer(),
                  if (isNew) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amberBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.amberBorder, width: 0.5),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnPrimary),
                      ),
                    ),
                  ],
                  Text(
                    timeAgo(notice.date),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Title
              Text(
                notice.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Body preview
              Text(
                notice.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Bottom row: comments
              Row(
                children: [
                  GestureDetector(
                    onTap: onCommentTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.amberBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amberBorder),
                      ),
                      child: Row(
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            notice.comments.isEmpty ? 'Comment' : '${notice.comments.length} comments',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (PrefsService.isAdmin)
                    InkWell(
                      onTap: () => FirestoreService.updateNotice(
                          notice.id, {'isPinned': !notice.isPinned}),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          notice.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 15,
                          color: notice.isPinned
                              ? AppColors.primaryAmber
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: () {
                      final text = '${notice.title}\n\n${notice.body}\n\n— via myRWA';
                      final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.share,
                          size: 15, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Detail Sheet ───────────────────────────────────────────────────────────────

class _NoticeDetailSheet extends StatelessWidget {
  final Notice notice;
  final VoidCallback? onCommentTap;
  const _NoticeDetailSheet({required this.notice, this.onCommentTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusModal)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Expanded(
                child: Text(
                  notice.title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
              if (notice.isPinned)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child:
                      Text('📌', style: TextStyle(fontSize: 18)),
                ),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusChip),
                border: Border.all(color: AppColors.amberBorder, width: 0.5),
              ),
              child: Text(
                notice.category,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${notice.author} • ${notice.authorFlat}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                formatDate(notice.date),
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Text(
              notice.body,
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textPrimary),
            ),
            if (notice.attachmentName != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldLight,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                      color: AppColors.cardBorder, width: 0.5),
                ),
                child: Row(children: [
                  const Icon(Icons.description,
                      color: AppColors.primaryAmber),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      notice.attachmentName!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        showSnack(context, 'Download: ${notice.attachmentName}'),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primaryAmber,
                      side: const BorderSide(color: AppColors.amberBorder),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onCommentTap?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amberBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.amberBorder),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        notice.comments.isEmpty ? 'Write a comment' : '${notice.comments.length} comments',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share,
                    color: AppColors.textSecondary),
                onPressed: () {
                  final text = '${notice.title}\n\n${notice.body}\n\n— via myRWA';
                  final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                  launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
