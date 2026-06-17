import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu routine đã hoàn thành trong ngày — khôi phục khi mở lại app.
class CompletedHabitsLocalStore {
  CompletedHabitsLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _dateKey = 'hp_completed_habits_date';
  static const _idsKey = 'hp_completed_habit_ids';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<Set<String>> loadToday() async {
    final savedDate = await _storage.read(key: _dateKey);
    if (savedDate != _todayKey()) {
      await clear();
      return {};
    }
    final raw = await _storage.read(key: _idsKey);
    if (raw == null || raw.isEmpty) return {};
    return raw
        .split(',')
        .where((id) => id.isNotEmpty)
        .map((id) => id.toLowerCase())
        .toSet();
  }

  /// Trả về ngày + routine đã hoàn thành nếu storage còn dữ liệu ngày cũ (trước khi clear).
  Future<({String date, Set<String> ids})?> readPreviousDayIfRollover() async {
    final savedDate = await _storage.read(key: _dateKey);
    if (savedDate == null || savedDate.isEmpty) return null;
    if (savedDate == _todayKey()) return null;
    final raw = await _storage.read(key: _idsKey);
    final ids = raw == null || raw.isEmpty
        ? <String>{}
        : raw
            .split(',')
            .where((id) => id.isNotEmpty)
            .map((id) => id.toLowerCase())
            .toSet();
    return (date: savedDate, ids: ids);
  }

  Future<void> save(Set<String> ids) async {
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
