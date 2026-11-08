import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_button.dart';
import '../household/add_housemate_dialog.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({super.key});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(repositoryProvider).markGroupChatAsRead();
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    ref.read(repositoryProvider).sendChatMessage(text);
    _msgController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
            .sendChatMessage('📷 Photo shared', mediaUrl: base64String);
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

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final messages = repo.groupMessages;
    final meetup = repo.activeMeetUp;

    final members = repo.members;
    final activeCount = members.where((m) => m.isHome).length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () => _showHouseholdMembersSheet(context, repo),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: CasamaColors.midnightNavy,
                  borderRadius: CasamaSpacing.roundedSm,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repo.currentHousehold.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                  Text(
                    '${members.length} members • Online: $activeCount',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.people_alt_outlined, color: context.textColor),
            tooltip: 'View Members',
            onPressed: () => _showHouseholdMembersSheet(context, repo),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat message stream
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  ...messages.map((m) => _buildMessageBubble(m)),

                  const SizedBox(height: 12),

                  // Embedded Meet-up Card in Chat (Matching Screen 7)
                  _buildMeetupCard(meetup),
                ],
              ),
            ),

            // Composer bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: context.textSecondaryColor,
                    ),
                    onPressed: () => _showAttachmentModal(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: context.textColor, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message your housemates...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: context.textMutedColor,
                        ),
                        filled: true,
                        fillColor: context.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: CasamaSpacing.roundedPill,
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: CasamaSpacing.roundedPill,
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: CasamaColors.midnightNavy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isCurrentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: CasamaColors.dustyBlue,
              child: ClipOval(
                child: msg.senderAvatar != null && msg.senderAvatar!.isNotEmpty
                    ? Image.network(
                        msg.senderAvatar!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(
                          msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : Text(
                        msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      msg.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (context.isDark
                              ? CasamaColors.darkSurface
                              : CasamaColors.midnightNavy)
                        : context.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
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
                      if (msg.mediaUrl != null &&
                          (msg.mediaUrl as String).isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              (msg.mediaUrl as String).startsWith('data:image')
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
                                    msg.inviteSpaceName ?? 'Household Code',
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                              ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
                                              : context.textSecondaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tap to copy code',
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
                                            .joinChatSpaceByCode(
                                              msg.inviteCode!,
                                            );
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(msg.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textMutedColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all,
                          size: 14,
                          color: CasamaColors.primaryCoral,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetupCard(MeetUpInvitation meetup) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meet-up Invitation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                    Text(
                      meetup.activity,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CasamaColors.ink,
                      ),
                    ),
                    Text(
                      'Today • 7:00 PM • ${meetup.location}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: CasamaColors.textSecondary,
                ),
                onPressed: () => _showRsvpDialog(context, meetup),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: CasamaColors.borderGray),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Going: ${meetup.goingCount}',
                style: const TextStyle(
                  color: CasamaColors.homeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'Maybe: ${meetup.maybeCount}',
                style: const TextStyle(
                  color: Color(0xFFF57F17),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                "Can't make it: ${meetup.cantMakeCount}",
                style: const TextStyle(
                  color: CasamaColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRsvpDialog(BuildContext context, MeetUpInvitation meetup) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meetup.activity,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Location: ${meetup.location}',
                style: TextStyle(color: context.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Response:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: meetup.currentUserResponse == 'going'
                            ? CasamaColors.homeBg
                            : null,
                      ),
                      onPressed: () {
                        ref.read(repositoryProvider).respondMeetUp('going');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Going 🎉'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: meetup.currentUserResponse == 'maybe'
                            ? const Color(0xFFFFF8E1)
                            : null,
                      ),
                      onPressed: () {
                        ref.read(repositoryProvider).respondMeetUp('maybe');
                        Navigator.pop(ctx);
                      },
                      child: const Text('Maybe 🤔'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(repositoryProvider)
                            .respondMeetUp('cant_make_it');
                        Navigator.pop(ctx);
                      },
                      child: const Text("Can't 😅"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAttachmentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
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
                    'Post code card to group chat for roommates to copy',
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
                        .shareInviteCodeToGroupChat(
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
                      'Post a custom space code to invite housemates',
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.celebration_outlined,
                    color: CasamaColors.primaryCoral,
                  ),
                  title: Text(
                    'Propose Meet-up Activity',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/create-meetup');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.casino_outlined,
                    color: CasamaColors.deepTeal,
                  ),
                  title: Text(
                    'Spin Chore Roulette',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/roulette');
                  },
                ),
              ],
            ),
          ),
        );
      },
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
                        .shareInviteCodeToGroupChat(
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

  void _showHouseholdMembersSheet(BuildContext context, dynamic repo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final members = repo.members;
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${repo.currentHousehold.name} Members (${members.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: CasamaColors.textMuted,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...members.map((m) {
                  final isMe = m.profile.id == repo.currentUser.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: CasamaColors.dustyBlue,
                      child: ClipOval(
                        child:
                            m.profile.avatarUrl != null &&
                                m.profile.avatarUrl!.isNotEmpty
                            ? Image.network(
                                m.profile.avatarUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Text(
                                  m.profile.displayName.isNotEmpty
                                      ? m.profile.displayName[0]
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              )
                            : Text(
                                m.profile.displayName.isNotEmpty
                                    ? m.profile.displayName[0]
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          m.profile.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: CasamaColors.softNeutral,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                color: CasamaColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      m.isHome
                          ? 'At home • ${m.note ?? "Present"}'
                          : 'Away • ${m.note ?? "Out"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: m.isHome
                            ? CasamaColors.homeGreen
                            : CasamaColors.textSecondary,
                      ),
                    ),
                    trailing: !isMe
                        ? IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: CasamaColors.primaryCoral,
                            ),
                            tooltip: 'Direct Message',
                            onPressed: () {
                              Navigator.pop(ctx);
                              final contactKey = m.profile.displayName
                                  .toLowerCase();
                              context.push(
                                '/direct-chat?contact=$contactKey&name=${Uri.encodeComponent(m.profile.displayName)}',
                              );
                            },
                          )
                        : null,
                  );
                }),
                const SizedBox(height: 14),
                CasamaButton(
                  label: 'Add Housemate',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    showAddHousemateDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
