/// Casama Core Data Models
library;

class UserProfile {
  final String id;
  final String displayName;
  final String handle;
  final String? fullName;
  final String? nickname;
  final int? age;
  final String? avatarUrl;
  final bool hasConsentedTerms;
  final bool hasCompletedOnboarding;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.handle,
    this.fullName,
    this.nickname,
    this.age,
    this.avatarUrl,
    this.hasConsentedTerms = false,
    this.hasCompletedOnboarding = false,
  });

  /// Sensible fallback for user greeting throughout the app (uses nickname if available)
  String get effectiveGreetingName {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return nickname!.trim();
    }
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim().split(' ').first;
    }
    if (displayName.trim().isNotEmpty) {
      return displayName.trim().split(' ').first;
    }
    return 'Kasama';
  }

  /// Default avatar fallback when none provided
  String get effectiveAvatarUrl {
    return avatarUrl ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Housemate',
      handle: json['handle'] as String? ?? '@member',
      fullName: json['full_name'] as String?,
      nickname: json['nickname'] as String?,
      age: json['age'] as int?,
      avatarUrl: json['avatar_url'] as String?,
      hasConsentedTerms: json['has_consented_terms'] as bool? ?? false,
      hasCompletedOnboarding:
          json['has_completed_onboarding'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'handle': handle,
    'full_name': fullName,
    'nickname': nickname,
    'age': age,
    'avatar_url': avatarUrl,
    'has_consented_terms': hasConsentedTerms,
    'has_completed_onboarding': hasCompletedOnboarding,
  };
}

class Household {
  final String id;
  final String name;
  final String inviteCode;
  final String? createdBy;

  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.createdBy,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String?,
    );
  }
}

enum InvitationStatus { pending, accepted, declined }

class HouseholdInvitation {
  final String id;
  final String householdId;
  final String householdName;
  final String inviterName;
  final String inviteeEmailOrHandle;
  final String? inviteeName;
  final InvitationStatus status;
  final DateTime createdAt;

  const HouseholdInvitation({
    required this.id,
    required this.householdId,
    required this.householdName,
    required this.inviterName,
    required this.inviteeEmailOrHandle,
    this.inviteeName,
    this.status = InvitationStatus.pending,
    required this.createdAt,
  });
}

class MemberPresence {
  final UserProfile profile;
  final bool isHome;
  final String? note;
  final DateTime updatedAt;

  const MemberPresence({
    required this.profile,
    required this.isHome,
    this.note,
    required this.updatedAt,
  });
}

enum ParcelPaymentType { paid, cod }

enum ParcelStatus { expected, arrived, received, cancelled }

