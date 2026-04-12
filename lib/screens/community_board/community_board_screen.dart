import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../widgets/warm_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loader.dart';

class CommunityBoardScreen extends StatefulWidget {
  const CommunityBoardScreen({super.key});

  @override
  State<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends State<CommunityBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Community Board'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '🎸 Skills'),
            Tab(text: '🔧 Lending'),
            Tab(text: '🚗 Carpooling'),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.fabShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddPost(context),
          icon: const Icon(Icons.add),
          label: const Text('Post'),
          backgroundColor: AppColors.primaryAmber,
          foregroundColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BoardTab(type: 'skill'),
          _BoardTab(type: 'lending'),
          _BoardTab(type: 'carpool'),
        ],
      ),
    );
  }

  void _showAddPost(BuildContext context) {
    String selectedType = 'skill';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.scaffoldLight,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('New Post',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                // Type selector
                const Text('Category',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _TypeChip(
                      label: '🎸 Skills',
                      value: 'skill',
                      selectedValue: selectedType,
                      onTap: () => setBS(() => selectedType = 'skill'),
                    ),
                    _TypeChip(
                      label: '🔧 Lending',
                      value: 'lending',
                      selectedValue: selectedType,
                      onTap: () => setBS(() => selectedType = 'lending'),
                    ),
                    _TypeChip(
                      label: '🚗 Carpooling',
                      value: 'carpool',
                      selectedValue: selectedType,
                      onTap: () => setBS(() => selectedType = 'carpool'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    if (title.isEmpty || desc.isEmpty) {
                      showSnack(ctx, 'Please fill in title and description',
                          isError: true);
                      return;
                    }
                    await FirestoreService.addBoardPost({
                      'type': selectedType,
                      'title': title,
                      'description': desc,
                      'contactMethod': 'in-app',
                    });
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    showSnack(context, 'Post added successfully!');
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryAmber),
                  child: const Text('Post to Board'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAmber : AppColors.amberBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryAmber : AppColors.amberBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BoardTab extends StatelessWidget {
  final String type;

  const _BoardTab({required this.type});

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.communityBoardStream(society, type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text('Failed to load posts',
                  style: TextStyle(color: AppColors.textSecondary)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoader();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          final emptyMessages = {
            'skill': ('🎸', 'No skills yet', 'Share your talents with the community!'),
            'lending': ('🔧', 'Nothing to lend yet', 'Help a neighbor — share your tools!'),
            'carpool': ('🚗', 'No carpool posts', 'Share a ride, save fuel!'),
          };
          final msg = emptyMessages[type]!;
          return EmptyState(emoji: msg.$1, title: msg.$2, subtitle: msg.$3);
        }

        return RefreshIndicator(
          color: AppColors.primaryAmber,
          onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _BoardPostCard(data: data, type: type, docId: docs[i].id);
            },
          ),
        );
      },
    );
  }
}

class _BoardPostCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String type;
  final String docId;

  const _BoardPostCard({required this.data, required this.type, required this.docId});

  @override
  State<_BoardPostCard> createState() => _BoardPostCardState();
}

class _BoardPostCardState extends State<_BoardPostCard> {
  Map<String, dynamic> get data => widget.data;
  String get type => widget.type;

  static String _typeEmoji(String t) {
    switch (t) {
      case 'skill':
        return '🎸';
      case 'lending':
        return '🔧';
      case 'carpool':
        return '🚗';
      default:
        return '📋';
    }
  }

  static Color _typeBg(String t) {
    switch (t) {
      case 'skill':
        return AppColors.purpleBg;
      case 'lending':
        return AppColors.amberBg;
      case 'carpool':
        return AppColors.greenBg;
      default:
        return AppColors.blueBg;
    }
  }

  static Color _typeBorder(String t) {
    switch (t) {
      case 'skill':
        return AppColors.purpleBorder;
      case 'lending':
        return AppColors.amberBorder;
      case 'carpool':
        return AppColors.greenBorder;
      default:
        return AppColors.blueBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final author = data['author'] as String? ?? 'Unknown';
    final flat = data['flat'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final timeStr = createdAt != null ? timeAgo(createdAt) : 'Just now';
    final t = data['type'] as String? ?? type;

    return WarmCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: emoji + title + timeAgo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeBg(t),
                  border: Border.all(color: _typeBorder(t)),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
                ),
                child: Center(
                  child: Text(_typeEmoji(t),
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                timeStr,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
          // Description
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          // Row 3: author + flat + interested button
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                author,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (flat.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '• Flat $flat',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
              const Spacer(),
              _buildInterestedButton(context, author),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestedButton(BuildContext context, String author) {
    final currentUser = PrefsService.userName;
    final interested = List<String>.from(data['interested'] ?? []);
    final isOwnPost = author == currentUser;
    final alreadyInterested = interested.contains(currentUser);

    if (isOwnPost) {
      if (interested.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.amberBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.amberBorder),
        ),
        child: Text(
          '${interested.length} interested',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryAmber),
        ),
      );
    }

    if (alreadyInterested) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.amberBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.amberBorder),
        ),
        child: Text(
          '${interested.length} interested',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryAmber),
        ),
      );
    }

    return InkWell(
      onTap: () async {
        await FirestoreService.updateDoc('community_board', widget.docId, {
          'interested': FieldValue.arrayUnion([currentUser]),
        });
        if (!context.mounted) return;
        showSnack(context, 'You expressed interest!');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.greenBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greenBorder),
        ),
        child: const Text(
          'Interested',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
        ),
      ),
    );
  }
}
