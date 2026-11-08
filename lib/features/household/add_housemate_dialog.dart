import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_button.dart';

/// Shows the Add Housemate modal dialog with search, code sharing, and pending invitation management.
void showAddHousemateDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _AddHousemateSheet(),
  );
}

class _AddHousemateSheet extends ConsumerStatefulWidget {
  const _AddHousemateSheet();

  @override
  ConsumerState<_AddHousemateSheet> createState() => _AddHousemateSheetState();
}

class _AddHousemateSheetState extends ConsumerState<_AddHousemateSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final pendingInvites = repo.invitations
        .where((i) => i.status == InvitationStatus.pending)
        .toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CasamaColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? CasamaColors.darkTileParcels
                              : CasamaColors.tileParcels,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: CasamaColors.primaryCoral,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Housemate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          Text(
                            'Connect roommates to ${repo.currentHousehold.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.textMutedColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab bar for options
            TabBar(
              controller: _tabController,
              indicatorColor: CasamaColors.primaryCoral,
              indicatorWeight: 3,
              labelColor: CasamaColors.primaryCoral,
              unselectedLabelColor: context.textSecondaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                const Tab(text: 'Find User'),
                const Tab(text: 'Invite Code'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pending'),
                      if (pendingInvites.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: CasamaColors.primaryCoral,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${pendingInvites.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 1, color: context.borderColor),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchTab(repo),
                  _buildCodeTab(repo),
                  _buildPendingTab(repo, pendingInvites),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Search Users Tab
  Widget _buildSearchTab(dynamic repo) {
    final searchResults = repo.searchUsers(_searchQuery);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by username or handle (e.g. @miguel)...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: CasamaColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: CasamaColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: CasamaColors.softNeutral,
              border: OutlineInputBorder(
                borderRadius: CasamaSpacing.roundedLg,
                borderSide: const BorderSide(color: CasamaColors.borderGray),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Privacy note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: CasamaSpacing.roundedSm,
              border: Border.all(color: context.borderColor),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: CasamaColors.primaryCoral,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Household membership requires an invite. Search does not expose private room data.',
                    style: TextStyle(
                      fontSize: 11,
                      color: CasamaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search results
          Expanded(
            child: _searchQuery.trim().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_search_outlined,
                          size: 40,
                          color: CasamaColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Search for Housemates',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: CasamaColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try searching "@miguel", "@clara", or "@bea"',
                          style: TextStyle(
                            fontSize: 12,
                            color: CasamaColors.textMuted.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : searchResults.isEmpty
                ? Center(
                    child: Text(
                      'No Casama users found matching "$_searchQuery"',
                      style: const TextStyle(
                        color: CasamaColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: searchResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final UserProfile user = searchResults[index];
                      final bool isAlreadyInvited = repo.invitations.any(
                        (inv) =>
                            inv.inviteeEmailOrHandle.toLowerCase() ==
                                user.handle.toLowerCase() &&
                            inv.status == InvitationStatus.pending,
                      );

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: CasamaColors.dustyBlue,
                          child: ClipOval(
                            child:
                                user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    user.avatarUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName[0]
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0]
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                        title: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          user.handle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CasamaColors.textSecondary,
                          ),
                        ),
                        trailing: isAlreadyInvited
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: CasamaColors.softNeutral,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Invited',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: CasamaColors.textMuted,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.send_rounded, size: 14),
                                label: const Text(
                                  'Invite',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CasamaColors.midnightNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  final sent = repo.sendInvitation(
                                    inviteeEmailOrHandle: user.handle,
                                    inviteeName: user.displayName,
                                  );
                                  if (sent) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Invitation sent to ${user.displayName} (${user.handle})!',
                                        ),
                                        backgroundColor:
                                            CasamaColors.midnightNavy,
                                      ),
                                    );
                                    setState(() {});
                                  }
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 2. Household Invite Code Tab
  Widget _buildCodeTab(dynamic repo) {
    final inviteCode = repo.currentHousehold.inviteCode;
    final householdName = repo.currentHousehold.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.vpn_key_rounded,
            size: 40,
            color: CasamaColors.primaryCoral,
          ),
          const SizedBox(height: 10),
          Text(
            'Join Code for $householdName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CasamaColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share this code with your housemates. They can enter it during setup to instantly join.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: CasamaColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: CasamaColors.softNeutral,
              borderRadius: CasamaSpacing.roundedLg,
              border: Border.all(color: CasamaColors.borderGray),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  inviteCode,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: CasamaColors.midnightNavy,
                  ),
                ),
                const SizedBox(width: 14),
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
          ),
          const SizedBox(height: 20),

          CasamaButton(
            label: 'Copy Invitation Message',
            icon: Icons.share_rounded,
            onPressed: () {
              final message =
                  'Hey! Join our household "$householdName" on Casama using invite code: $inviteCode. Download the app to coordinate deliveries, chores, and housemate plans!';
              Clipboard.setData(ClipboardData(text: message));
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
        ],
      ),
    );
  }

  // 3. Pending Invitations Tab (Accept / Decline)
  Widget _buildPendingTab(
    dynamic repo,
    List<HouseholdInvitation> pendingInvites,
  ) {
    if (pendingInvites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: CasamaColors.textMuted,
            ),
            const SizedBox(height: 10),
            const Text(
              'No Pending Invitations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: CasamaColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'All household invites have been accepted or processed.',
              style: TextStyle(fontSize: 12, color: CasamaColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pendingInvites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final inv = pendingInvites[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CasamaColors.cardSurface,
            borderRadius: CasamaSpacing.roundedLg,
            border: Border.all(color: CasamaColors.borderGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.inviteeName ?? inv.inviteeEmailOrHandle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: CasamaColors.ink,
                          ),
                        ),
                        Text(
                          '${inv.inviteeEmailOrHandle} • Invited by ${inv.inviterName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CasamaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: CasamaColors.tileParcels,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CasamaColors.primaryCoral,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Accept Button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: CasamaColors.homeGreen,
                      ),
                      label: const Text(
                        'Accept',
                        style: TextStyle(
                          color: CasamaColors.homeGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CasamaColors.homeGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        repo.acceptInvitation(inv.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${inv.inviteeName ?? inv.inviteeEmailOrHandle} joined the household! 🎉',
                            ),
                            backgroundColor: CasamaColors.successGreen,
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Decline Button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: CasamaColors.textSecondary,
                      ),
                      label: const Text(
                        'Decline',
                        style: TextStyle(
                          color: CasamaColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CasamaColors.borderGray),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        repo.declineInvitation(inv.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Declined invitation for ${inv.inviteeEmailOrHandle}.',
                            ),
                            backgroundColor: CasamaColors.midnightNavy,
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
