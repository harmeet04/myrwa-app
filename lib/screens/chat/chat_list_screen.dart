import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../utils/mock_data.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uid = AuthService.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages / संदेश')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChat(context),
        child: const Icon(Icons.edit),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.chatRoomsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Text('Start a conversation!', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final participants = List<String>.from(d['participants'] ?? []);
              final otherUid = participants.firstWhere((p) => p != uid, orElse: () => '');
              final names = d['participantNames'] as Map<String, dynamic>? ?? {};
              final flats = d['participantFlats'] as Map<String, dynamic>? ?? {};
              final otherName = names[otherUid] ?? 'Unknown';
              final otherFlat = flats[otherUid] ?? '';
              final lastMessage = d['lastMessage'] ?? '';
              final lastTime = (d['lastTime'] as Timestamp?)?.toDate() ?? DateTime.now();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Text(otherName.isNotEmpty ? otherName[0] : '?', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                ),
                title: Row(children: [
                  Text(otherName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text(otherFlat, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(timeAgo(lastTime), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(otherName: otherName, otherFlat: otherFlat, otherId: otherUid),
                )),
              );
            },
          );
        },
      ),
    );
  }

  void _showNewChat(BuildContext context) {
    final society = PrefsService.societyName;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Start New Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.residentsStream(society),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    // Fallback to mock data
                    final residents = MockData.residents;
                    return ListView.builder(
                      controller: ctrl,
                      itemCount: residents.length,
                      itemBuilder: (ctx, i) {
                        final r = residents[i];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Color(r.avatarColor), child: Text(r.name[0], style: const TextStyle(color: Colors.white))),
                          title: Text(r.name),
                          subtitle: Text('Flat ${r.flat}'),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatScreen(otherName: r.name, otherFlat: r.flat, otherId: r.id),
                            ));
                          },
                        );
                      },
                    );
                  }
                  return ListView.builder(
                    controller: ctrl,
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final name = d['name'] ?? '';
                      final flat = d['flat'] ?? '';
                      final color = d['avatarColor'] ?? 0xFF1565C0;
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Color(color), child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white))),
                        title: Text(name),
                        subtitle: Text('Flat $flat'),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatScreen(otherName: name, otherFlat: flat, otherId: docs[i].id),
                          ));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
