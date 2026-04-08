import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String otherName;
  final String otherFlat;
  final String otherId;

  const ChatScreen({super.key, required this.otherName, required this.otherFlat, required this.otherId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _roomId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> _initRoom() async {
    try {
      final roomId = await FirestoreService.getOrCreateChatRoom(
        widget.otherId, widget.otherName, widget.otherFlat,
      );
      if (mounted) setState(() { _roomId = roomId; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  String _dateLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(time.year, time.month, time.day);
    if (msgDay == today) return 'Today';
    if (msgDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _roomId == null) return;
    _msgCtrl.clear();
    await FirestoreService.sendMessage(_roomId!, text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uid = AuthService.uid;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: cs.primaryContainer,
            child: Text(widget.otherName[0], style: TextStyle(color: cs.primary, fontSize: 14, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherName, style: const TextStyle(fontSize: 16)),
            Text(widget.otherFlat, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
          ]),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _roomId == null
              ? const Center(child: Text('Could not open chat'))
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirestoreService.messagesStream(_roomId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.cardBorder),
                                const SizedBox(height: 12),
                                Text('No messages yet.\nSay hello! 👋', textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textTertiary)),
                              ]),
                            );
                          }

                          // Auto-scroll on new messages
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollCtrl.hasClients) {
                              _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                            }
                          });

                          return ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount: docs.length,
                            itemBuilder: (_, i) {
                              final d = docs[i].data() as Map<String, dynamic>;
                              final senderId = d['senderId'] ?? '';
                              final text = d['text'] ?? '';
                              final time = (d['time'] as Timestamp?)?.toDate() ?? DateTime.now();
                              final isMe = senderId == uid;

                              // Date separator
                              Widget? dateSeparator;
                              if (i == 0) {
                                dateSeparator = _dateSep(context, _dateLabel(time));
                              } else {
                                final prevD = docs[i - 1].data() as Map<String, dynamic>;
                                final prevTime = (prevD['time'] as Timestamp?)?.toDate() ?? DateTime.now();
                                if (_dateLabel(time) != _dateLabel(prevTime)) {
                                  dateSeparator = _dateSep(context, _dateLabel(time));
                                }
                              }

                              return Column(
                                children: [
                                  ?dateSeparator,
                                  Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                      decoration: BoxDecoration(
                                        color: isMe ? cs.primary : cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                                          bottomRight: Radius.circular(isMe ? 4 : 16),
                                        ),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(text, style: TextStyle(color: isMe ? Colors.white : null, fontSize: 14)),
                                          const SizedBox(height: 3),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.textTertiary),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 3),
                                                Icon(Icons.done_all, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -1))],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  isDense: true,
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: cs.primary,
                              child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _dateSep(BuildContext context, String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBorder,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
