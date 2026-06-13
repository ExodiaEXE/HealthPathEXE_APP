import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/core/utils/weekly_planner_utils.dart';
import 'package:health/domain/entities/complete_routine_result.dart';
import 'package:health/domain/entities/recurring_template_entities.dart';
import 'package:health/domain/entities/user_routine_entities.dart';
import 'package:health/domain/entities/weekly_plan_sync_result.dart';
import 'package:health/domain/repositories/user_routine_repository.dart';
import 'package:health/shared/models/app_models.dart';

class UserRoutineRepositoryImpl implements UserRoutineRepository {
  UserRoutineRepositoryImpl({ApiClient? api, TokenStore? storage})
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
    return ApiClient(baseUrl: EnvConfig.apiBaseUrl, bearerToken: token);
  }

  String? _apiMessage(Map<String, dynamic> json) =>
      json['message'] as String?;

  String? _apiErrorCode(Map<String, dynamic> json) =>
      json['errorCode'] as String?;

  @override
  Future<List<UserRoutineRecord>> fetchScheduleForDate(DateTime date) async {
    final client = await _authedClient();
    if (client == null) return const [];

    final local = DateTime.utc(date.year, date.month, date.day);
    final query = 'date=${local.toIso8601String()}&page=1&pageSize=100';

    try {
      final res = await client.getJson('/api/UserRoutine/my-schedule?$query');
      if (res.json['success'] != true) return const [];
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => UserRoutineRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return const [];
    } finally {
      client.close();
    }
  }

  Future<String?> _createCatalogRoutineId(
    ApiClient client,
    RoutineItem item,
  ) async {
    try {
      final res = await client.postJson('/api/Routine', {
        'title': item.text,
        'category': item.category.isNotEmpty ? item.category : 'other',
        'difficulty': 'easy',
        'durationMinutes': 5,
      });
      if (res.json['success'] != true) {
        return null;
      }
      final data = res.json['data'] as Map<String, dynamic>?;
      final id = data?['id'] as String?;
      return id?.toLowerCase();
    } on ApiException {
      return null;
    }
  }

  Future<String?> _resolveRoutineId(
    ApiClient client,
    RoutineItem item,
  ) async {
    if (WeeklyPlannerUtils.isCatalogRoutineId(item.id)) {
      return item.id.toLowerCase();
    }
    return _createCatalogRoutineId(client, item);
  }

  @override
  Future<CompleteRoutineResult> completeRoutineForToday({
    required String routineId,
    int? durationMinutes,
  }) async {
    final client = await _authedClient();
    if (client == null) {
      return const CompleteRoutineResult(
        errorMessage: 'Chưa kết nối máy chủ.',
      );
    }

    try {
      final today = DateTime.now();
      final existing = await fetchScheduleForDate(today);
      UserRoutineRecord? target;
      final rid = routineId.toLowerCase();

      for (final item in existing) {
        if (item.routineId.toLowerCase() != rid) continue;
        if (item.isCompleted) {
          return CompleteRoutineResult(record: item);
        }
        if (item.status == 'failed' || item.status == 'cancelled') continue;
        target = item;
        break;
      }

      if (target == null) {
        final scheduledAt =
            DateTime.utc(today.year, today.month, today.day, 12);
        final schedule = await client.postJson('/api/UserRoutine/schedule', {
          'routineId': routineId,
          'scheduledAt': scheduledAt.toIso8601String(),
        });
        if (schedule.json['success'] != true) {
          return CompleteRoutineResult(
            errorMessage: _apiMessage(schedule.json) ??
                'Không thể lên lịch routine.',
            errorCode: _apiErrorCode(schedule.json),
          );
        }
        final data = schedule.json['data'] as Map<String, dynamic>?;
        if (data == null) {
          return const CompleteRoutineResult(
            errorMessage: 'Phản hồi lịch routine không hợp lệ.',
          );
        }
        target = UserRoutineRecord.fromJson(data);
      }

      if (target.status == 'pending') {
        final start = await client.postJson(
          '/api/UserRoutine/${target.id}/start',
          {},
        );
        if (start.json['success'] != true) {
          return CompleteRoutineResult(
            errorMessage:
                _apiMessage(start.json) ?? 'Không thể bắt đầu routine.',
            errorCode: _apiErrorCode(start.json),
          );
        }
        final data = start.json['data'] as Map<String, dynamic>?;
        if (data != null) target = UserRoutineRecord.fromJson(data);
      }

      final minutes = durationMinutes ?? 5;
      final complete = await client.postJson(
        '/api/UserRoutine/${target.id}/complete',
        {
          'status': 'completed',
          'elapsedSeconds': minutes * 60,
          'actualDurationMinutes': minutes,
        },
      );
      if (complete.json['success'] != true) {
        return CompleteRoutineResult(
          errorMessage:
              _apiMessage(complete.json) ?? 'Không thể hoàn thành routine.',
          errorCode: _apiErrorCode(complete.json),
        );
      }
      final data = complete.json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return const CompleteRoutineResult(
          errorMessage: 'Phản hồi hoàn thành không hợp lệ.',
        );
      }
      return CompleteRoutineResult(
        record: UserRoutineRecord.fromJson(data),
      );
    } on ApiException catch (e) {
      return CompleteRoutineResult(errorMessage: e.message);
    } finally {
      client.close();
    }
  }

  Future<List<RecurringTemplateRecord>> _fetchRecurringTemplates(
    ApiClient client,
  ) async {
    try {
      final res = await client.getJson('/api/UserRoutine/recurring');
      if (res.json['success'] != true) return const [];
      final items = res.json['data'] as List<dynamic>? ?? [];
      return items
          .map((e) =>
              RecurringTemplateRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return const [];
    }
  }

  @override
  Future<List<RecurringTemplateRecord>> fetchRecurringTemplates() async {
    final client = await _authedClient();
    if (client == null) return const [];

    try {
      return await _fetchRecurringTemplates(client);
    } finally {
      client.close();
    }
  }

  Future<bool> _createRecurringTemplate(
    ApiClient client, {
    required String routineId,
    required List<int> daysOfWeek,
    String scheduledTime = '09:00:00',
  }) async {
    try {
      final res = await client.postJson('/api/UserRoutine/recurring', {
        'routineId': routineId,
        'daysOfWeek': daysOfWeek,
        'scheduledTime': scheduledTime,
      });
      return res.json['success'] == true;
    } on ApiException {
      return false;
    }
  }

  @override
  Future<bool> createRecurringTemplate({
    required String routineId,
    required List<int> daysOfWeek,
    String scheduledTime = '09:00:00',
  }) async {
    final client = await _authedClient();
    if (client == null) return false;

    try {
      return await _createRecurringTemplate(
        client,
        routineId: routineId,
        daysOfWeek: daysOfWeek,
        scheduledTime: scheduledTime,
      );
    } finally {
      client.close();
    }
  }

  Future<bool> _deleteRecurringTemplate(
    ApiClient client,
    String templateId,
  ) async {
    try {
      final res =
          await client.deleteJson('/api/UserRoutine/recurring/$templateId');
      return res.json['success'] == true;
    } on ApiException {
      return false;
    }
  }

  @override
  Future<bool> deleteRecurringTemplate(String templateId) async {
    final client = await _authedClient();
    if (client == null) return false;

    try {
      return await _deleteRecurringTemplate(client, templateId);
    } finally {
      client.close();
    }
  }

  @override
  Future<WeeklyPlanSyncResult> syncWeeklyPlan(
    Map<int, List<RoutineItem>> plan,
  ) async {
    if (!isOnline) {
      return const WeeklyPlanSyncResult(savedLocally: true, offline: true);
    }

    final client = await _authedClient();
    if (client == null) {
      return const WeeklyPlanSyncResult(savedLocally: true, noAuth: true);
    }

    try {
      final existing = await _fetchRecurringTemplates(client);
      if (existing.isNotEmpty) {
        await Future.wait(
          existing.map((t) => _deleteRecurringTemplate(client, t.id)),
        );
      }

      final uniqueItems = <String, RoutineItem>{};
      for (final entry in plan.entries) {
        for (final item in entry.value) {
          uniqueItems.putIfAbsent(item.id.toLowerCase(), () => item);
        }
      }

      final resolvedEntries = await Future.wait(
        uniqueItems.entries.map((entry) async {
          final routineId = await _resolveRoutineId(client, entry.value);
          return MapEntry(entry.key, routineId);
        }),
      );
      final routineIdByItemId = {
        for (final entry in resolvedEntries)
          if (entry.value != null) entry.key: entry.value!,
      };

      final idRemapping = <String, String>{};
      for (final entry in routineIdByItemId.entries) {
        if (entry.key.startsWith('custom-')) {
          idRemapping[entry.key] = entry.value;
        }
      }

      final grouped = <String, Set<int>>{};
      for (final entry in plan.entries) {
        for (final item in entry.value) {
          final routineId = routineIdByItemId[item.id.toLowerCase()];
          if (routineId == null) continue;
          grouped
              .putIfAbsent(routineId, () => {})
              .add(WeeklyPlannerUtils.toApiDayOfWeek(entry.key));
        }
      }

      if (grouped.isEmpty) {
        return WeeklyPlanSyncResult(
          savedLocally: true,
          idRemapping: idRemapping,
        );
      }

      final createResults = await Future.wait(
        grouped.entries.map((entry) async {
          final days = entry.value.toList()..sort();
          final ok = await _createRecurringTemplate(
            client,
            routineId: entry.key,
            daysOfWeek: days,
          );
          return ok;
        }),
      );

      final synced = createResults.where((ok) => ok).length;
      return WeeklyPlanSyncResult(
        savedLocally: true,
        syncedTemplateCount: synced,
        idRemapping: idRemapping,
        errorMessage: synced == 0 ? 'Không đồng bộ được lên máy chủ.' : null,
      );
    } on ApiException catch (e) {
      return WeeklyPlanSyncResult(
        savedLocally: true,
        errorMessage: e.message,
      );
    } finally {
      client.close();
    }
  }
}
