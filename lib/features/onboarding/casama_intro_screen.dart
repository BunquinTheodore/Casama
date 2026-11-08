import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_button.dart';

class CasamaIntroScreen extends ConsumerWidget {
  const CasamaIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final greeting = repo.currentUser.effectiveGreetingName;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: CasamaSpacing.md),

              // Skip Button Top Right
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(repositoryProvider).completeOnboardingTutorial();
                    context.go('/dashboard');
                  },
                  child: Text(
                    'Skip to Home',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Mascot Mascot
              Container(
                height: 180,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/cas/cas_waving.png',
                  height: 170,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.home_work_rounded,
                    size: 80,
                    color: CasamaColors.primaryCoral,
                  ),
                ),
              ),
              const SizedBox(height: CasamaSpacing.md),

              // Welcome Title
              Text(
                'Welcome, $greeting! 🦉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),

              // Short explanation
              Text(
                'Casama is your household\'s shared coordination hub, designed to make co-living simpler, warmer, and friction-free.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: CasamaSpacing.xl),

              // Main Application Benefits
              _buildBenefitRow(
                context: context,
                icon: Icons.location_on_outlined,
                iconBg: CasamaColors.tileParcels,
                iconColor: CasamaColors.primaryCoral,
                title: 'Manual Presence Awareness',
                desc: 'Know who is home at a glance with zero intrusive background GPS tracking.',
              ),
              const SizedBox(height: CasamaSpacing.md),

              _buildBenefitRow(
                context: context,
                icon: Icons.inventory_2_outlined,
                iconBg: CasamaColors.tileLostFound,
                iconColor: CasamaColors.deepTeal,
                title: 'Delivery & COD Protection',
                desc: 'Signal parcel reception availability and track Cash on Delivery settlements transparently.',
              ),
              const SizedBox(height: CasamaSpacing.md),

              _buildBenefitRow(
                context: context,
                icon: Icons.casino_outlined,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: CasamaColors.warmGold,
                title: 'Fair Chores & Kasama Points',
                desc: 'Spin the Chore Roulette for fair turn-taking and earn recognition on the leaderboard.',
              ),
              const SizedBox(height: CasamaSpacing.md),

              _buildBenefitRow(
                context: context,
                icon: Icons.chat_bubble_outline_rounded,
                iconBg: CasamaColors.tileChat,
                iconColor: const Color(0xFF3949AB),
                title: 'Harmonious Housemate Connect',
                desc: 'Coordinate in the household group chat, send direct messages, and RSVP to meet-ups.',
              ),
              const SizedBox(height: CasamaSpacing.xl),

              // CTA: Let's Get Started (Launches Interactive Tutorial)
              CasamaButton(
                label: "Let's Get Started",
                isPill: true,
                height: 52,
                onPressed: () => context.push('/interactive-tutorial'),
              ),
              const SizedBox(height: CasamaSpacing.sm),

              TextButton(
                onPressed: () {
                  ref.read(repositoryProvider).completeOnboardingTutorial();
                  context.go('/dashboard');
                },
                child: const Text(
                  'Skip Tutorial & Go to Dashboard',
                  style: TextStyle(
                    color: CasamaColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: CasamaSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(CasamaSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
