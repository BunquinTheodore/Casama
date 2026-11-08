import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/invite_housemate_sheet.dart';
import 'boards_screen.dart';
import 'dashboard_screen.dart';
import '../chat/chat_directory_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    BoardsScreen(),
    SizedBox.shrink(), // Center + Action dummy placeholder
    ChatDirectoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _showQuickActionMenu(context);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _showQuickActionMenu(BuildContext context) {
    final repo = ref.read(repositoryProvider);

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Title, Subtitle and Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions ⚡',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'What would you like to coordinate in ${repo.currentHousehold.name}?',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.textSecondaryColor,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Add a Parcel
                  _buildQuickActionCard(
                    icon: Icons.inventory_2_outlined,
                    iconBg: CasamaColors.tileParcels,
                    iconColor: CasamaColors.primaryCoral,
                    tag: 'PARCELS',
                    title: 'Add a Parcel',
                    subtitle: 'Schedule an expected delivery & set COD payment',
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/parcels?openAdd=true');
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Report an Item
                  _buildQuickActionCard(
                    icon: Icons.search_rounded,
                    iconBg: CasamaColors.tileLostFound,
                    iconColor: CasamaColors.deepTeal,
                    tag: 'LOST & FOUND',
                    title: 'Report an Item',
                    subtitle: 'Post missing belongings or announce found items',
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/lost-found?openPost=true');
                    },
                  ),
                  const SizedBox(height: 10),

                  // 3. Add a Household Task
                  _buildQuickActionCard(
                    icon: Icons.build_outlined,
                    iconBg: CasamaColors.tileMaintenance,
                    iconColor: const Color(0xFF1E88E5),
                    tag: 'CHORES',
                    title: 'Add a Household Task',
                    subtitle:
                        'Assign DIY repairs, landlord fixes, or restock items',
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/maintenance?openAdd=true');
                    },
                  ),
                  const SizedBox(height: 10),

                  // 4. Create a Meet-up
                  _buildQuickActionCard(
                    icon: Icons.celebration_outlined,
                    iconBg: CasamaColors.tileChat,
                    iconColor: const Color(0xFF3949AB),
                    tag: 'SOCIAL',
                    title: 'Create a Meet-up',
                    subtitle:
                        'Bring housemates together for food, study, or bonding',
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/create-meetup');
                    },
                  ),
                  const SizedBox(height: 10),

                  // 5. Invite a Housemate
                  _buildQuickActionCard(
                    icon: Icons.group_add_rounded,
                    iconBg: const Color(0xFFFFECE8),
                    iconColor: CasamaColors.primaryCoral,
                    tag: 'HOUSEHOLD',
                    title: 'Invite a Housemate',
                    subtitle:
                        'Share your Casa 204 invite code with new roommates',
                    onTap: () {
                      Navigator.pop(ctx);
                      showInviteHousemateSheet(
                        context,
                        householdName: repo.currentHousehold.name,
                        inviteCode: repo.currentHousehold.inviteCode,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String tag,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: CasamaSpacing.roundedLg,
        side: BorderSide(color: context.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: CasamaSpacing.roundedLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
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
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? CasamaColors.darkSurface
                                : CasamaColors.softNeutral,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.textMutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final unreadChat = repo.totalUnreadChatCount;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.3 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.grid_view_rounded, 'Boards'),
                _buildCenterPlusButton(),
                _buildNavItem(
                  3,
                  Icons.chat_bubble_rounded,
                  'Chat',
                  badge: unreadChat > 0 ? '$unreadChat' : null,
                ),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    String? badge,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? CasamaColors.primaryCoral
        : (context.isDark
              ? CasamaColors.darkTextSecondary
              : CasamaColors.textMuted);

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: CasamaSpacing.roundedMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: CasamaColors.primaryCoral,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlusButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: CasamaColors.primaryCoral,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CasamaColors.primaryCoral.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
