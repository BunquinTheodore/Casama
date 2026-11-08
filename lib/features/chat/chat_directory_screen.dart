import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_avatar.dart';
import '../../shared/widgets/casama_button.dart';
import '../household/add_housemate_dialog.dart';

class ChatDirectoryScreen extends ConsumerStatefulWidget {
  const ChatDirectoryScreen({super.key});

  @override
  ConsumerState<ChatDirectoryScreen> createState() =>
      _ChatDirectoryScreenState();
}

class _ChatDirectoryScreenState extends ConsumerState<ChatDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final meetup = repo.activeMeetUp;
    final otherMembers = repo.members
        .where((m) => m.profile.id != repo.currentUser.id)
        .toList();

    // Group chat details
    final groupLastMsg = repo.groupMessages.isNotEmpty
        ? repo.groupMessages.last
        : null;
    final groupPreview = groupLastMsg?.content ?? "Let's plan for the meetup!";
    final groupTime = groupLastMsg != null
        ? DateFormat('h:mm a').format(groupLastMsg.createdAt)
        : '8:24 PM';

    // Search filtering
    final query = _searchQuery.trim().toLowerCase();
    final bool matchesGroup =
        query.isEmpty ||
        repo.currentHousehold.name.toLowerCase().contains(query) ||
        groupPreview.toLowerCase().contains(query);

    final filteredSpaces = repo.chatSpaces.where((s) {
      if (query.isEmpty) return true;
      final name = s.name.toLowerCase();
      final desc = s.description.toLowerCase();
      final code = s.inviteCode.toLowerCase();
      final lastMsg = s.messages.lastOrNull?.content.toLowerCase() ?? '';
      return name.contains(query) ||
          desc.contains(query) ||
          code.contains(query) ||
          lastMsg.contains(query);
    }).toList();

    final filteredMembers = otherMembers.where((m) {
      if (query.isEmpty) return true;
      final name = m.profile.displayName.toLowerCase();
      final handle = m.profile.handle.toLowerCase();
      final note = (m.note ?? '').toLowerCase();
      final lastMsg = repo
          .getDirectMessages(m.profile.displayName.toLowerCase())
          .lastOrNull;
      final msgContent = (lastMsg?.content ?? '').toLowerCase();
      return name.contains(query) ||
          handle.contains(query) ||
          note.contains(query) ||
          msgContent.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
              color: CasamaColors.primaryCoral,
            ),
            tooltip: 'Add Housemate',
            onPressed: () => showAddHousemateDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.edit_square, color: context.textColor),
            tooltip: 'Create Meet-up',
            onPressed: () => context.push('/create-meetup'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.lg),
        children: [
          const SizedBox(height: CasamaSpacing.xs),

          // Search Bar
          TextField(
            controller: _searchController,
            style: TextStyle(color: context.textColor, fontSize: 14),
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search conversations or housemates...',
              hintStyle: TextStyle(fontSize: 13, color: context.textMutedColor),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: context.textSecondaryColor,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: context.textSecondaryColor,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.cardColor,
              border: OutlineInputBorder(
                borderRadius: CasamaSpacing.roundedPill,
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: CasamaSpacing.roundedPill,
                borderSide: BorderSide(color: context.borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: CasamaSpacing.md),

          // Pinned Household Group Chat Section
          if (matchesGroup) ...[
            Text(
              'Household Group Chat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 6),
            _ChatListItem(
              isGroup: true,
              title: repo.currentHousehold.name,
              preview: groupPreview,
              time: groupTime,
              unreadCount: repo.groupChatUnreadCount,
              onTap: () {
                ref.read(repositoryProvider).markGroupChatAsRead();
                context.push('/group-chat');
              },
            ),
            const SizedBox(height: CasamaSpacing.lg),
          ],

          // Custom Chat Spaces Section
          if (filteredSpaces.isNotEmpty || query.isEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Custom Chat Spaces',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? CasamaColors.darkSurface
                            : CasamaColors.softNeutral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${repo.chatSpaces.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.vpn_key_rounded,
                        size: 14,
                        color: CasamaColors.primaryCoral,
                      ),
                      label: const Text(
                        'Join Code',
                        style: TextStyle(
                          color: CasamaColors.primaryCoral,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => _showJoinWithCodeDialog(context),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 14,
                        color: CasamaColors.deepTeal,
                      ),
                      label: const Text(
                        '+ Space',
                        style: TextStyle(
                          color: CasamaColors.deepTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => _showCreateSpaceDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (filteredSpaces.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: CasamaSpacing.roundedLg,
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: CasamaColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No chat spaces yet. Create one or join with a code!',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredSpaces.map((s) {
                final lastMsg = s.messages.lastOrNull;
                final preview = lastMsg != null
                    ? (lastMsg.isCurrentUser
                          ? 'You: ${lastMsg.content}'
                          : '${lastMsg.senderName}: ${lastMsg.content}')
                    : s.description;
                final timeStr = lastMsg != null
                    ? DateFormat('h:mm a').format(lastMsg.createdAt)
                    : DateFormat('h:mm a').format(s.createdAt);

                return _ChatListItem(
                  isSpace: true,
                  iconEmoji: s.iconEmoji,
                  title: s.name,
                  preview: preview,
                  time: timeStr,
                  codeTag: s.inviteCode,
                  memberCount: s.memberNames.length,
                  unreadCount: s.unreadCount,
                  onTap: () {
                    ref.read(repositoryProvider).markSpaceChatAsRead(s.id);
                    context.push('/space-chat?id=${s.id}');
                  },
                );
              }),
            const SizedBox(height: CasamaSpacing.lg),
          ],

          // Section 2: Individual Conversations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Individual Conversations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: context.textSecondaryColor,
                ),
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 16,
                  color: CasamaColors.primaryCoral,
                ),
                label: const Text(
                  'Add Housemate',
                  style: TextStyle(
                    color: CasamaColors.primaryCoral,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => showAddHousemateDialog(context),
              ),
            ],
          ),
          const SizedBox(height: CasamaSpacing.xs),

          // Empty state when user has no other housemates
          if (otherMembers.isEmpty)
            _buildEmptyHousematesState(context)
          else if (filteredMembers.isEmpty && _searchQuery.isNotEmpty)
            _buildNoSearchResultsState()
          else
            ...filteredMembers.map((m) {
              final contactKey = m.profile.displayName.toLowerCase();
              final dmMessages = repo.getDirectMessages(contactKey);
              final lastMsg = dmMessages.isNotEmpty ? dmMessages.last : null;
              final preview = lastMsg != null
                  ? (lastMsg.isCurrentUser
                        ? 'You: ${lastMsg.content}'
                        : lastMsg.content)
                  : (m.note != null
                        ? 'Status: ${m.note}'
                        : 'Tap to message ${m.profile.displayName}');
              final timeStr = lastMsg != null
                  ? DateFormat('h:mm a').format(lastMsg.createdAt)
                  : DateFormat('h:mm a').format(m.updatedAt);

              return _ChatListItem(
                title: m.profile.displayName,
                preview: preview,
                time: timeStr,
                avatarUrl: m.profile.avatarUrl,
                isHome: m.isHome,
                note: m.note,
                onTap: () => context.push(
                  '/direct-chat?contact=$contactKey&name=${Uri.encodeComponent(m.profile.displayName)}&avatar=${Uri.encodeComponent(m.profile.avatarUrl ?? '')}',
                ),
              );
            }),

          const SizedBox(height: CasamaSpacing.xl),

          // Section 3: Meet-up Invitations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meet-up Invitations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: context.textSecondaryColor,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/create-meetup'),
                child: const Text(
                  '+ New',
                  style: TextStyle(
                    color: CasamaColors.primaryCoral,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CasamaSpacing.xs),

          // Meet-up Quick Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: CasamaSpacing.roundedLg,
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? CasamaColors.darkTileChat
                        : const Color(0xFFE8F1F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: CasamaColors.deepTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.activity,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${meetup.location} • ${meetup.goingCount} going',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDark
                        ? context.surfaceColor
                        : CasamaColors.softNeutral,
                    foregroundColor: context.textColor,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => context.push('/group-chat'),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: CasamaSpacing.xxl),
        ],
      ),
    );
  }

  // Helpful empty state for new users with no housemates yet
  Widget _buildEmptyHousematesState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.isDark
                  ? CasamaColors.darkTileParcels
                  : CasamaColors.tileParcels,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add_rounded,
              color: CasamaColors.primaryCoral,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your household is better together! 🏡',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CasamaColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Invite your housemates to start communicating and coordinating.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: CasamaColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          CasamaButton(
            label: 'Invite Housemate',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () => showAddHousemateDialog(context),
            height: 46,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 36,
            color: CasamaColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'No conversations found matching "$_searchQuery"',
            style: const TextStyle(
              fontSize: 13,
              color: CasamaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSpaceDialog(BuildContext context) {
    final repo = ref.read(repositoryProvider);
    final otherMembers = repo.members
        .where((m) => m.profile.id != repo.currentUser.id)
        .toList();

    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '🛒';
    final selectedMembers = <String>{};

    final emojis = ['🛒', '🧹', '🍿', '📚', '🍕', '💬', '🎮', '🌿'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? CasamaColors.darkSurface
                                  : const Color(0xFFFFECE8),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              selectedEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Chat Space',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                              ),
                              Text(
                                'Generates an invite code & adds housemates',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Emoji picker row
                  Text(
                    'Choose an icon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: emojis.map((emoji) {
                        final isSel = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedEmoji = emoji),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? (context.isDark
                                        ? CasamaColors.darkSurface
                                        : const Color(0xFFFFECE8))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? CasamaColors.primaryCoral
                                    : context.borderColor,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Space Name field
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Space Name',
                      hintText: 'e.g. Grocery & Supplies',
                      filled: true,
                      fillColor: context.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: CasamaSpacing.roundedMd,
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: CasamaSpacing.roundedMd,
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description field
                  TextField(
                    controller: descController,
                    style: TextStyle(color: context.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Description / Purpose',
                      hintText:
                          'e.g. Shopping lists, shared bills & food requests',
                      filled: true,
                      fillColor: context.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: CasamaSpacing.roundedMd,
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: CasamaSpacing.roundedMd,
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Creator can add housemates directly
                  if (otherMembers.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Housemates Directly:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          '${selectedMembers.length} selected',
                          style: const TextStyle(
                            fontSize: 11,
                            color: CasamaColors.primaryCoral,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...otherMembers.map((m) {
                      final name = m.profile.displayName;
                      final isChecked = selectedMembers.contains(name);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: isChecked,
                        activeColor: CasamaColors.primaryCoral,
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textColor,
                          ),
                        ),
                        subtitle: Text(
                          m.profile.handle,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        secondary: CasamaAvatar(
                          avatarUrl: m.profile.avatarUrl,
                          radius: 16,
                          name: name,
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              selectedMembers.add(name);
                            } else {
                              selectedMembers.remove(name);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // Create button
                  CasamaButton(
                    label: 'Create Space & Generate Code',
                    icon: Icons.check_circle_outline,
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a space name.'),
                          ),
                        );
                        return;
                      }
                      final desc = descController.text.trim();
                      final newSpace = ref
                          .read(repositoryProvider)
                          .createChatSpace(
                            name: name,
                            description: desc.isNotEmpty
                                ? desc
                                : 'Household Chat Space',
                            iconEmoji: selectedEmoji,
                            initialMembers: selectedMembers.toList(),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Space "${newSpace.name}" created! Code: ${newSpace.inviteCode}',
                          ),
                          backgroundColor: CasamaColors.midnightNavy,
                        ),
                      );
                      context.push('/space-chat?id=${newSpace.id}');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJoinWithCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFECE8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: CasamaColors.primaryCoral,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join Space with Code',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          'Enter a code shared by your housemate',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. SPC-101 or CASA204',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1,
                      color: context.textMutedColor,
                      fontWeight: FontWeight.normal,
                    ),
                    errorText: errorText,
                    suffixIcon: TextButton(
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data != null && data.text != null) {
                          codeController.text = data.text!.trim().toUpperCase();
                          setModalState(() => errorText = null);
                        }
                      },
                      child: const Text(
                        'PASTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: CasamaColors.primaryCoral,
                        ),
                      ),
                    ),
                    filled: true,
                    fillColor: context.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: CasamaSpacing.roundedMd,
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: CasamaSpacing.roundedMd,
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CasamaButton(
                  label: 'Join Space',
                  icon: Icons.login_rounded,
                  onPressed: () {
                    final code = codeController.text.trim().toUpperCase();
                    if (code.isEmpty) {
                      setModalState(
                        () => errorText = 'Please enter an invite code.',
                      );
                      return;
                    }
                    final repo = ref.read(repositoryProvider);
                    // Check if it's the household code
                    if (code ==
                        repo.currentHousehold.inviteCode.toUpperCase()) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You are already a verified member of ${repo.currentHousehold.name}!',
                          ),
                        ),
                      );
                      context.push('/group-chat');
                      return;
                    }

                    final joinedSpace = repo.joinChatSpaceByCode(code);
                    if (joinedSpace != null) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Joined "${joinedSpace.name}"! 🎉'),
                          backgroundColor: CasamaColors.midnightNavy,
                        ),
                      );
                      context.push('/space-chat?id=${joinedSpace.id}');
                    } else {
                      setModalState(() {
                        errorText =
                            'No space found with code "$code". Check and retry.';
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final String title;
  final String preview;
  final String time;
  final String? avatarUrl;
  final bool isGroup;
  final bool isSpace;
  final String? iconEmoji;
  final String? codeTag;
  final int? memberCount;
  final bool isHome;
  final String? note;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.title,
    required this.preview,
    required this.time,
    this.avatarUrl,
    this.isGroup = false,
    this.isSpace = false,
    this.iconEmoji,
    this.codeTag,
    this.memberCount,
    this.isHome = false,
    this.note,
    this.unreadCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: CasamaSpacing.roundedLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Avatar, Group House Icon, or Space Emoji Icon
            if (isGroup)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CasamaColors.midnightNavy,
                  borderRadius: CasamaSpacing.roundedMd,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              )
            else if (isSpace)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? CasamaColors.darkSurface
                      : const Color(0xFFFFECE8),
                  borderRadius: CasamaSpacing.roundedMd,
                  border: Border.all(
                    color: context.isDark
                        ? context.borderColor
                        : const Color(0xFFFFD5CE),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  iconEmoji ?? '💬',
                  style: const TextStyle(fontSize: 24),
                ),
              )
            else
              Stack(
                children: [
                  CasamaAvatar(avatarUrl: avatarUrl, radius: 24, name: title),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isHome
                            ? CasamaColors.homeGreen
                            : CasamaColors.outGray,
                        shape: BoxShape.circle,
                        border: Border.all(color: CasamaColors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (codeTag != null) ...[
                              const SizedBox(width: 6),
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
                                  border: Border.all(
                                    color: context.borderColor,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  codeTag!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: CasamaColors.primaryCoral,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textMutedColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          memberCount != null
                              ? '$memberCount members • $preview'
                              : preview,
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0
                                ? context.textColor
                                : context.textSecondaryColor,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: CasamaColors.primaryCoral,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
