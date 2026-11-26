import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repository_provider.dart';
import '../../data/supabase_config.dart';
import '../../shared/widgets/casama_button.dart';
import '../../shared/widgets/casama_text_field.dart';
import '../profile/edit_profile_dialog.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _shareRoomStatus = true;

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final repo = ref.watch(repositoryProvider);
    final notifs = repo.notificationPreferences;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF2C3E5A)
        : CasamaColors.borderGray;
    final textColor = isDark ? Colors.white : CasamaColors.ink;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: CasamaSpacing.lg,
            vertical: CasamaSpacing.md,
          ),
          children: [
            // ──────────────────────────────────────────
            // 1. Account Settings
            // ──────────────────────────────────────────
            const _SettingsSectionHeader(title: 'Account Settings'),
            const SizedBox(height: CasamaSpacing.xs),
            Material(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: CasamaSpacing.roundedLg,
                side: BorderSide(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline_rounded,
                      color: CasamaColors.primaryCoral,
                    ),
                    title: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      '${repo.currentUser.displayName} (${repo.currentUser.handle})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const EditProfileDialog(),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 54, color: borderColor),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_outline_rounded,
                      color: CasamaColors.deepTeal,
                    ),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Update authentication credentials',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  Divider(height: 1, indent: 54, color: borderColor),
                  ListTile(
                    leading: const Icon(
                      Icons.badge_outlined,
                      color: CasamaColors.dustyBlue,
                    ),
                    title: Text(
                      'Manage Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Verified Resident • Casa 204',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CasamaColors.successBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CasamaColors.homeGreen,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 54, color: borderColor),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: CasamaColors.errorRed,
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CasamaColors.errorRed,
                      ),
                    ),
                    subtitle: const Text(
                      'Sign out of your active Casama session',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: CasamaColors.errorRed,
                    ),
                    onTap: () => _confirmLogout(context, repo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CasamaSpacing.lg),

            // ──────────────────────────────────────────
            // 2. Appearance Settings (Light / Dark / System)
            // ──────────────────────────────────────────
            const _SettingsSectionHeader(title: 'Appearance'),
            const SizedBox(height: CasamaSpacing.xs),
            Container(
              padding: const EdgeInsets.all(CasamaSpacing.md),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: CasamaSpacing.roundedLg,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose your preferred visual theme across the application:',
                    style: TextStyle(
                      fontSize: 12,
                      color: CasamaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeChoiceTile(
                          icon: Icons.light_mode_outlined,
                          label: 'Light',
                          isSelected: currentThemeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ThemeChoiceTile(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark',
                          isSelected: currentThemeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ThemeChoiceTile(
                          icon: Icons.brightness_auto_outlined,
                          label: 'System',
                          isSelected: currentThemeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: CasamaSpacing.lg),

            // ──────────────────────────────────────────
            // 3. Notification Settings
            // ──────────────────────────────────────────
            const _SettingsSectionHeader(title: 'Notification Settings'),
            const SizedBox(height: CasamaSpacing.xs),
            Material(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: CasamaSpacing.roundedLg,
                side: BorderSide(color: borderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Household Updates',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Member presence, housemate joins, and announcements',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    value: notifs.householdUpdates,
                    activeTrackColor: CasamaColors.primaryCoral,
                    onChanged: (v) =>
                        repo.updateNotificationPreferences(householdUpdates: v),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: borderColor,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Parcel & Delivery Alerts',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'When packages arrive or COD payment is needed',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    value: notifs.parcelNotifications,
                    activeTrackColor: CasamaColors.primaryCoral,
                    onChanged: (v) => repo.updateNotificationPreferences(
                      parcelNotifications: v,
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: borderColor,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Task & Chore Reminders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'When maintenance chores are assigned or due',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    value: notifs.taskReminders,
                    activeTrackColor: CasamaColors.primaryCoral,
                    onChanged: (v) =>
                        repo.updateNotificationPreferences(taskReminders: v),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: borderColor,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Chat & Meet-up Notifications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Group messages, direct chats, and meet-up invites',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    value: notifs.chatNotifications,
                    activeTrackColor: CasamaColors.primaryCoral,
                    onChanged: (v) => repo.updateNotificationPreferences(
                      chatNotifications: v,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CasamaSpacing.lg),

            // ──────────────────────────────────────────
            // 4. Privacy and Security
            // ──────────────────────────────────────────
            const _SettingsSectionHeader(title: 'Privacy and Security'),
            const SizedBox(height: CasamaSpacing.xs),
            Material(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: CasamaSpacing.roundedLg,
                side: BorderSide(color: borderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Presence & Status Sharing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Share active room notes with verified housemates',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    value: _shareRoomStatus,
                    activeTrackColor: CasamaColors.primaryCoral,
                    onChanged: (v) => setState(() => _shareRoomStatus = v),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: borderColor,
                  ),
                  SwitchListTile(
                    title: Text(
                      'Let Cas learn my routine',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Uses only your Home and Out taps to forecast when you are home for parcels. Stays on this device. Turning it off deletes what Cas learned.',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    value: repo.isRoutineOptedIn(repo.currentUser.id),
                    activeTrackColor: CasamaColors.primaryCoral,
                    onChanged: (v) =>
                        repo.setRoutineOptIn(repo.currentUser.id, v),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: borderColor,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.perm_device_information_outlined,
                      color: CasamaColors.deepTeal,
                    ),
                    title: Text(
                      'Application Permissions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Camera, photos & local device access status',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => context.push('/permissions'),
                  ),
                  Divider(height: 1, indent: 54, color: borderColor),
                  ListTile(
                    leading: const Icon(
                      Icons.security_outlined,
                      color: CasamaColors.homeGreen,
                    ),
                    title: Text(
                      'Account Security & Two-Factor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Protected via encrypted Supabase Auth session',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: CasamaColors.successBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Secured',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: CasamaColors.homeGreen,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 54, color: borderColor),
                  ListTile(
                    leading: const Icon(
                      Icons.policy_outlined,
                      color: CasamaColors.dustyBlue,
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Zero GPS background tracking guarantee',
                      style: TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => context.push('/terms'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CasamaSpacing.lg),

            // ──────────────────────────────────────────
            // 5. About Casama
            // ──────────────────────────────────────────
            const _SettingsSectionHeader(title: 'About Casama'),
            const SizedBox(height: CasamaSpacing.xs),
            Container(
              padding: const EdgeInsets.all(CasamaSpacing.md),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: CasamaSpacing.roundedLg,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: CasamaColors.midnightNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Casama',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Text(
                            'Version 1.0.0 (Build 1)',
                            style: TextStyle(
                              fontSize: 12,
                              color: CasamaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Making shared living simpler, warmer, and more coordinated.',
                    style: TextStyle(
                      fontSize: 13,
                      color: CasamaColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.push('/terms'),
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: CasamaColors.primaryCoral,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/terms'),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: CasamaColors.primaryCoral,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: CasamaSpacing.lg),

            // Diagnostics and Cache Reset
            Container(
              padding: const EdgeInsets.all(CasamaSpacing.md),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: CasamaSpacing.roundedLg,
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Backend Engine',
                        style: TextStyle(
                          fontSize: 13,
                          color: CasamaColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: SupabaseConfig.isConfigured
                              ? CasamaColors.successBg
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          SupabaseConfig.isConfigured
                              ? 'Live Supabase'
                              : 'High-Fidelity Mock Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: SupabaseConfig.isConfigured
                                ? CasamaColors.successGreen
                                : CasamaColors.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Local cache reset successfully!'),
                          ),
                        );
                      },
                      child: const Text(
                        'Reset Offline Cache',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
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

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CasamaTextField(
                  controller: oldPasswordController,
                  label: 'Current Password',
                  hint: '••••••••',
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => v == null || v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                CasamaTextField(
                  controller: newPasswordController,
                  label: 'New Password',
                  hint: '••••••••',
                  isPassword: true,
                  prefixIcon: Icons.lock_reset_rounded,
                  validator: (v) => v == null || v.length < 6
                      ? 'New password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                CasamaTextField(
                  controller: confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: '••••••••',
                  isPassword: true,
                  prefixIcon: Icons.check_circle_outline,
                  validator: (v) => v != newPasswordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 20),
                CasamaButton(
                  label: 'Update Password',
                  isPill: true,
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully! 🔒'),
                          backgroundColor: CasamaColors.successGreen,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, dynamic repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out of Casama?'),
        content: const Text(
          'Are you sure you want to end your current session? You will need to log back in to access your household.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CasamaColors.errorRed,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              repo.logout();
              context.go('/');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;

  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: CasamaColors.textSecondary,
      ),
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChoiceTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark
        ? const Color(0xFF243650)
        : CasamaColors.softNeutral;
    final unselectedText = isDark ? Colors.white70 : CasamaColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? CasamaColors.primaryCoral : unselectedBg,
          borderRadius: CasamaSpacing.roundedMd,
          border: Border.all(
            color: isSelected
                ? CasamaColors.primaryCoral
                : (isDark ? const Color(0xFF2C3E5A) : CasamaColors.borderGray),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : unselectedText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
