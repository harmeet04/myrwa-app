import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/ai_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/mock_data.dart';
import '../../utils/prefs_service.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser, required this.time});
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _dotAnimController;

  static const _suggestedPrompts = [
    'What bills are due?',
    'Show my complaints',
    'Any upcoming events?',
    'Who visited recently?',
  ];

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotAnimController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(
        text: trimmed,
        isUser: true,
        time: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _askGemini(trimmed);
      setState(() {
        _messages.add(_ChatMessage(
          text: reply,
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Sorry, something went wrong. Please try again.',
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _askGemini(String question) async {
    // Gather context from MockData
    final bills =
        MockData.bills.where((b) => b.status == BillStatus.pending).toList();
    final complaints = MockData.complaints
        .where((c) => c.status == ComplaintStatus.open)
        .toList();
    final notices = MockData.notices.take(5).toList();
    final visitors = MockData.visitors
        .where((v) => v.status == VisitorStatus.pending)
        .toList();
    final events = MockData.events.take(3).toList();

    final systemContext = '''
You are myRWA Assistant for ${PrefsService.societyName}.
User: ${PrefsService.userName}, Flat: ${PrefsService.userFlat}

Society data:
- Pending bills (${bills.length}): ${bills.map((b) => '${b.title} Rs${b.amount.toInt()} due ${b.dueDate.day}/${b.dueDate.month}').join(', ')}
- Open complaints (${complaints.length}): ${complaints.map((c) => c.title).join(', ')}
- Recent notices: ${notices.map((n) => n.title).join(', ')}
- Pending visitors: ${visitors.length}
- Upcoming events: ${events.map((e) => '${e.title} on ${e.date.day}/${e.date.month}').join(', ')}

Answer helpfully and concisely (2-3 sentences max). Be friendly, use casual Hindi words where natural. If they ask to do something (like create a complaint), tell them how to do it in the app.
''';

    return await AiService.chat(systemContext, question);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\u{1F916} ',
              style: TextStyle(fontSize: 22),
            ),
            Text(
              'Ask myRWA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length && _isLoading) {
                        return _buildTypingIndicator(isDark);
                      }
                      return _bubble(_messages[i], isDark);
                    },
                  ),
          ),

          // Input bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: AppColors.amberBorder),
              ),
              alignment: Alignment.center,
              child: const Text('\u{1F916}', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Hi ${PrefsService.userName.split(' ').first}! How can I help?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Ask me anything about your society',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestedPrompts.map((prompt) {
                return ActionChip(
                  label: Text(
                    prompt,
                    style: const TextStyle(fontSize: 13),
                  ),
                  backgroundColor: AppColors.amberBg,
                  side: const BorderSide(color: AppColors.amberBorder),
                  onPressed: () => _sendMessage(prompt),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: msg.isUser ? 60 : 0,
          right: msg.isUser ? 0 : 60,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!msg.isUser) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.amberBorder),
                ),
                alignment: Alignment.center,
                child:
                    const Text('\u{1F916}', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? AppColors.primaryAmber
                      : (isDark ? AppColors.cardDark : AppColors.cardLight),
                  borderRadius: BorderRadius.circular(16),
                  border: msg.isUser
                      ? null
                      : Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: msg.isUser
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amberBorder),
              ),
              alignment: Alignment.center,
              child: const Text('\u{1F916}', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: AnimatedBuilder(
                animation: _dotAnimController,
                builder: (_, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final delay = i * 0.2;
                      final t = (_dotAnimController.value - delay) % 1.0;
                      final scale = t < 0.5 ? 1.0 + t * 0.6 : 1.0 + (1.0 - t) * 0.6;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Transform.scale(
                          scale: scale.clamp(0.8, 1.3),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask anything about your society...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: isDark ? AppColors.scaffoldDark : AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.primaryAmber, width: 1.5),
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: AppColors.primaryAmber,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isLoading ? null : () => _sendMessage(_controller.text),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                child: Icon(
                  _isLoading ? Icons.hourglass_top : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
