import 'package:health/domain/entities/group_entities.dart';
import 'package:health/domain/repositories/group_repository.dart';

class CreateGroupUseCase {
  const CreateGroupUseCase(this._repository);
  final GroupRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<GroupOperationResult> call({required String name, String? description}) =>
      _repository.createGroup(name: name, description: description);
}

class FetchMyGroupsUseCase {
  const FetchMyGroupsUseCase(this._repository);
  final GroupRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<GroupOperationResult> call() => _repository.fetchMyGroups();
}

class FetchPublicGroupsUseCase {
  const FetchPublicGroupsUseCase(this._repository);
  final GroupRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<GroupOperationResult> call({String? search}) =>
      _repository.fetchPublicGroups(search: search);
}

class JoinGroupUseCase {
  const JoinGroupUseCase(this._repository);
  final GroupRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<GroupOperationResult> call({required String groupId}) =>
      _repository.joinGroup(groupId: groupId);
}

class FetchGroupMembersUseCase {
  const FetchGroupMembersUseCase(this._repository);
  final GroupRepository _repository;

  Future<GroupOperationResult> call({required String groupId}) =>
      _repository.fetchMembers(groupId: groupId);
}

class FetchGroupChallengesUseCase {
  const FetchGroupChallengesUseCase(this._repository);
  final GroupRepository _repository;

  Future<GroupOperationResult> call({required String groupId}) =>
      _repository.fetchChallenges(groupId: groupId);
}

class LeaveGroupUseCase {
  const LeaveGroupUseCase(this._repository);
  final GroupRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<GroupOperationResult> call({required String groupId}) =>
      _repository.leaveGroup(groupId: groupId);
}

class CheckInGroupUseCase {
  const CheckInGroupUseCase(this._repository);
  final GroupRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<GroupOperationResult> call({required String groupId}) =>
      _repository.checkInGroup(groupId: groupId);
}
