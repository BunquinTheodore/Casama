import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/cas_mascot_view.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);

    final leaderboardList = [
      _LeaderboardEntry(
        'Jon Paul Berana',
        '@jpberana',
        repo.kasamaPoints,
        '1st',
        '🥇',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
      ),
      _LeaderboardEntry(
        'Maria Santos',
        '@maria',
        85,
        '2nd',
        '🥈',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
      ),
      _LeaderboardEntry(
        'Alex Rivera',
        '@alex',
        65,
        '3rd',
        '🥉',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
      ),
      _LeaderboardEntry(
        'Ria Garcia',
        '@ria',
        55,
        '4th',
        '🎖️',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80',
      ),
    ];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Kasama Leaderboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.lg),
          children: [
            const SizedBox(height: CasamaSpacing.sm),

            // Top Hero Card with Cas Jumping Celebration
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CasamaColors.midnightNavy,
                borderRadius: CasamaSpacing.roundedXl,
              ),
              child: Row(
                children: [
                  const CasMascotView(
                    pose: CasPose.jumping,
                    width: 85,
                    height: 85,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'November 2026',
                          style: TextStyle(
                            color: CasamaColors.warmGold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Good Kasama Rank',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Every helpful deed coordinates a better home.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: CasamaSpacing.xl),

            // Rankings List
            Text(
              'Household Standings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: CasamaSpacing.sm),

            ...leaderboardList.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: CasamaSpacing.roundedLg,
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Text(entry.medal, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(entry.avatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          Text(
                            entry.handle,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${entry.points} pts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CasamaColors.primaryCoral,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: CasamaSpacing.lg),

            // Points Rules Guide Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: CasamaSpacing.roundedLg,
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Earn Points:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Receive & confirm a delivery: +5 pts',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                  Text(
                    '• Complete maintenance repair: +5 pts',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                  Text(
                    '• Restock household supplies: +2 pts',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                  Text(
                    '• Locate and return lost item: +3 pts',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: CasamaSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEntry {
  final String name;
  final String handle;
  final int points;
  final String rank;
  final String medal;
  final String avatar;

  _LeaderboardEntry(
    this.name,
    this.handle,
    this.points,
    this.rank,
    this.medal,
    this.avatar,
  );
}
