import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/domain/entities/group_entities.dart';
import 'package:health/domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({ApiClient? api, TokenStore? storage})
      : _api = api,
        _storage = storage ?? SecureStorageService();

  final ApiClient? _api;
  final TokenStore _storage;

  @override
  bool get isOnline =>
      _api?.hasBaseUrl ?? EnvConfig.apiBaseUrl.isNotEmpty;

  Future<ApiClient?> _authedClient() async {
    if (!isOnline) return null;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return null;
    }
    return _api!.withBearer(token);
  }

  GroupOperationResult _parseGroup(ApiResult res, {String? fallback}) {
    final ok = res.json['success'] == true;
    if (!ok) {
      return GroupOperationResult.fail(
        res.json['message'] as String? ?? fallback ?? 'Thao tác nhóm thất bại.',
      );
    }
    final data = res.json['data'] as Map<String, dynamic>?;
    if (data == null) {
      return const GroupOperationResult(success: true);
    }
    return GroupOperationResult(
      success: true,
      message: res.json['message'] as String?,
      group: GroupRecord.fromJson(data),
    );
  }

  GroupOperationResult _parseGroupList(ApiResult res, {String? fallback}) {
    final ok = res.json['success'] == true;
    if (!ok) {
      return GroupOperationResult.fail(
        res.json['message'] as String? ?? fallback ?? 'Không tải được danh sách nhóm.',
      );
    }
    final list = res.json['data'] as List<dynamic>? ?? [];
    return GroupOperationResult(
      success: true,
      message: res.json['message'] as String?,
      groups: list
          .map((e) => GroupRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<GroupOperationResult> createGroup({
    required String name,
    String? description,
  }) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.postJson('/api/Group', {
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      });
      return _parseGroup(res, fallback: 'Tạo nhóm thất bại.');
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> fetchMyGroups() async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.getJson('/api/Group/my-groups');
      return _parseGroupList(res);
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> fetchPublicGroups({String? search}) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final query = search != null && search.trim().isNotEmpty
          ? '?search=${Uri.encodeQueryComponent(search.trim())}'
          : '';
      final res = await client.getJson('/api/Group/public$query');
      return _parseGroupList(res);
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> joinGroup({required String groupId}) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.postJson('/api/Group/$groupId/join', {});
      final ok = res.json['success'] == true;
      if (!ok) {
        return GroupOperationResult.fail(
          res.json['message'] as String? ?? 'Tham gia nhóm thất bại.',
        );
      }
      final detail = await client.getJson('/api/Group/$groupId');
      return _parseGroup(detail, fallback: 'Tham gia nhóm thất bại.');
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> joinByInviteCode({
    required String inviteCode,
  }) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.postJson('/api/Group/join-by-invite', {
        'inviteCode': inviteCode.trim().toUpperCase(),
      });
      return _parseGroup(res, fallback: 'Mã mời không hợp lệ.');
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> fetchMembers({required String groupId}) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.getJson('/api/Group/$groupId/members');
      final ok = res.json['success'] == true;
      if (!ok) {
        return GroupOperationResult.fail(
          res.json['message'] as String? ?? 'Không tải được thành viên.',
        );
      }
      final list = res.json['data'] as List<dynamic>? ?? [];
      return GroupOperationResult(
        success: true,
        members: list
            .map((e) => GroupMemberRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> fetchChallenges({required String groupId}) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res =
          await client.getJson('/api/GroupChallenge/group/$groupId/challenges');
      final ok = res.json['success'] == true;
      if (!ok) {
        return GroupOperationResult(
          success: true,
          challenges: const [],
        );
      }
      final list = res.json['data'] as List<dynamic>? ?? [];
      return GroupOperationResult(
        success: true,
        challenges: list
            .map((e) =>
                GroupChallengeRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> checkInGroup({required String groupId}) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.postJson('/api/Group/$groupId/check-in', {});
      final ok = res.json['success'] == true;
      if (!ok) {
        return GroupOperationResult.fail(
          res.json['message'] as String? ?? 'Điểm danh nhóm thất bại.',
        );
      }
      return GroupOperationResult(
        success: true,
        message: res.json['message'] as String?,
      );
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<GroupOperationResult> leaveGroup({required String groupId}) async {
    final client = await _authedClient();
    if (client == null) {
      return GroupOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.postJson('/api/Group/$groupId/leave', {});
      final ok = res.json['success'] == true;
      if (!ok) {
        return GroupOperationResult.fail(
          res.json['message'] as String? ?? 'Rời nhóm thất bại.',
        );
      }
      final data = res.json['data'] as Map<String, dynamic>?;
      return GroupOperationResult(
        success: true,
        message: res.json['message'] as String?,
        groupDeleted: data?['groupDeleted'] == true,
      );
    } on ApiException catch (e) {
      return GroupOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }
}
