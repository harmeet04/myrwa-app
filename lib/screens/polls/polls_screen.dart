import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../models/models.dart';
import '../../utils/prefs_service.dart';
import '../../utils/app_colors.dart';
import '../../services/analytics_service.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  late List<Poll> _polls;

  @override
  void initState() {
    super.initState();
    _polls = MockData.polls;
    // Restore votes from prefs
    final saved = PrefsService.pollVotes;
    for (final p in _polls) {
      if (saved.containsKey(p.id)) p.votedIndex = saved[p.id];
    }
  }

  String _timeRemaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Polls & Voting')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePoll(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Poll'),
      ),
      body: _polls.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.poll_outlined, size: 72, color: AppColors.cardBorder),
              const SizedBox(height: 12),
              Text('No polls yet', style: TextStyle(fontSize: 16, color: AppColors.textTertiary)),
            ]))
          : RefreshIndicator(
              onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _polls.length,
                itemBuilder: (_, i) {
                  final p = _polls[i];
                  final voted = p.votedIndex != null;
                  final timeLeft = _timeRemaining(p.endDate);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(p.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            if (p.isAnonymous) Tooltip(
                              message: 'Anonymous',
                              child: Icon(Icons.visibility_off, size: 18, color: AppColors.textTertiary),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(p.createdBy, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: p.isActive ? AppColors.primaryAmber.withValues(alpha: 0.1) : AppColors.cardBorder,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.timer_outlined, size: 12, color: p.isActive ? AppColors.primaryAmber : Colors.grey),
                                const SizedBox(width: 4),
                                Text(timeLeft, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.isActive ? AppColors.primaryAmber : Colors.grey)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          ...List.generate(p.options.length, (oi) {
                            final pct = p.totalVotes > 0 ? p.votes[oi] / p.totalVotes : 0.0;
                            final isSelected = p.votedIndex == oi;
                            final isWinner = voted && p.votes[oi] == p.votes.reduce((a, b) => a > b ? a : b);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: voted || !p.isActive ? null : () {
                                  HapticFeedback.mediumImpact();
                                  setState(() { p.votes[oi]++; p.votedIndex = oi; });
                                  PrefsService.savePollVote(p.id, oi);
                                  AnalyticsService.logPollVoted(p.id);
                                  // Animated confirmation
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Row(children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text('Voted for "${p.options[oi]}"'),
                                    ]),
                                    backgroundColor: AppColors.statusSuccess,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ));
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? cs.primary : (isWinner ? AppColors.statusSuccess : AppColors.cardBorder), width: isSelected ? 2 : 1),
                                    color: isSelected ? cs.primary.withValues(alpha: 0.05) : (isWinner ? AppColors.statusSuccess.withValues(alpha: 0.03) : null),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      if (voted) AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeOut,
                                        height: 48,
                                        width: MediaQuery.of(context).size.width * pct * 0.85,
                                        decoration: BoxDecoration(
                                          color: isSelected ? cs.primary.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.06),
                                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        child: Row(children: [
                                          if (!voted) Icon(Icons.radio_button_unchecked, size: 18, color: AppColors.textTertiary),
                                          if (voted && isSelected) Icon(Icons.check_circle, size: 18, color: cs.primary),
                                          if (voted && !isSelected) Icon(Icons.circle_outlined, size: 18, color: AppColors.textTertiary),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(p.options[oi], style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : null))),
                                          if (voted) ...[
                                            Text('${p.votes[oi]}', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                            const SizedBox(width: 6),
                                            Text('${(pct * 100).toInt()}%', style: TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 14,
                                              color: isSelected ? cs.primary : (isWinner ? AppColors.statusSuccess : AppColors.textSecondary),
                                            )),
                                          ],
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.people_outline, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text('${p.totalVotes} votes', style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
                            if (voted) ...[
                              const Spacer(),
                              Icon(Icons.check, size: 14, color: AppColors.statusSuccess),
                              const SizedBox(width: 4),
                              Text('You voted', style: TextStyle(fontSize: 12, color: AppColors.statusSuccess)),
                            ],
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showCreatePoll(BuildContext context) {
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];
    bool isAnonymous = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create Poll', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Question')),
                const SizedBox(height: 12),
                ...List.generate(optionCtrls.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(controller: optionCtrls[i], decoration: InputDecoration(labelText: 'Option ${i + 1}',
                    suffixIcon: optionCtrls.length > 2 ? IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.statusError),
                      onPressed: () => setBS(() => optionCtrls.removeAt(i))) : null)),
                )),
                TextButton.icon(
                  onPressed: () => setBS(() => optionCtrls.add(TextEditingController())),
                  icon: const Icon(Icons.add), label: const Text('Add Option'),
                ),
                SwitchListTile(
                  title: const Text('Anonymous Voting'),
                  value: isAnonymous,
                  onChanged: (v) => setBS(() => isAnonymous = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    final options = optionCtrls.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                    if (questionCtrl.text.isNotEmpty && options.length >= 2) {
                      setState(() {
                        _polls.insert(0, Poll(
                          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                          question: questionCtrl.text, options: options,
                          votes: List.filled(options.length, 0), totalVoters: 0,
                          endDate: DateTime.now().add(const Duration(days: 7)),
                          createdBy: 'You', isAnonymous: isAnonymous,
                        ));
                      });
                      Navigator.pop(ctx);
                      showSnack(context, '✅ Poll created!');
                    } else {
                      showSnack(context, 'Need a question and at least 2 options', isError: true);
                    }
                  },
                  child: const Text('Create Poll'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
