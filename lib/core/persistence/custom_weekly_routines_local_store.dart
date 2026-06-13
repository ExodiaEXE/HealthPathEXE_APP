import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/shared/models/app_models.dart';

/// Lưu routine 7 ngày do user tự đặt.
class CustomWeeklyRoutinesLocalStore {
  CustomWeeklyRoutinesLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;
  static const _key = 'hp_custom_weekly_routines';

  Future<Map<int, List<RoutineItem>>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <int, List<RoutineItem>>{};
      for (final entry in decoded.entries) {
        final day = int.tryParse(entry.key);
        if (day == null || day < 0 || day > 6) continue;
        final items = entry.value as List<dynamic>? ?? [];
        result[day] = items
            .map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<int, List<RoutineItem>> plan) async {
    final encoded = <String, dynamic>{};
    for (final entry in plan.entries) {
      encoded['${entry.key}'] =
          entry.value.map((item) => item.toJson()).toList();
    }
    await _storage.write(key: _key, value: jsonEncode(encoded));
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
