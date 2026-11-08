import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import 'casama_button.dart';

/// Centralized Household Invitation Bottom Sheet
void showInviteHousemateSheet(
  BuildContext context, {
  required String householdName,
  required String inviteCode,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Icon badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.tileParcelsColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  color: CasamaColors.primaryCoral,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                'Invite Your Housemates 🏡',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Share this unique household invite code with your roommates so they can join $householdName on Casama.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // Invite code display card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? CasamaColors.darkSurface
                      : CasamaColors.softNeutral,
                  borderRadius: CasamaSpacing.roundedLg,
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      'HOUSEHOLD CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: context.textMutedColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          inviteCode,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: CasamaColors.primaryCoral,
                          ),
                          tooltip: 'Copy Code',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Copied invite code "$inviteCode" to clipboard!',
                                ),
                                backgroundColor: CasamaColors.midnightNavy,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feature benefits reminder
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: CasamaSpacing.roundedMd,
                  border: Border.all(color: context.borderColor),
                ),
                child: const Column(
                  children: [
                    _BenefitRow(
                      icon: Icons.shield_outlined,
                      text: 'Zero GPS tracking — manual presence only',
                    ),
                    SizedBox(height: 6),
                    _BenefitRow(
                      icon: Icons.inventory_2_outlined,
                      text: 'Deliveries & COD advance coordination',
                    ),
                    SizedBox(height: 6),
                    _BenefitRow(
                      icon: Icons.stars_rounded,
                      text: 'Earn Good Kasama points for chores',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Share Button
              CasamaButton(
                label: 'Copy Full Invitation Message',
                icon: Icons.share_rounded,
                onPressed: () {
                  final message =
                      'Hey! Join our household "$householdName" on Casama using invite code: $inviteCode. Download the app to coordinate deliveries, chores, and housemate plans!';
                  Clipboard.setData(ClipboardData(text: message));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invitation message copied to clipboard! Share it with your housemates.',
                      ),
                      backgroundColor: CasamaColors.midnightNavy,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Dismiss / Close button
              CasamaButton(
                label: 'Close',
                style: CasamaButtonStyle.ghost,
                onPressed: () => Navigator.pop(ctx),
                height: 40,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CasamaColors.primaryCoral),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.textColor,
            ),
          ),
        ),
      ],
    );
  }
}
