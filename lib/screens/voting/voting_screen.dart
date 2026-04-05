import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../utils/prefs_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Voting / डिजिटल मतदान'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.collectionStream('elections', society),
        builder: (context, snapshot) {
          List<_Election> elections;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            elections = snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final candidates = (d['candidates'] as List<dynamic>? ?? []).map((c) {
                final cm = c as Map<String, dynamic>;
                return _Candidate(name: cm['name'] ?? '', subtitle: cm['subtitle'], votes: cm['votes'] ?? 0);
              }).toList();
              final votedBy = List<String>.from(d['votedBy'] ?? []);
              final uid = AuthService.uid;
              return _Election(
                id: doc.id,
                title: d['title'] ?? '',
                description: d['description'] ?? '',
                type: d['type'] ?? 'election',
                isAnonymous: d['isAnonymous'] ?? true,
                endDate: (d['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isActive: d['isActive'] ?? true,
                totalVoted: d['totalVoted'] ?? 0,
                totalEligible: d['totalEligible'] ?? 96,
                candidates: candidates,
                hasVoted: votedBy.contains(uid),
                votedIndex: d['votedIndex_$uid'],
              );
            }).toList();
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            elections = _MockElections.elections;
          }

          final active = elections.where((e) => e.isActive).toList();
          final completed = elections.where((e) => !e.isActive).toList();

          return TabBarView(
            controller: _tab,
            children: [
              _buildList(active, true),
              _buildList(completed, false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<_Election> list, bool isActive) {
    if (list.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.how_to_vote_outlined, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(isActive ? 'No active elections\nकोई चालू चुनाव नहीं' : 'No completed elections',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  backgroundColor: e.isActive ? Colors.blue.shade100 : Colors.green.shade100,
                  child: Icon(e.type == 'election' ? Icons.how_to_vote : Icons.poll, color: e.isActive ? Colors.blue : Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${e.type == "election" ? "🗳️ Election" : "📊 Budget Vote"} • ${e.isAnonymous ? "Anonymous" : "Public"}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.isActive ? Colors.blue.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(e.isActive ? 'LIVE' : 'DONE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: e.isActive ? Colors.blue : Colors.green)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(e.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text('Ends: ${formatDate(e.endDate)} • Voted: ${e.totalVoted}/${e.totalEligible}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 12),
              ...e.candidates.asMap().entries.map((entry) {
                final idx = entry.key;
                final c = entry.value;
                final percentage = e.totalVoted > 0 ? (c.votes / e.totalVoted * 100) : 0.0;
                final isWinner = !e.isActive && c.votes == e.candidates.map((x) => x.votes).reduce((a, b) => a > b ? a : b);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: e.isActive && !e.hasVoted ? () => _castVote(e, idx) : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isWinner ? Colors.green : (e.votedIndex == idx ? Colors.blue : Colors.grey.shade300)),
                        color: isWinner ? Colors.green.shade50 : (e.votedIndex == idx ? Colors.blue.shade50 : null)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.primaries[idx % Colors.primaries.length].withValues(alpha: 0.2),
                            child: Text(c.name[0], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.primaries[idx % Colors.primaries.length]))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                              if (isWinner) const Text('🏆 Winner', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                              if (e.votedIndex == idx) const Text('✓ Your vote', style: TextStyle(fontSize: 11, color: Colors.blue)),
                            ]),
                            if (c.subtitle != null)
                              Text(c.subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ])),
                          if (!e.isActive || e.hasVoted)
                            Text('${c.votes} (${percentage.toStringAsFixed(0)}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ]),
                        if (!e.isActive || e.hasVoted) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: e.totalVoted > 0 ? c.votes / e.totalVoted : 0,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(isWinner ? Colors.green : Colors.blue.shade300),
                              minHeight: 6)),
                        ],
                      ]),
                    ),
                  ),
                );
              }),
              if (e.isActive && !e.hasVoted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('👆 Tap a candidate to vote / वोट देने के लिए टैप करें',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                ),
            ]),
          ),
        );
      },
    );
  }

  void _castVote(_Election election, int candidateIdx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Vote / वोट पक्का करें'),
        content: Text('You are voting for:\n\n${election.candidates[candidateIdx].name}\n\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (election.id != null) {
                final uid = AuthService.uid;
                // Update candidates votes
                final updatedCandidates = election.candidates.asMap().entries.map((e) {
                  return {
                    'name': e.value.name,
                    'subtitle': e.value.subtitle,
                    'votes': e.key == candidateIdx ? e.value.votes + 1 : e.value.votes,
                  };
                }).toList();
                await FirestoreService.updateDoc('elections', election.id!, {
                  'candidates': updatedCandidates,
                  'totalVoted': election.totalVoted + 1,
                  'votedBy': FieldValue.arrayUnion([uid]),
                  'votedIndex_$uid': candidateIdx,
                });
              }
              if (!context.mounted) return;
              Navigator.pop(context);
              showSnack(context, '✅ Vote cast successfully! धन्यवाद!');
            },
            child: const Text('Vote / वोट दें'),
          ),
        ],
      ),
    );
  }
}

class _Candidate {
  final String name;
  final String? subtitle;
  int votes;
  _Candidate({required this.name, this.subtitle, this.votes = 0});
}

class _Election {
  final String? id;
  final String title;
  final String description;
  final String type;
  final bool isAnonymous;
  final DateTime endDate;
  final bool isActive;
  int totalVoted;
  final int totalEligible;
  final List<_Candidate> candidates;
  bool hasVoted;
  int? votedIndex;

  _Election({this.id, required this.title, required this.description, required this.type,
    required this.isAnonymous, required this.endDate, required this.isActive,
    required this.totalVoted, required this.totalEligible, required this.candidates,
    this.hasVoted = false, this.votedIndex});
}

class _MockElections {
  static List<_Election> get elections => [
    _Election(
      title: 'RWA President Election 2026',
      description: 'Vote for the new RWA President. All flat owners are eligible.',
      type: 'election', isAnonymous: true, endDate: DateTime(2026, 4, 15), isActive: true,
      totalVoted: 42, totalEligible: 96,
      candidates: [
        _Candidate(name: 'Rajesh Sharma', subtitle: 'Current President, A-101', votes: 18),
        _Candidate(name: 'Vikram Singh', subtitle: 'Ex-Secretary, A-301', votes: 15),
        _Candidate(name: 'Sunita Rao', subtitle: 'Committee Member, C-201', votes: 9),
      ],
    ),
    _Election(
      title: 'Secretary Election 2025',
      description: 'Election for society secretary position.',
      type: 'election', isAnonymous: true, endDate: DateTime(2025, 12, 15), isActive: false,
      totalVoted: 68, totalEligible: 96, hasVoted: true, votedIndex: 0,
      candidates: [
        _Candidate(name: 'Amit Kumar', subtitle: 'Won - A-201', votes: 35),
        _Candidate(name: 'Deepak Iyer', subtitle: 'B-301', votes: 20),
        _Candidate(name: 'Neha Gupta', subtitle: 'A-202', votes: 13),
      ],
    ),
  ];
}
