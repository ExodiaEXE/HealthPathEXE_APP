import 'package:health/domain/entities/group_entities.dart';

abstract class GroupRepository {
  bool get isOnline;

  Future<GroupOperationResult> createGroup({
    required String name,
    String? description,
  });

  Future<GroupOperationResult> fetchMyGroups();

  Future<GroupOperationResult> fetchPublicGroups({String? search});

  Future<GroupOperationResult> joinGroup({required String groupId});

  Future<GroupOperationResult> joinByInviteCode({required String inviteCode});

  Future<GroupOperationResult> fetchMembers({required String groupId});

  Future<GroupOperationResult> fetchChallenges({required String groupId});

  Future<GroupOperationResult> leaveGroup({required String groupId});

  Future<GroupOperationResult> checkInGroup({required String groupId});
}
