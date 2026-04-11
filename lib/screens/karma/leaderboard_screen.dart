import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/prefs_service.dart';
import '../../services/karma_service.dart';
import '../../services/auth_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final society = PrefsService.societyName;

    return Scaffold(
      backgroundColor: AppColors.scaffoldLight,
      appBar: AppBar(
        title: const Text('Community Karma 🌟'),
        backgroundColor: AppColors.scaffoldLight,
        elevation: 0,
      ),
      body: Column(
        children: [
          // My karma card
          _MyKarmaCard(society: society),
          // Leaderboard list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: KarmaService.leaderboardStream(society),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🌱', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'No karma data yet',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Start participating to earn points!',
                          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final myUid = AuthService.uid;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final uid = data['uid'] as String? ?? docs[i].id;
                    final name = data['name'] as String? ?? 'Resident';
                    final flat = data['flat'] as String? ?? '';
                    final points = (data['totalPoints'] ?? 0) as int;
                    final isMe = uid == myUid;
                    final rank = i + 1;

                    return _LeaderboardRow(
                      rank: rank,
                      name: name,
                      flat: flat,
                      points: points,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Karma Card ──────────────────────────────────────────────────────────────

class _MyKarmaCard extends StatelessWidget {
  final String society;
  const _MyKarmaCard({required this.society});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: KarmaService.myKarmaStream(),
      builder: (context, snapshot) {
        int points = 0;
        int rank = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          points = (data['totalPoints'] ?? 0) as int;
        }

        final badge = KarmaService.getBadge(points);
        final badgeColor = Color(KarmaService.getBadgeColor(points));
        final name = PrefsService.userName.isEmpty ? 'Resident' : PrefsService.userName;
        final flat = PrefsService.userFlat;

        return StreamBuilder<QuerySnapshot>(
          stream: KarmaService.leaderboardStream(society),
          builder: (context, lbSnap) {
            if (lbSnap.hasData) {
              final myUid = AuthService.uid;
              final docs = lbSnap.data!.docs;
              for (int i = 0; i < docs.length; i++) {
                final d = docs[i].data() as Map<String, dynamic>;
                if ((d['uid'] ?? docs[i].id) == myUid) {
                  rank = i + 1;
                  break;
                }
              }
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + flat row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryAmber,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'R',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (flat.isNotEmpty)
                              Text(
                                'Flat $flat',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Points row
                  Row(
                    children: [
                      Text(
                        '🌟 $points points',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (rank > 0)
                        Text(
                          'Rank #$rank in your community',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Leaderboard Row ────────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String flat;
  final int points;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    required this.flat,
    required this.points,
    required this.isMe,
  });

  String _rankEmoji() {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFD97706);
      case 2:
        return const Color(0xFF6B7280);
      case 3:
        return const Color(0xFFB45309);
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = KarmaService.getBadge(points);
    final badgeColor = Color(KarmaService.getBadgeColor(points));
    final isTopThree = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFFFEF3C7)
            : (isTopThree ? Colors.white : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primaryAmber
              : (isTopThree
                  ? _rankColor().withValues(alpha: 0.3)
                  : AppColors.cardBorder),
          width: isMe ? 2 : 1,
        ),
        boxShadow: isTopThree || isMe
            ? [
                BoxShadow(
                  color: (isMe ? AppColors.primaryAmber : _rankColor()).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTopThree
                ? Text(
                    _rankEmoji(),
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _rankColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isTopThree
                ? _rankColor().withValues(alpha: 0.15)
                : AppColors.amberBg,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'R',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isTopThree ? _rankColor() : AppColors.primaryAmber,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + flat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAmber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                if (flat.isNotEmpty)
                  Text(
                    'Flat $flat',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Points + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points pts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? _rankColor() : AppColors.textPrimary,
                ),
              ),
              Text(
                badge.split(' ').last,
                style: TextStyle(
                  fontSize: 10,
                  color: badgeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
