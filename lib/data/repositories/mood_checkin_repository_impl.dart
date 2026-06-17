import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/domain/entities/mood_checkin_entities.dart';
import 'package:health/domain/repositories/mood_checkin_repository.dart';

class MoodCheckinRepositoryImpl implements MoodCheckinRepository {
  MoodCheckinRepositoryImpl({ApiClient? api, TokenStore? storage})
      : _api = api,
        _storage = storage ?? SecureStorageService();

  final ApiClient? _api;
  final TokenStore _storage;

  @override
  bool get isOnline =>
      _api?.hasBaseUrl ?? EnvConfig.apiBaseUrl.isNotEmpty;

  Future<ApiClient?> _authedClient() async {
    if (!isOnline) return null;
    if (_api != null) return _api;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return null;
    }
    return ApiClient(baseUrl: EnvConfig.apiBaseUrl, bearerToken: token);
  }

  @override
  Future<MoodCheckinRecord?> upsertTodayCheckin({
    required String mood,
    required String energyLevel,
  }) async {
    final client = await _authedClient();
    if (client == null) return null;

    try {
      final body = {'mood': mood, 'energyLevel': energyLevel};
      final create = await client.postJson('/api/MoodCheckin', body);
      if (create.json['success'] == true) {
        final data = create.json['data'] as Map<String, dynamic>?;
        if (data != null) return MoodCheckinRecord.fromJson(data);
      }

      if (create.json['errorCode'] == 'ALREADY_CHECKED_IN') {
        final today = await _findTodayCheckin(client);
        if (today == null) return null;
        final update = await client.putJson(
          '/api/MoodCheckin/${today.id}',
          body,
        );
        if (update.json['success'] == true) {
          final data = update.json['data'] as Map<String, dynamic>?;
          if (data != null) return MoodCheckinRecord.fromJson(data);
        }
      }
      return null;
    } on ApiException {
      return null;
    } finally {
      if (_api == null) client.close();
    }
  }

  @override
  Future<MoodCheckinRecord?> fetchTodayCheckin() async {
    final client = await _authedClient();
    if (client == null) return null;

    try {
      return await _findTodayCheckin(client);
    } on ApiException {
      return null;
    } finally {
      if (_api == null) client.close();
    }
  }

  Future<MoodCheckinRecord?> _findTodayCheckin(ApiClient client) async {
    final res = await client.getJson('/api/MoodCheckin/my-history');
    if (res.json['success'] != true) return null;
    final list = res.json['data'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    for (final item in list) {
      final record = MoodCheckinRecord.fromJson(item as Map<String, dynamic>);
      if (_isSameLocalDay(record.checkedAt, now)) return record;
    }
    return null;
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  @override
  Future<MoodStats?> fetchStats() async {
    final client = await _authedClient();
    if (client == null) return null;

    try {
      final res = await client.getJson('/api/MoodCheckin/stats');
      if (res.json['success'] != true) return null;
      final data = res.json['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return MoodStats.fromJson(data);
    } on ApiException {
      return null;
    } finally {
      if (_api == null) client.close();
    }
  }
}
