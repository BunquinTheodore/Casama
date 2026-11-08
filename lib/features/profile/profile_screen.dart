import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_avatar.dart';
import '../../shared/widgets/cas_mascot_view.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final user = repo.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF2C3E5A)
        : CasamaColors.borderGray;
    final textColor = isDark ? Colors.white : CasamaColors.ink;

    final displayName = user.fullName ?? user.displayName;
    final nicknameText =
        user.nickname != null && user.nickname!.trim().isNotEmpty
        ? user.nickname!.trim()
        : 'Not set';
    final ageText = user.age != null
        ? '${user.age} years old'
        : 'Not specified';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 26),
              decoration: const BoxDecoration(
                color: CasamaColors.midnightNavy,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Actions: Settings icon
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                          ),
                          tooltip: 'Settings',
                          onPressed: () => context.push('/settings'),
                        ),
                      ),
                    ),

                    // Avatar with Edit overlay
                    GestureDetector(
                      onTap: () => _showEditProfileModal(context),
                      child: CasamaAvatar(
                        avatarUrl: user.avatarUrl,
                        radius: 46,
                        name: displayName,
                        showEditBadge: true,
                        borderWidth: 2,
                        borderColor: CasamaColors.primaryCoral,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full Name
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Nickname & Handle
                    Text(
                      user.nickname != null && user.nickname!.trim().isNotEmpty
                          ? '"${user.nickname}" • ${user.handle}'
                          : user.handle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Clearly Visible "Edit Profile" Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(
                        Icons.mode_edit_outline_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _showEditProfileModal(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: CasamaSpacing.lg),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.lg),
              child: Column(
                children: [
                  // Personal Information Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: CasamaSpacing.roundedLg,
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showEditProfileModal(context),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: CasamaColors.primaryCoral,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Full Name', value: displayName),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Nickname', value: nicknameText),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Age', value: ageText),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Handle', value: user.handle),
                      ],
                    ),
                  ),

                  const SizedBox(height: CasamaSpacing.md),

                  // Good Kasama Points Card & Audit Trail Trigger
                  GestureDetector(
                    onTap: () => _showPointsAuditSheet(
                      context,
                      repo.pointHistory,
                      repo.kasamaPoints,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: CasamaSpacing.roundedLg,
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF8E1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: CasamaColors.warmGold,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Good Kasama Points',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CasamaColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${repo.kasamaPoints} pts',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CasamaColors.tileParcels,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Gold Tier',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: CasamaColors.primaryCoral,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Tap to view activity & points audit ledger',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CasamaColors.deepTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: CasamaColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: CasamaSpacing.lg),

                  // Menu Options
                  Material(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: CasamaSpacing.roundedLg,
                      side: BorderSide(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _ProfileMenuRow(
                          icon: Icons.home_outlined,
                          title: 'My Household',
                          subtitle: repo.currentHousehold.name,
                          onTap: () => _showHouseholdModal(
                            context,
                            repo.currentHousehold,
                          ),
                        ),
                        Divider(height: 1, indent: 54, color: borderColor),
                        _ProfileMenuRow(
                          icon: Icons.settings_outlined,
                          title: 'Application Settings',
                          subtitle: 'Appearance, notifications & account',
                          onTap: () => context.push('/settings'),
                        ),
                        Divider(height: 1, indent: 54, color: borderColor),
                        _ProfileMenuRow(
                          icon: Icons.shield_outlined,
                          title: 'Privacy & Permissions',
                          subtitle: 'Zero GPS tracking policy',
                          onTap: () => context.push('/terms'),
                        ),
                        Divider(height: 1, indent: 54, color: borderColor),
                        _ProfileMenuRow(
                          icon: Icons.info_outline_rounded,
                          title: 'About Casama',
                          subtitle: 'v1.0.0 (Build 1)',
                          onTap: () => _showAboutModal(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: CasamaSpacing.xl),

                  // Clearly Visible Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CasamaColors.primaryCoral,
                        side: const BorderSide(
                          color: Color(0xFFFFCDD2),
                          width: 1.5,
                        ),
                        backgroundColor: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: CasamaSpacing.roundedMd,
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        ref.read(repositoryProvider).logout();
                        context.go('/');
                      },
                    ),
                  ),

                  const SizedBox(height: CasamaSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPointsAuditSheet(
    BuildContext context,
    List<PointAuditEntry> history,
    int totalPoints,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.only(
              top: 14,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CasamaColors.borderGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF8E1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: CasamaColors.warmGold,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kasama Points Ledger',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total Balance: $totalPoints pts',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CasamaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 16),
                const Text(
                  'Recent Activity & Points Earned',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: CasamaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final dateStr = DateFormat('MMM d, h:mm a')
                          .format(item.timestamp);

                      IconData icon;
                      Color iconColor;
                      switch (item.category) {
                        case 'parcel':
                          icon = Icons.local_shipping_outlined;
                          iconColor = CasamaColors.primaryCoral;
                          break;
                        case 'task':
                          icon = Icons.check_circle_outline;
                          iconColor = CasamaColors.homeGreen;
                          break;
                        case 'lost_found':
                          icon = Icons.search_rounded;
                          iconColor = CasamaColors.deepTeal;
                          break;
                        default:
                          icon = Icons.stars_rounded;
                          iconColor = CasamaColors.warmGold;
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CasamaColors.textSecondary,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CasamaColors.successBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${item.points} pts',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: CasamaColors.successGreen,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHouseholdModal(BuildContext context, dynamic household) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.home_work_outlined,
                size: 48,
                color: CasamaColors.midnightNavy,
              ),
              const SizedBox(height: 12),
              Text(
                household.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share this invite code with your housemates to join:',
                style: TextStyle(
                  color: CasamaColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CasamaColors.softNeutral,
                  borderRadius: CasamaSpacing.roundedMd,
                  border: Border.all(color: CasamaColors.borderGray),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      household.inviteCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: CasamaColors.midnightNavy,
                      ),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 20,
                        color: CasamaColors.primaryCoral,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: household.inviteCode),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invite code copied to clipboard!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CasMascotView(pose: CasPose.hero, width: 100, height: 100),
              const SizedBox(height: 12),
              const Text(
                'Casama & Cas the Owl',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                '"A better home starts with being a good kasama."',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: CasamaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Casama provides one organized place for household members to coordinate presence, deliveries, shared items, maintenance, and small responsibilities.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: CasamaColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileDialog(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: CasamaColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : CasamaColors.ink,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : CasamaColors.ink,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: CasamaColors.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: CasamaColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
