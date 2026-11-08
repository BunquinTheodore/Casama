import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_button.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  final String contactKey;
  final String? contactName;
  final String? avatarUrl;

  const DirectChatScreen({
    super.key,
    required this.contactKey,
    this.contactName,
    this.avatarUrl,
  });

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(repositoryProvider).sendDirectMessage(widget.contactKey, text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        ref
            .read(repositoryProvider)
            .sendDirectMessage(
              widget.contactKey,
              '📷 Photo attached',
              mediaUrl: base64String,
            );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not attach photo: $e')));
      }
    }
  }

  void _showMediaPickerSheet() {
    final contactName = widget.contactName ?? widget.contactKey;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: CasamaColors.primaryCoral,
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF1E88E5),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.vpn_key_rounded,
                  color: CasamaColors.homeGreen,
                ),
                title: Text(
                  'Share Household Invite Code (${ref.read(repositoryProvider).currentHousehold.inviteCode})',
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Send household code card to $contactName',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  final household = ref
                      .read(repositoryProvider)
                      .currentHousehold;
                  ref
                      .read(repositoryProvider)
                      .shareInviteCodeToDirectChat(
                        contactKey: widget.contactKey,
                        code: household.inviteCode,
                        title: household.name,
                      );
                  _scrollToBottom();
                },
              ),
              if (ref.read(repositoryProvider).chatSpaces.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.groups_outlined,
                    color: CasamaColors.primaryCoral,
                  ),
                  title: Text(
                    'Share Space Code...',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Invite $contactName to a custom chat space',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSelectSpaceToShareSheet(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectSpaceToShareSheet(BuildContext context) {
    final spaces = ref.read(repositoryProvider).chatSpaces;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a Space to Share',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 12),
              ...spaces.map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    s.iconEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(
                    s.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${s.inviteCode} • ${s.memberNames.length} members',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: CasamaColors.primaryCoral,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(repositoryProvider)
                        .shareInviteCodeToDirectChat(
                          contactKey: widget.contactKey,
                          code: s.inviteCode,
                          title: '${s.iconEmoji} ${s.name}',
                        );
                    _scrollToBottom();
                  },
                ),
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
    final isAuthorized = repo.isHousemateAuthorized(widget.contactKey);

    if (!isAuthorized) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          title: const Text('Access Restricted'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_person_outlined,
                  size: 64,
                  color: context.textMutedColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unauthorized Conversation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Private messaging is restricted to verified housemates of ${repo.currentHousehold.name}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                CasamaButton(
                  label: 'Return to Messages',
                  icon: Icons.arrow_back,
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final messages = repo.getDirectMessages(widget.contactKey);

    // Look up contact member info for presence note
    final member = repo.members.firstWhere(
      (m) =>
          m.profile.displayName.toLowerCase().contains(
            widget.contactKey.toLowerCase(),
          ) ||
          m.profile.handle.toLowerCase().contains(
            widget.contactKey.toLowerCase(),
          ),
      orElse: () => repo.members.first,
    );

    final displayName = widget.contactName ?? member.profile.displayName;
    final avatar = widget.avatarUrl ?? member.profile.avatarUrl;
    final isHome = member.isHome;
    final note = member.note ?? (isHome ? 'At home' : 'Away');

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: CasamaColors.borderGray,
                  child: ClipOval(
                    child: avatar != null && avatar.isNotEmpty
                        ? Image.network(
                            avatar,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Text(
                              displayName.isNotEmpty ? displayName[0] : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            displayName.isNotEmpty ? displayName[0] : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isHome
                          ? CasamaColors.homeGreen
                          : CasamaColors.outGray,
                      shape: BoxShape.circle,
                      border: Border.all(color: CasamaColors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 11,
                      color: isHome
                          ? CasamaColors.deepTeal
                          : context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.phone_outlined,
              color: context.textColor,
              size: 22,
            ),
            tooltip: 'Call $displayName',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: context.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      const Icon(
                        Icons.phone_in_talk_rounded,
                        color: CasamaColors.homeGreen,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Call $displayName',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Calling $displayName ($note)...',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('End Call'),
                    ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.textColor, size: 22),
            color: context.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: context.borderColor),
            ),
            onSelected: (val) {
              if (val == 'mute') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notifications muted for $displayName'),
                  ),
                );
              } else if (val == 'clear') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat history cleared')),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 18,
                      color: context.textSecondaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mute Notifications',
                      style: TextStyle(color: context.textColor),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: CasamaColors.errorRed,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Clear History',
                      style: TextStyle(color: CasamaColors.errorRed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages list
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: context.textMutedColor,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Say hi to $displayName! 👋',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep your housemate coordination seamless.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CasamaSpacing.md,
                        vertical: CasamaSpacing.md,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildChatBubble(msg, displayName, avatar);
                      },
                    ),
            ),

            // Bottom input bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CasamaSpacing.md,
                vertical: CasamaSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: CasamaColors.primaryCoral,
                      size: 24,
                    ),
                    tooltip: 'Attach or Take Photo',
                    onPressed: _showMediaPickerSheet,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? CasamaColors.darkSurface
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message $displayName...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: context.textMutedColor,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: CasamaColors.primaryCoral,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    dynamic msg,
    String contactName,
    String? contactAvatar,
  ) {
    final isMe = msg.isCurrentUser;
    final timeStr =
        '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: CasamaColors.borderGray,
              child: ClipOval(
                child: contactAvatar != null && contactAvatar.isNotEmpty
                    ? Image.network(
                        contactAvatar,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(
                          contactName.isNotEmpty ? contactName[0] : '?',
                          style: const TextStyle(fontSize: 10),
                        ),
                      )
                    : Text(
                        contactName.isNotEmpty ? contactName[0] : '?',
                        style: const TextStyle(fontSize: 10),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? CasamaColors.primaryCoral : context.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (msg.mediaUrl != null &&
                      (msg.mediaUrl as String).isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (msg.mediaUrl as String).startsWith('data:image')
                          ? Image.memory(
                              base64Decode(
                                (msg.mediaUrl as String).split(',').last,
                              ),
                              width: 200,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              msg.mediaUrl as String,
                              width: 200,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image, size: 40),
                            ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (msg.inviteCode != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.15)
                            : (context.isDark
                                  ? CasamaColors.darkBackground
                                  : CasamaColors.softNeutral),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.3)
                              : context.borderColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.vpn_key_rounded,
                                size: 16,
                                color: CasamaColors.primaryCoral,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                msg.inviteSpaceName ?? 'Invite Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isMe
                                      ? Colors.white
                                      : context.textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.inviteCode!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: isMe
                                  ? Colors.white
                                  : CasamaColors.primaryCoral,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: msg.inviteCode!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Copied code "${msg.inviteCode}"!',
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 13,
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : context.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy code',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe
                                            ? Colors.white.withValues(
                                                alpha: 0.8,
                                              )
                                            : context.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (msg.inviteCode!.startsWith('SPC-')) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    final space = ref
                                        .read(repositoryProvider)
                                        .joinChatSpaceByCode(msg.inviteCode!);
                                    if (space != null) {
                                      context.push(
                                        '/space-chat?id=${space.id}',
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white
                                          : CasamaColors.primaryCoral,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Join Space',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isMe
                                            ? CasamaColors.primaryCoral
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      msg.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : context.textColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : CasamaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
