import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/shared/models/app_models.dart';

/// Lưu lịch sử thói quen theo email — backend chưa có API history.
class HabitHistoryLocalStore {
  HabitHistoryLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  String _key(String email) =>
      'hp_habit_history_${email.trim().toLowerCase()}';

  Future<List<HabitRecord>> load(String email) async {
    final key = email.trim();
    if (key.isEmpty) return [];
    final raw = await _storage.read(key: _key(key));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => HabitRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(String email, List<HabitRecord> records) async {
    final key = email.trim();
    if (key.isEmpty) return;
    final payload = jsonEncode(records.map((r) => r.toJson()).toList());
    await _storage.write(key: _key(key), value: payload);
  }

  Future<void> clear(String email) async {
    final key = email.trim();
    if (key.isEmpty) return;
    await _storage.delete(key: _key(key));
  }
}
