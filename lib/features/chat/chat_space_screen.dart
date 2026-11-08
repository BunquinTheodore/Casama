import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';

class ChatSpaceScreen extends ConsumerStatefulWidget {
  final String spaceId;

  const ChatSpaceScreen({super.key, required this.spaceId});

  @override
  ConsumerState<ChatSpaceScreen> createState() => _ChatSpaceScreenState();
}

class _ChatSpaceScreenState extends ConsumerState<ChatSpaceScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(repositoryProvider).markSpaceChatAsRead(widget.spaceId);
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    ref.read(repositoryProvider).sendSpaceMessage(widget.spaceId, text);
    _msgController.clear();
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

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        ref
            .read(repositoryProvider)
            .sendSpaceMessage(
              widget.spaceId,
              '📷 Photo shared',
              mediaUrl: base64String,
            );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not attach image: $e')));
      }
    }
  }

  void _shareSpaceCode(ChatSpace space) {
    ref
        .read(repositoryProvider)
        .sendSpaceMessage(
          widget.spaceId,
          '🔑 Space Invitation Code: ${space.inviteCode}',
          inviteCode: space.inviteCode,
          inviteSpaceName: space.name,
        );
    _scrollToBottom();
  }

  void _showAttachmentMenu(BuildContext context, ChatSpace space) {
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
              const SizedBox(height: 14),
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
                  _pickAndSendPhoto(ImageSource.camera);
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
                  _pickAndSendPhoto(ImageSource.gallery);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.vpn_key_rounded,
                  color: CasamaColors.homeGreen,
                ),
                title: Text(
                  'Share Space Invite Code (${space.inviteCode})',
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Share into this space so members can invite other housemates',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareSpaceCode(space);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpaceInfoSheet(BuildContext context, ChatSpace space) {
    final repo = ref.read(repositoryProvider);
    final allHouseholdMembers = repo.members
        .map((m) => m.profile.displayName)
        .toList();
    final nonMembers = allHouseholdMembers
        .where((name) => !space.memberNames.contains(name))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentSpace = ref
              .watch(repositoryProvider)
              .chatSpaces
              .firstWhere((s) => s.id == widget.spaceId, orElse: () => space);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? CasamaColors.darkSurface
                              : CasamaColors.tileChat,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          currentSpace.iconEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSpace.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            Text(
                              'Created by ${currentSpace.creatorName} • ${currentSpace.memberNames.length} members',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (currentSpace.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      currentSpace.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Space Invite Code Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? CasamaColors.darkSurface
                          : CasamaColors.softNeutral,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'SPACE INVITATION CODE',
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
                              currentSpace.inviteCode,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                color: context.textColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: CasamaColors.primaryCoral,
                                size: 20,
                              ),
                              tooltip: 'Copy Code',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: currentSpace.inviteCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Copied space code "${currentSpace.inviteCode}" to clipboard!',
                                    ),
                                    backgroundColor: CasamaColors.midnightNavy,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                          'Housemates can enter this code in Chat to join instantly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Member list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Space Members (${currentSpace.memberNames.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      if (nonMembers.isNotEmpty)
                        Text(
                          '${nonMembers.length} available to add',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: currentSpace.memberNames.map((name) {
                      return Chip(
                        backgroundColor: context.cardColor,
                        side: BorderSide(color: context.borderColor),
                        avatar: CircleAvatar(
                          backgroundColor: CasamaColors.primaryCoral,
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        label: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Creator can add directly
                  if (nonMembers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Add Housemates Directly:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...nonMembers.map((name) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: context.tileChatColor,
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textColor,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CasamaColors.midnightNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text(
                            'Add',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            ref
                                .read(repositoryProvider)
                                .addMemberToSpace(currentSpace.id, name);
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added $name to ${currentSpace.name}!',
                                ),
                                backgroundColor: CasamaColors.midnightNavy,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final space = repo.chatSpaces.firstWhere(
      (s) => s.id == widget.spaceId,
      orElse: () => repo.chatSpaces.isNotEmpty
          ? repo.chatSpaces.first
          : ChatSpace(
              id: 'none',
              householdId: '',
              name: 'Space',
              description: '',
              inviteCode: '',
              creatorId: '',
              creatorName: '',
              memberNames: const [],
              createdAt: DateTime(2026, 1, 1),
            ),
    );

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => _showSpaceInfoSheet(context, space),
          child: Row(
            children: [
              Text(space.iconEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${space.memberNames.length} members • Code: ${space.inviteCode}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: context.textColor),
            tooltip: 'Space Details & Code',
            onPressed: () => _showSpaceInfoSheet(context, space),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: space.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            space.iconEmoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome to ${space.name}!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share updates or invite housemates using code ${space.inviteCode}',
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
                      itemCount: space.messages.length,
                      itemBuilder: (context, index) {
                        final msg = space.messages[index];
                        return _buildSpaceMessageBubble(msg);
                      },
                    ),
            ),

            // Composer bar
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
                      Icons.add_circle_outline_rounded,
                      color: CasamaColors.primaryCoral,
                      size: 24,
                    ),
                    tooltip: 'Attach photo or Share code',
                    onPressed: () => _showAttachmentMenu(context, space),
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
                        controller: _msgController,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message in ${space.name}...',
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
                      color: CasamaColors.midnightNavy,
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

  Widget _buildSpaceMessageBubble(ChatMessage msg) {
    final isMe = msg.isCurrentUser;
    final timeStr = DateFormat('h:mm a').format(msg.createdAt);

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
              child: Text(
                msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? (context.isDark
                          ? CasamaColors.darkSurface
                          : CasamaColors.midnightNavy)
                    : context.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? (context.isDark
                          ? Border.all(color: context.borderColor)
                          : null)
                    : Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      msg.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CasamaColors.primaryCoral,
                      ),
                    ),
                  if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: msg.mediaUrl!.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(msg.mediaUrl!.split(',').last),
                              width: 200,
                              height: 140,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              msg.mediaUrl!,
                              width: 200,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // If sharing invitation code card
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
                                  'Tap to copy code',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : context.textMutedColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 13,
                          color: msg.isRead
                              ? CasamaColors.primaryCoral
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
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
