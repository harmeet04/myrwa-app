import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/mock_data.dart';
import '../../utils/helpers.dart';
import '../../models/models.dart';
import '../../utils/prefs_service.dart';
import '../../utils/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  String _timeRemaining(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(title: const Text('Polls')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePoll(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Poll'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.pollsStream(society),
        builder: (context, snapshot) {
          List<Poll> polls;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            polls = snapshot.data!.docs
                .map((d) => FirestoreService.pollFromDoc(d))
                .toList();
          } else {
            polls = MockData.polls;
          }

          // Restore votes from prefs
          final saved = PrefsService.pollVotes;
          for (final p in polls) {
            if (saved.containsKey(p.id)) p.votedIndex = saved[p.id];
          }

          if (polls.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.poll_outlined, size: 72, color: AppColors.cardBorder),
              const SizedBox(height: 12),
              Text('No polls yet', style: TextStyle(fontSize: 16, color: AppColors.textTertiary)),
            ]));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: polls.length,
              itemBuilder: (_, i) {
                final p = polls[i];
                final voted = p.votedIndex != null;
                final timeLeft = _timeRemaining(p.endDate);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        if (!voted)
                          ...List.generate(p.options.length, (oi) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: !p.isActive ? null : () {
                                  HapticFeedback.mediumImpact();
                                  setState(() { p.votes[oi]++; p.votedIndex = oi; });
                                  PrefsService.savePollVote(p.id, oi);
                                  AnalyticsService.logPollVoted(p.id);
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(children: [
                                    Icon(Icons.radio_button_unchecked, size: 18, color: AppColors.textTertiary),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(p.options[oi])),
                                  ]),
                                ),
                              ),
                            );
                          })
                        else
                          ...() {
                            const barColors = [
                              AppColors.primaryAmber,
                              AppColors.statusSuccess,
                              AppColors.primaryOrange,
                              Color(0xFF7C3AED),
                              Color(0xFF3B82F6),
                            ];
                            return List.generate(p.options.length, (oi) {
                              final voteCount = p.votes[oi];
                              final totalVotes = p.totalVotes;
                              final percentage = totalVotes > 0 ? voteCount / totalVotes : 0.0;
                              final isSelected = p.votedIndex == oi;
                              final barColor = barColors[oi % barColors.length];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      if (isSelected) ...[
                                        Icon(Icons.check_circle, size: 16, color: barColor),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(child: Text(p.options[oi], style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
                                      Text('$voteCount votes', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ]),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: totalVotes > 0 ? voteCount / totalVotes : 0,
                                        minHeight: 8,
                                        backgroundColor: AppColors.cardBorder,
                                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${(percentage * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                  ],
                                ),
                              );
                            });
                          }(),
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
          );
        },
      ),
    );
  }

  void _showCreatePoll(BuildContext context) {
    final questionCtrl = TextEditingController();
    final optionCtrls = [TextEditingController(), TextEditingController()];
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
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    final options = optionCtrls.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                    if (questionCtrl.text.isNotEmpty && options.length >= 2) {
                      final poll = Poll(
                        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                        question: questionCtrl.text, options: options,
                        votes: List.filled(options.length, 0), totalVoters: 0,
                        endDate: DateTime.now().add(const Duration(days: 7)),
                        createdBy: PrefsService.userName.isEmpty ? 'You' : PrefsService.userName,
                      );
                      FirestoreService.addPoll(poll);
                      Navigator.pop(ctx);
                      showSnack(context, '\u2705 Poll created!');
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
