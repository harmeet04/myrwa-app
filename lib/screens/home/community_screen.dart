import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../widgets/warm_card.dart';
import '../notices/notices_screen.dart';
import '../chat/chat_list_screen.dart';
import '../events/events_screen.dart';
import '../polls/polls_screen.dart';
import '../directory/directory_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _CommunityItem('📢', 'Notices', 'Announcements & updates', AppColors.amberBg, AppColors.amberBorder, const NoticesScreen()),
      _CommunityItem('💬', 'Chat', 'Messages with residents', AppColors.pinkBg, AppColors.pinkBorder, const ChatListScreen()),
      _CommunityItem('📅', 'Events', 'Society events & RSVP', AppColors.purpleBg, AppColors.purpleBorder, const EventsScreen()),
      _CommunityItem('🗳️', 'Polls', 'Vote on society decisions', AppColors.blueBg, AppColors.blueBorder, const PollsScreen()),
      _CommunityItem('👥', 'Directory', 'Residents & contacts', AppColors.greenBg, AppColors.greenBorder, const DirectoryScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return WarmCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    border: Border.all(color: item.borderColor, width: 1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommunityItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color borderColor;
  final Widget screen;

  const _CommunityItem(this.emoji, this.title, this.subtitle, this.bgColor, this.borderColor, this.screen);
}
