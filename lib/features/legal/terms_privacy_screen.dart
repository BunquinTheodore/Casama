import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../shared/widgets/casama_button.dart';

class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CasamaColors.primaryCoral,
          labelColor: CasamaColors.primaryCoral,
          unselectedLabelColor: context.textSecondaryColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Terms'),
            Tab(text: 'Privacy'),
            Tab(text: 'Permissions'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermsTab(),
                  _buildPrivacyTab(),
                  _buildPermissionsTab(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(CasamaSpacing.md),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: CasamaButton(
                label: 'I Understand & Agree',
                isPill: true,
                onPressed: () => context.pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsTab() {
    return ListView(
      padding: const EdgeInsets.all(CasamaSpacing.lg),
      children: [
        _buildSectionCard(
          icon: Icons.handshake_outlined,
          title: 'Household Harmony',
          content: 'Casama is designed to foster transparency, cooperation, and goodwill between housemates. By using Casama, you agree to treat your housemates with respect and keep household records accurate.',
        ),
        const SizedBox(height: CasamaSpacing.md),
        _buildSectionCard(
          icon: Icons.payments_outlined,
          title: 'Parcel Deliveries & COD Reimbursement',
          content: 'When a housemate covers Cash on Delivery (COD) on your behalf, you are expected to settle the reimbursement promptly. Casama tracks these balances transparently to prevent awkward financial friction.',
        ),
        const SizedBox(height: CasamaSpacing.md),
        _buildSectionCard(
          icon: Icons.checklist_rounded,
          title: 'Chores & Maintenance Responsibilities',
          content: 'Chore assignments and Roulette spins are intended to distribute responsibilities fairly. Completed tasks award Good Kasama points to recognize helpful housemates.',
        ),
        const SizedBox(height: CasamaSpacing.md),
        _buildSectionCard(
          icon: Icons.inventory_2_outlined,
          title: 'Shared Belongings & Borrowing',
          content: 'Items logged in the Lost, Found & Borrowed board belong to household members. Respect borrowed items, return them in good condition, and notify the owner of any damage.',
        ),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.all(CasamaSpacing.lg),
      children: [
        _buildSectionCard(
          icon: Icons.location_off_rounded,
          title: 'Zero Background GPS Tracking',
          badge: 'Privacy First',
          content: 'Casama strictly respects your personal privacy. The app NEVER monitors, requests, or records your continuous background GPS location. Your presence status (In, Out, Away) is entirely controlled by you manually.',
        ),
        const SizedBox(height: CasamaSpacing.md),
        _buildSectionCard(
          icon: Icons.shield_outlined,
          title: 'Household Data Isolation (RLS)',
          content: 'Your household conversations, delivery logs, tasks, and item postings are isolated using Row Level Security (RLS). Only approved members of your household code can view your home data.',
        ),
        const SizedBox(height: CasamaSpacing.md),
        _buildSectionCard(
          icon: Icons.lock_outline_rounded,
          title: 'Data Security & Storage',
          content: 'Your profile details and household communications are encrypted in transit and protected by Supabase security policies. We do not sell your personal data to third parties or advertisers.',
        ),
      ],
    );
  }

  Widget _buildPermissionsTab() {
    return ListView(
      padding: const EdgeInsets.all(CasamaSpacing.lg),
      children: [
        _buildPermissionItem(
          icon: Icons.camera_alt_outlined,
          title: 'Camera & Photo Library',
          reason: 'Required only when you choose to snap or upload a photo of a package delivery slip, a lost item, or a maintenance repair issue.',
          isOptional: false,
        ),
        const SizedBox(height: CasamaSpacing.md),
        _buildPermissionItem(
          icon: Icons.notifications_active_outlined,
          title: 'Push Notifications',
          reason: 'Used to alert you when a parcel arrives, when someone covers your COD, or when a housemate invites you to a household meet-up.',
          isOptional: true,
        ),
        const SizedBox(height: CasamaSpacing.md),
        _buildPermissionItem(
          icon: Icons.storage_rounded,
          title: 'Local Storage & Offline Cache',
          reason: 'Used to store your current session token, preferences, and offline cache so Casama opens smoothly and quickly even with low connectivity.',
          isOptional: false,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    String? badge,
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
                  borderRadius: CasamaSpacing.roundedSm,
                ),
                child: Icon(icon, size: 20, color: CasamaColors.primaryCoral),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
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
          const SizedBox(height: CasamaSpacing.sm),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String reason,
    required bool isOptional,
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
            decoration: BoxDecoration(
              color: context.tileChatColor,
              borderRadius: CasamaSpacing.roundedMd,
            ),
            child: Icon(
              icon,
              size: 22,
              color: context.isDark
                  ? CasamaColors.primaryCoral
                  : CasamaColors.midnightNavy,
            ),
          ),
          const SizedBox(width: CasamaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isOptional ? 'Optional' : 'Required',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOptional
                            ? context.textSecondaryColor
                            : CasamaColors.primaryCoral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
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
