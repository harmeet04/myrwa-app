import 'package:flutter/material.dart';
import '../notices/notices_screen.dart';
import '../chat/chat_list_screen.dart';
import '../events/events_screen.dart';
import '../polls/polls_screen.dart';
import '../directory/directory_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      _CommunityItem(Icons.campaign_rounded, 'Notices', 'Announcements & updates', Colors.blue.shade700, const NoticesScreen()),
      _CommunityItem(Icons.chat_rounded, 'Chat', 'Messages with residents', Colors.pink.shade600, const ChatListScreen()),
      _CommunityItem(Icons.event_rounded, 'Events', 'Society events & RSVP', Colors.purple.shade600, const EventsScreen()),
      _CommunityItem(Icons.poll_rounded, 'Polls', 'Vote on society decisions', Colors.indigo.shade600, const PollsScreen()),
      _CommunityItem(Icons.people_rounded, 'Directory', 'Residents & contacts', Colors.teal.shade600, const DirectoryScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [item.color, item.color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(item.subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    )),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CommunityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;
  const _CommunityItem(this.icon, this.title, this.subtitle, this.color, this.screen);
}
