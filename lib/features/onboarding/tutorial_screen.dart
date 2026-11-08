import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../shared/widgets/casama_button.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialSlide> _slides = const [
    _TutorialSlide(
      imagePath: 'assets/images/cas/cas_waving.png',
      title: 'Welcome to Casama! 🦉',
      subtitle: 'Meet Cas, your friendly household companion. Keep everyone on the same page with manual presence updates and instant coordination.',
      accentColor: CasamaColors.primaryCoral,
    ),
    _TutorialSlide(
      imagePath: 'assets/images/cas/cas_deliveries.png',
      title: 'Parcels & COD Made Easy 📦',
      subtitle: 'Never miss a delivery. Signal when you can receive parcels, and track Cash on Delivery (COD) reimbursements with complete transparency.',
      accentColor: CasamaColors.deepTeal,
    ),
    _TutorialSlide(
      imagePath: 'assets/images/cas/cas_tasks.png',
      title: 'Fair Chores & Kasama Points ⭐',
      subtitle: 'Take turns fairly with Chore Roulette, keep maintenance tasks organized, and earn Good Kasama points for keeping your home clean.',
      accentColor: CasamaColors.warmGold,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/household-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CasamaSpacing.lg,
                vertical: CasamaSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CasamaColors.primaryCoral,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Casama Tour',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CasamaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/household-setup'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: CasamaColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CasamaSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mascot Image Container
                        Container(
                          height: 240,
                          alignment: Alignment.center,
                          child: Image.asset(
                            slide.imagePath,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.home_work_rounded,
                                  size: 100,
                                  color: CasamaColors.primaryCoral,
                                ),
                          ),
                        ),
                        const SizedBox(height: CasamaSpacing.xl),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: CasamaSpacing.md),

                        // Subtitle
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Indicators
            Padding(
              padding: const EdgeInsets.all(CasamaSpacing.xl),
              child: Column(
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? CasamaColors.primaryCoral
                              : CasamaColors.borderGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CasamaSpacing.xl),

                  // Action Button
                  CasamaButton(
                    label: _currentPage == _slides.length - 1
                        ? 'Set Up Household'
                        : 'Continue',
                    isPill: true,
                    height: 52,
                    onPressed: _onNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialSlide {
  final String imagePath;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _TutorialSlide({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}
