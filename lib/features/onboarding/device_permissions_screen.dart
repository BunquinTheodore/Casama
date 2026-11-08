import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../shared/widgets/casama_button.dart';

class DevicePermissionsScreen extends StatefulWidget {
  const DevicePermissionsScreen({super.key});

  @override
  State<DevicePermissionsScreen> createState() =>
      _DevicePermissionsScreenState();
}

class _DevicePermissionsScreenState extends State<DevicePermissionsScreen> {
  bool _notificationsAllowed = true;
  bool _cameraPhotosAllowed = true;
  bool _contactsAllowed = false;

  void _continue() {
    context.push('/intro');
  }

  void _skipAll() {
    setState(() {
      _notificationsAllowed = false;
      _cameraPhotosAllowed = false;
      _contactsAllowed = false;
    });
    context.push('/intro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Permissions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _skipAll,
            child: Text(
              'Skip All',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: CasamaSpacing.sm),
              Text(
                'Device Permissions 📱',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Step 4 of 4: Casama requests only what is needed for shared living coordination. You can customize or skip each permission.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: CasamaSpacing.lg),

              // Permission 1: Push Notifications
              _buildPermissionTile(
                icon: Icons.notifications_active_outlined,
                iconBg: context.isDark
                    ? CasamaColors.darkTileParcels
                    : CasamaColors.tileParcels,
                iconColor: CasamaColors.primaryCoral,
                title: 'Push Notifications',
                badge: 'Recommended',
                reason: 'Receive timely alerts when a delivery arrives, when housemates request COD payment assistance, or when someone schedules a household gathering.',
                value: _notificationsAllowed,
                onChanged: (val) => setState(() => _notificationsAllowed = val),
              ),
              const SizedBox(height: CasamaSpacing.md),

              // Permission 2: Camera & Photos
              _buildPermissionTile(
                icon: Icons.photo_camera_outlined,
                iconBg: context.isDark
                    ? CasamaColors.darkTileLostFound
                    : CasamaColors.tileLostFound,
                iconColor: CasamaColors.deepTeal,
                title: 'Camera & Photo Library',
                badge: 'Recommended',
                reason: 'Take or attach photos of parcel delivery slips, items for the Lost & Found board, and maintenance repair receipts.',
                value: _cameraPhotosAllowed,
                onChanged: (val) => setState(() => _cameraPhotosAllowed = val),
              ),
              const SizedBox(height: CasamaSpacing.md),

              // Permission 3: Contacts (Optional)
              _buildPermissionTile(
                icon: Icons.contacts_outlined,
                iconBg: context.isDark
                    ? CasamaColors.darkTileChat
                    : CasamaColors.tileChat,
                iconColor: const Color(0xFF3949AB),
                title: 'Contacts Assistance',
                badge: 'Optional',
                reason: 'Help you quickly share your household invite code (CASA204) directly with roommates from your contact list.',
                value: _contactsAllowed,
                onChanged: (val) => setState(() => _contactsAllowed = val),
              ),
              const SizedBox(height: CasamaSpacing.xl),

              // Action Buttons
              CasamaButton(
                label: 'Save & Continue',
                isPill: true,
                height: 52,
                onPressed: _continue,
              ),
              const SizedBox(height: CasamaSpacing.sm),

              CasamaButton(
                label: 'Skip All for Now',
                style: CasamaButtonStyle.ghost,
                onPressed: _skipAll,
                height: 44,
              ),
              const SizedBox(height: CasamaSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badge,
    required String reason,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: CasamaSpacing.roundedLg,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(CasamaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: badge == 'Recommended'
                                  ? (isDark
                                        ? const Color(0xFF1B382B)
                                        : CasamaColors.successBg)
                                  : (isDark
                                        ? CasamaColors.darkSurface
                                        : CasamaColors.softNeutral),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badge == 'Recommended'
                                    ? (isDark
                                          ? const Color(0xFF81C784)
                                          : CasamaColors.successGreen)
                                    : context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: value,
                      activeTrackColor: CasamaColors.primaryCoral,
                      onChanged: onChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