extension ParcelStatusX on ParcelStatus {
  String get label {
    switch (this) {
      case ParcelStatus.expected:
        return 'Expected';
      case ParcelStatus.arrived:
        return 'Arrived';
      case ParcelStatus.received:
        return 'Received';
      case ParcelStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class ParcelItem {
  final String id;
  final String householdId;
  final String buyerId;
  final String buyerName;
  final String courier;
  final DateTime expectedArrival;
  final ParcelPaymentType paymentType;
  final double? codAmount;
  final String currency;
  final ParcelStatus status;
  final String? notes;
  final List<String> availableMemberNames;
  final bool isAllUnavailable;

  const ParcelItem({
    required this.id,
    required this.householdId,
    required this.buyerId,
    required this.buyerName,
    required this.courier,
    required this.expectedArrival,
    required this.paymentType,
    this.codAmount,
    this.currency = 'PHP',
    required this.status,
    this.notes,
    this.availableMemberNames = const [],
    this.isAllUnavailable = false,
  });
}

enum ItemType { lost, found, shared }

enum ItemStatus { open, unclaimed, claimed, returned }

class LostFoundItem {
  final String id;
  final String householdId;
  final ItemType type;
  final String title;
  final String? description;
  final String? imageUrl;
  final ItemStatus status;
  final String reportedBy;
  final String reportedByName;
  final DateTime createdAt;

  const LostFoundItem({
    required this.id,
    required this.householdId,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    required this.status,
    required this.reportedBy,
    required this.reportedByName,
    required this.createdAt,
  });
}

enum TaskCategory { diy, landlord, restock }

enum TaskUrgency { low, medium, urgent }

enum TaskStatus { open, inProgress, done }

extension TaskUrgencyX on TaskUrgency {
  String get label {
    switch (this) {
      case TaskUrgency.urgent:
        return 'Urgent';
      case TaskUrgency.medium:
        return 'Medium';
      case TaskUrgency.low:
        return 'Low';
    }
  }
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

class MaintenanceTask {
  final String id;
  final String householdId;
  final String title;
  final TaskCategory category;
  final TaskUrgency urgency;
  final TaskStatus status;
  final String? assigneeName;
  final String? assigneeAvatar;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? dueDate;

  const MaintenanceTask({
    required this.id,
    required this.householdId,
    required this.title,
    required this.category,
    required this.urgency,
    required this.status,
    this.assigneeName,
    this.assigneeAvatar,
    required this.createdByName,
    required this.createdAt,
    this.dueDate,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String? mediaUrl;
  final String? inviteCode;
  final String? inviteSpaceName;
  final DateTime createdAt;
  final bool isCurrentUser;
  final bool isRead;
  final MeetUpInvitation? meetUpInvitation;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.mediaUrl,
    this.inviteCode,
    this.inviteSpaceName,
    required this.createdAt,
    required this.isCurrentUser,
    this.isRead = true,
    this.meetUpInvitation,
  });
}

class ChatSpace {
  final String id;
  final String householdId;
  final String name;
  final String description;
  final String inviteCode;
  final String creatorId;
  final String creatorName;
  final List<String> memberNames;
  final String iconEmoji;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  final int unreadCount;

  const ChatSpace({
    required this.id,
    required this.householdId,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.creatorId,
    required this.creatorName,
    required this.memberNames,
    this.iconEmoji = '💬',
    required this.createdAt,
    this.messages = const [],
    this.unreadCount = 0,
  });

  ChatSpace copyWith({
    String? name,
    String? description,
    List<String>? memberNames,
    List<ChatMessage>? messages,
    int? unreadCount,
  }) {
    return ChatSpace(
      id: id,
      householdId: householdId,
      name: name ?? this.name,
      description: description ?? this.description,
      inviteCode: inviteCode,
      creatorId: creatorId,
      creatorName: creatorName,
      memberNames: memberNames ?? this.memberNames,
      iconEmoji: iconEmoji,
      createdAt: createdAt,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class MeetUpInvitation {
  final String id;
  final String activity;
  final String location;
  final DateTime scheduledTime;
  final int goingCount;
  final int maybeCount;
  final int cantMakeCount;
  final String? currentUserResponse; // 'going', 'maybe', 'cant_make_it'

  const MeetUpInvitation({
    required this.id,
    required this.activity,
    required this.location,
    required this.scheduledTime,
    this.goingCount = 0,
    this.maybeCount = 0,
    this.cantMakeCount = 0,
    this.currentUserResponse,
  });
}

class PointAuditEntry {
  final String id;
  final String title;
  final int points;
  final DateTime timestamp;
  final String category; // 'parcel', 'task', 'lost_found', 'bonus'

  const PointAuditEntry({
    required this.id,
    required this.title,
    required this.points,
    required this.timestamp,
    required this.category,
  });
}

class NotificationPreferences {
  final bool householdUpdates;
  final bool parcelNotifications;
  final bool taskReminders;
  final bool chatNotifications;

  const NotificationPreferences({
    this.householdUpdates = true,
    this.parcelNotifications = true,
    this.taskReminders = true,
    this.chatNotifications = true,
  });

  NotificationPreferences copyWith({
    bool? householdUpdates,
    bool? parcelNotifications,
    bool? taskReminders,
    bool? chatNotifications,
  }) {
    return NotificationPreferences(
      householdUpdates: householdUpdates ?? this.householdUpdates,
      parcelNotifications: parcelNotifications ?? this.parcelNotifications,
      taskReminders: taskReminders ?? this.taskReminders,
      chatNotifications: chatNotifications ?? this.chatNotifications,
    );
  }
}
