import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/prefs_service.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../widgets/action_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/warm_card.dart';
import '../visitors/visitors_screen.dart';
import '../packages/packages_screen.dart';
import '../notices/notices_screen.dart';
import '../bills/bills_screen.dart';
import '../facility/facility_screen.dart';
import '../polls/polls_screen.dart';
import '../gate_log/gate_log_screen.dart';
import '../qr_pass/qr_pass_screen.dart';
import '../sos/sos_screen.dart';
import 'community_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final userName = PrefsService.userName.isEmpty
        ? 'Resident'
        : PrefsService.userName.split(' ')[0];
    final societyName = PrefsService.societyName.isEmpty
        ? 'myRWA'
        : PrefsService.societyName;
    final userFlat = PrefsService.userFlat;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _push(context, const SosScreen()),
        backgroundColor: AppColors.statusError,
        child: const Icon(Icons.sos, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Greeting Bar
            SliverToBoxAdapter(
              child: _GreetingBar(
                greeting: _greeting(),
                userName: userName,
                societyName: societyName,
                flat: userFlat,
              ),
            ),

            // 2. Needs Your Attention
            SliverToBoxAdapter(
              child: _NeedsAttentionSection(
                onPush: (w) => _push(context, w),
              ),
            ),

            // 3. Quick Access
            SliverToBoxAdapter(
              child: _QuickAccessSection(
                onPush: (w) => _push(context, w),
              ),
            ),

            // 4. Community Feed
            SliverToBoxAdapter(
              child: _CommunityFeedSection(
                onPush: (w) => _push(context, w),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// ─── 1. Greeting Bar ───
class _GreetingBar extends StatelessWidget {
  final String greeting;
  final String userName;
  final String societyName;
  final String flat;

  const _GreetingBar({
    required this.greeting,
    required this.userName,
    required this.societyName,
    required this.flat,
  });

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '\u{1F3E0}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$societyName${flat.isNotEmpty ? ' \u2022 Flat $flat' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, size: 26),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Needs Your Attention ───
class _NeedsAttentionSection extends StatelessWidget {
  final void Function(Widget) onPush;

  const _NeedsAttentionSection({required this.onPush});

  @override
  Widget build(BuildContext context) {
    final pendingVisitors = MockData.visitors
        .where((v) => v.status == VisitorStatus.pending)
        .toList();
    final pendingBills = MockData.bills
        .where((b) =>
            b.status == BillStatus.pending || b.status == BillStatus.overdue)
        .toList();

    final hasPending = pendingVisitors.isNotEmpty || pendingBills.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '\u26A1', title: 'Needs Your Attention'),
        if (!hasPending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: WarmCard(
              child: Center(
                child: Text(
                  'All caught up! \u{1F389}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        if (hasPending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                ...pendingVisitors.map((v) => ActionTile(
                      emoji: '\u{1F6B6}',
                      bgColor: AppColors.amberBg,
                      borderColor: AppColors.amberBorder,
                      title: v.name,
                      subtitle: '${v.purpose} \u2022 ${timeAgo(v.date)}',
                      actions: [
                        ActionTileButton(
                          label: '\u2713',
                          color: AppColors.statusSuccess,
                          onTap: () => showSnack(context, '${v.name} approved'),
                        ),
                        ActionTileButton(
                          label: '\u2717',
                          color: AppColors.statusError,
                          onTap: () => showSnack(context, '${v.name} rejected'),
                        ),
                      ],
                    )),
                ...pendingBills.map((b) => ActionTile(
                      emoji: '\u{1F9FE}',
                      bgColor: AppColors.blueBg,
                      borderColor: AppColors.blueBorder,
                      title: '${b.category} bill',
                      subtitle:
                          '\u20B9${b.amount.toInt()} \u2022 Due ${formatDate(b.dueDate)}',
                      actions: [
                        ActionTileButton(
                          label: 'Pay',
                          color: AppColors.primaryAmber,
                          onTap: () => onPush(const BillsScreen()),
                        ),
                      ],
                    )),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── 3. Quick Access ───
class _QuickAccessSection extends StatelessWidget {
  final void Function(Widget) onPush;

  const _QuickAccessSection({required this.onPush});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _QuickTile('\u{1F6B6}', 'Visitors', AppColors.amberBg, AppColors.amberBorder, const VisitorsScreen()),
      _QuickTile('\u{1F4E6}', 'Packages', AppColors.greenBg, AppColors.greenBorder, const PackagesScreen()),
      _QuickTile('\u{1F4E2}', 'Notices', AppColors.blueBg, AppColors.blueBorder, const NoticesScreen()),
      _QuickTile('\u{1F9FE}', 'Bills', AppColors.pinkBg, AppColors.pinkBorder, const BillsScreen()),
      _QuickTile('\u{1F3CB}\uFE0F', 'Booking', AppColors.purpleBg, AppColors.purpleBorder, const FacilityScreen()),
      _QuickTile('\u{1F5F3}\uFE0F', 'Polls', AppColors.amberBg, AppColors.amberBorder, const PollsScreen()),
      _QuickTile('\u{1F6AA}', 'Gate Log', AppColors.greenBg, AppColors.greenBorder, const GateLogScreen()),
      _QuickTile('\u{1F511}', 'QR Pass', AppColors.blueBg, AppColors.blueBorder, const QrPassScreen()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(emoji: '\u{1F517}', title: 'Quick Access'),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: tiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final t = tiles[i];
              return GestureDetector(
                onTap: () => onPush(t.screen),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: t.bg,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
                          border: Border.all(color: t.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(t.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.label,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickTile {
  final String emoji;
  final String label;
  final Color bg;
  final Color border;
  final Widget screen;
  const _QuickTile(this.emoji, this.label, this.bg, this.border, this.screen);
}

// ─── 4. Community Feed ───
class _CommunityFeedSection extends StatelessWidget {
  final void Function(Widget) onPush;

  const _CommunityFeedSection({required this.onPush});

  @override
  Widget build(BuildContext context) {
    final notices = MockData.notices.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          emoji: '\u{1F3D8}\uFE0F',
          title: 'Community',
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CommunityScreen()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: notices.map((n) => WarmCard(
              onTap: () => onPush(const NoticesScreen()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amberBg,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                        ),
                        child: Text(
                          n.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeAgo(n.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
