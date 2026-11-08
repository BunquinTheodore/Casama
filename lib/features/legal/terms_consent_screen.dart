import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_button.dart';

class TermsConsentScreen extends ConsumerStatefulWidget {
  const TermsConsentScreen({super.key});

  @override
  ConsumerState<TermsConsentScreen> createState() => _TermsConsentScreenState();
}

class _TermsConsentScreenState extends ConsumerState<TermsConsentScreen> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  void _acknowledgeAndContinue() {
    if (!_agreedToTerms || !_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge both agreements to proceed.'),
          backgroundColor: CasamaColors.errorRed,
        ),
      );
      return;
    }

    ref.read(repositoryProvider).recordTermsConsent();
    context.push('/permissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: CasamaSpacing.sm),
              Text(
                'Household Agreements 📋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Step 3 of 4: Review and acknowledge our household guidelines and privacy commitments before entering your home.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: CasamaSpacing.lg),

              // Summary Card 1: Terms of Service
              _buildAgreementCard(
                icon: Icons.gavel_rounded,
                title: 'Terms of Service',
                summary: 'Covers household mutual respect, prompt COD parcel reimbursements, shared resource borrowing, and fair chore obligations.',
                onReadMore: () => context.push('/terms'),
                isChecked: _agreedToTerms,
                checkboxLabel: 'I accept the Terms of Service',
                onChanged: (val) =>
                    setState(() => _agreedToTerms = val ?? false),
              ),
              const SizedBox(height: CasamaSpacing.md),

              // Summary Card 2: Privacy Policy
              _buildAgreementCard(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                badge: 'Zero GPS Tracking',
                summary: 'Your presence is 100% manually updated by you. Casama NEVER monitors background GPS. Household records are isolated strictly to your housemates via Supabase RLS.',
                onReadMore: () => context.push('/terms'),
                isChecked: _agreedToPrivacy,
                checkboxLabel:
                    'I acknowledge the Privacy Policy & Data Protections',
                onChanged: (val) =>
                    setState(() => _agreedToPrivacy = val ?? false),
              ),
              const SizedBox(height: CasamaSpacing.xl),

              // Accept & Continue
              CasamaButton(
                label: 'Acknowledge & Continue',
                isPill: true,
                height: 52,
                onPressed: _acknowledgeAndContinue,
              ),
              const SizedBox(height: CasamaSpacing.md),

              Center(
                child: Text(
                  'Next: Relevant device permissions',
                  style: TextStyle(
                    fontSize: 12,
                    color: CasamaColors.textSecondary.withValues(alpha: 0.8),
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

  Widget _buildAgreementCard({
    required IconData icon,
    required String title,
    String? badge,
    required String summary,
    required VoidCallback onReadMore,
    required bool isChecked,
    required String checkboxLabel,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(CasamaSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.tileParcelsColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: CasamaColors.primaryCoral, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF1B3B2B)
                        : CasamaColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.isDark
                          ? const Color(0xFF81C784)
                          : CasamaColors.successGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onReadMore,
            child: const Text(
              'Read Full Document ➔',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: CasamaColors.primaryCoral,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isChecked,
                  activeColor: CasamaColors.primaryCoral,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  checkboxLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
