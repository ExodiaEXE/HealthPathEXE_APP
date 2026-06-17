class GroupRecord {
  const GroupRecord({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberCount,
    this.description,
    this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final int memberCount;
  final String? description;
  final DateTime? createdAt;

  factory GroupRecord.fromJson(Map<String, dynamic> json) => GroupRecord(
        id: (json['id'] as String? ?? '').toLowerCase(),
        name: json['name'] as String? ?? '',
        inviteCode: json['inviteCode'] as String? ?? '',
        memberCount: json['memberCount'] as int? ?? 0,
        description: json['description'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

class GroupMemberRecord {
  const GroupMemberRecord({
    required this.userId,
    required this.name,
    required this.role,
    required this.isCurrentUser,
    required this.weeklyScore,
  });

  final String userId;
  final String name;
  final String role;
  final bool isCurrentUser;
  final int weeklyScore;

  factory GroupMemberRecord.fromJson(Map<String, dynamic> json) =>
      GroupMemberRecord(
        userId: (json['userId'] as String? ?? '').toLowerCase(),
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'Member',
        isCurrentUser: json['isCurrentUser'] == true,
        weeklyScore: json['weeklyScore'] as int? ?? 0,
      );

  String get avatar => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

class GroupChallengeRecord {
  const GroupChallengeRecord({
    required this.id,
    required this.groupId,
    required this.title,
    required this.isActive,
    this.description,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String groupId;
  final String title;
  final bool isActive;
  final String? description;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory GroupChallengeRecord.fromJson(Map<String, dynamic> json) =>
      GroupChallengeRecord(
        id: (json['id'] as String? ?? '').toLowerCase(),
        groupId: (json['groupId'] as String? ?? '').toLowerCase(),
        title: json['title'] as String? ?? '',
        isActive: json['isActive'] == true,
        description: json['description'] as String?,
        startsAt: json['startsAt'] != null
            ? DateTime.tryParse(json['startsAt'] as String)
            : null,
        endsAt: json['endsAt'] != null
            ? DateTime.tryParse(json['endsAt'] as String)
            : null,
      );
}

class GroupOperationResult {
  const GroupOperationResult({
    required this.success,
    this.message,
    this.group,
    this.groups,
    this.members,
    this.challenges,
    this.groupDeleted = false,
  });

  final bool success;
  final String? message;
  final GroupRecord? group;
  final List<GroupRecord>? groups;
  final List<GroupMemberRecord>? members;
  final List<GroupChallengeRecord>? challenges;
  final bool groupDeleted;

  factory GroupOperationResult.fail(String message) =>
      GroupOperationResult(success: false, message: message);
}
