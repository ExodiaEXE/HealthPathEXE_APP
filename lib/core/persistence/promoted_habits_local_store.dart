import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu routine user bấm "+" từ gợi ý thêm — khôi phục sau khi mở lại app.
class PromotedHabitsLocalStore {
  PromotedHabitsLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _dateKey = 'hp_promoted_habits_date';
  static const _idsKey = 'hp_promoted_habit_ids';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<String>> loadToday() async {
    final savedDate = await _storage.read(key: _dateKey);
    if (savedDate != _todayKey()) {
      await clear();
      return [];
    }
    final raw = await _storage.read(key: _idsKey);
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .where((id) => id.isNotEmpty)
        .map((id) => id.toLowerCase())
        .toList();
  }

  Future<void> save(List<String> ids) async {
    await _storage.write(key: _dateKey, value: _todayKey());
    await _storage.write(
      key: _idsKey,
      value: ids.map((id) => id.toLowerCase()).join(','),
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _dateKey);
    await _storage.delete(key: _idsKey);
  }
}
