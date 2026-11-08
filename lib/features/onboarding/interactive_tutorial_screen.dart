import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_button.dart';

class InteractiveTutorialScreen extends ConsumerStatefulWidget {
  const InteractiveTutorialScreen({super.key});

  @override
  ConsumerState<InteractiveTutorialScreen> createState() =>
      _InteractiveTutorialScreenState();
}

class _InteractiveTutorialScreenState
    extends ConsumerState<InteractiveTutorialScreen> {
  int _currentStep = 0;

  final List<_TourStepData> _steps = const [
    _TourStepData(
      navIndex: 0,
      navLabel: 'Home',
      title: '1. Home Dashboard & Calendar 🏠',
      description: 'View live housemate presence at a glance, update your status with notes, inspect the interactive activity calendar, and track upcoming deliveries.',
      mascotImage: 'assets/images/cas/cas_hero.png',
      navIcon: Icons.home_rounded,
      highlightDetail:
          'Active now: see who is home or out without background GPS',
    ),
    _TourStepData(
      navIndex: 1,
      navLabel: 'Boards',
      title: '2. Household Boards 📦',
      description: 'Access all 3 core household boards in one organized view: Parcels & COD settlement, Lost & Found belongings, and Maintenance repairs.',
      mascotImage: 'assets/images/cas/cas_deliveries.png',
      navIcon: Icons.dashboard_outlined,
      highlightDetail: 'Keep records authoritative and avoid awkward roommate money disputes',
    ),
    _TourStepData(
      navIndex: 2,
      navLabel: 'Plus (+)',
      title: '3. Plus (+) Quick Actions ➕',
      description: 'The center button gives you one-tap access to schedule a parcel delivery, report a lost item, assign a maintenance task, or spin Chore Roulette!',
      mascotImage: 'assets/images/cas/cas_roulette.png',
      navIcon: Icons.add,
      highlightDetail: 'Spin the Chore Roulette when duties are disputed for fair random turns',
    ),
    _TourStepData(
      navIndex: 3,
      navLabel: 'Chat',
      title: '4. Household Chat & Connect 💬',
      description: 'Stay connected in the Casa 204 household channel, message housemates 1-on-1 directly, and propose or RSVP to structured meet-ups.',
      mascotImage: 'assets/images/cas/cas_together.png',
      navIcon: Icons.chat_bubble_outline_rounded,
      highlightDetail:
          'Organize study sessions, meals, and general announcements smoothly',
    ),
    _TourStepData(
      navIndex: 4,
      navLabel: 'Profile',
      title: '5. Profile & Settings ⚙️',
      description: 'View your earned Good Kasama points, check the monthly leaderboard podium, copy your household invite code, and toggle Light/Dark Mode.',
      mascotImage: 'assets/images/cas/cas_jumping.png',
      navIcon: Icons.person_outline_rounded,
      highlightDetail:
          'Recognize helpful housemates with monthly Kasama rewards',
    ),
  ];

  void _finishTutorial() {
    ref.read(repositoryProvider).completeOnboardingTutorial();
    context.go('/dashboard');
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _finishTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Tour (${_currentStep + 1} of ${_steps.length})'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
        actions: [
          TextButton(
            onPressed: _finishTutorial,
            child: Text(
              'Skip',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.lg),
              child: Row(
                children: List.generate(
                  _steps.length,
                  (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentStep
                            ? CasamaColors.primaryCoral
                            : context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: CasamaSpacing.md),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CasamaSpacing.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mascot Illustration
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: Image.asset(
                        step.mascotImage,
                        height: 170,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          step.navIcon,
                          size: 80,
                          color: CasamaColors.primaryCoral,
                        ),
                      ),
                    ),
                    const SizedBox(height: CasamaSpacing.md),

                    // Title
                    Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      step.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: CasamaSpacing.md),

                    // Feature Highlight Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CasamaColors.tileParcels,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CasamaColors.primaryCoral.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tips_and_updates_outlined,
                            size: 16,
                            color: CasamaColors.primaryCoral,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              step.highlightDetail,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: CasamaColors.primaryCoral,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mock Navigation Bar with Highlighted Tab
            Container(
              margin: const EdgeInsets.symmetric(horizontal: CasamaSpacing.md),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMockNavItem(0, Icons.home_rounded, 'Home'),
                  _buildMockNavItem(1, Icons.dashboard_outlined, 'Boards'),
                  _buildMockNavCenterFab(2),
                  _buildMockNavItem(
                    3,
                    Icons.chat_bubble_outline_rounded,
                    'Chat',
                  ),
                  _buildMockNavItem(4, Icons.person_outline_rounded, 'Profile'),
                ],
              ),
            ),
            const SizedBox(height: CasamaSpacing.md),

            // Bottom Continue / Finish Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.xl),
              child: CasamaButton(
                label: _currentStep == _steps.length - 1
                    ? 'Enter Home Dashboard'
                    : 'Next Navigation Element',
                isPill: true,
                height: 52,
                onPressed: _nextStep,
              ),
            ),
            const SizedBox(height: CasamaSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildMockNavItem(int index, IconData icon, String label) {
    final isHighlighted = _steps[_currentStep].navIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted ? CasamaColors.tileParcels : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: CasamaColors.primaryCoral, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isHighlighted
                ? CasamaColors.primaryCoral
                : CasamaColors.textMuted,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted
                  ? CasamaColors.primaryCoral
                  : CasamaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockNavCenterFab(int index) {
    final isHighlighted = _steps[_currentStep].navIndex == index;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CasamaColors.primaryCoral,
        shape: BoxShape.circle,
        border: isHighlighted
            ? Border.all(color: CasamaColors.midnightNavy, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: CasamaColors.primaryCoral.withValues(
              alpha: isHighlighted ? 0.6 : 0.3,
            ),
            blurRadius: isHighlighted ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    );
  }
}

class _TourStepData {
  final int navIndex;
  final String navLabel;
  final String title;
  final String description;
  final String mascotImage;
  final IconData navIcon;
  final String highlightDetail;

  const _TourStepData({
    required this.navIndex,
    required this.navLabel,
    required this.title,
    required this.description,
    required this.mascotImage,
    required this.navIcon,
    required this.highlightDetail,
  });
}
