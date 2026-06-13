import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/domain/entities/notification_entities.dart';
import 'package:health/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({ApiClient? api, TokenStore? storage})
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

  NotificationOperationResult _fail(ApiResult res, String fallback) {
    return NotificationOperationResult.fail(
      res.json['message'] as String? ?? fallback,
    );
  }

  @override
  Future<NotificationOperationResult> fetchNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final unread = unreadOnly ? '&unreadOnly=true' : '';
      final res = await client.getJson(
        '/api/Notification?page=$page&pageSize=$pageSize$unread',
      );
      if (res.json['success'] != true) {
        return _fail(res, 'Không tải được thông báo.');
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];
      return NotificationOperationResult(
        success: true,
        notifications: items
            .map((e) =>
                NotificationRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalItems: data['totalItems'] as int? ?? items.length,
      );
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> getUnreadCount() async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.getJson('/api/Notification/unread-count');
      if (res.json['success'] != true) {
        return _fail(res, 'Không tải được số thông báo.');
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      return NotificationOperationResult(
        success: true,
        unreadCount: data['unreadCount'] as int? ?? 0,
      );
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> markAsRead(String id) async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.putJson('/api/Notification/$id/read', {});
      if (res.json['success'] != true) {
        return _fail(res, 'Không cập nhật được thông báo.');
      }
      return const NotificationOperationResult(success: true);
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> markAllAsRead() async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.putJson('/api/Notification/read-all', {});
      if (res.json['success'] != true) {
        return _fail(res, 'Không cập nhật được thông báo.');
      }
      return const NotificationOperationResult(success: true);
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> deleteNotification(String id) async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.deleteJson('/api/Notification/$id');
      if (res.json['success'] != true) {
        return _fail(res, 'Không xóa được thông báo.');
      }
      return const NotificationOperationResult(success: true);
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> getSettings() async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.getJson('/api/Notification/settings');
      if (res.json['success'] != true) {
        return _fail(res, 'Không tải được cài đặt thông báo.');
      }
      final data = res.json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return NotificationOperationResult.fail('Dữ liệu cài đặt không hợp lệ.');
      }
      return NotificationOperationResult(
        success: true,
        settings: NotificationSettingsRecord.fromJson(data),
      );
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> updateSettings(
    NotificationSettingsRecord settings,
  ) async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.putJson(
        '/api/Notification/settings',
        settings.toUpdateJson(),
      );
      if (res.json['success'] != true) {
        return _fail(res, 'Không lưu được cài đặt thông báo.');
      }
      final data = res.json['data'] as Map<String, dynamic>?;
      return NotificationOperationResult(
        success: true,
        message: res.json['message'] as String?,
        settings: data != null
            ? NotificationSettingsRecord.fromJson(data)
            : settings,
      );
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceName,
  }) async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final res = await client.postJson('/api/Notification/device-token', {
        'token': token,
        'platform': platform,
        if (deviceName != null && deviceName.isNotEmpty)
          'deviceName': deviceName,
      });
      if (res.json['success'] != true) {
        return _fail(res, 'Không đăng ký được thiết bị nhận push.');
      }
      return const NotificationOperationResult(success: true);
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<NotificationOperationResult> removeDeviceToken(String token) async {
    final client = await _authedClient();
    if (client == null) {
      return NotificationOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }
    try {
      final encoded = Uri.encodeComponent(token);
      final res =
          await client.deleteJson('/api/Notification/device-token?token=$encoded');
      if (res.json['success'] != true) {
        return _fail(res, 'Không gỡ được token thiết bị.');
      }
      return const NotificationOperationResult(success: true);
    } on ApiException catch (e) {
      return NotificationOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }
}
