import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/shared/models/app_models.dart';

/// Lưu lựa chọn mood/năng lượng trong ngày — khôi phục khi mở lại app.
class DailyCheckinLocalStore {
  DailyCheckinLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _dateKey = 'hp_daily_checkin_date';
  static const _moodKey = 'hp_daily_mood_idx';
  static const _energyKey = 'hp_daily_energy';
  static const _lockedKey = 'hp_daily_checkin_locked';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> save({int? mood, EnergyLevel? energy, bool? locked}) async {
    await _storage.write(key: _dateKey, value: _todayKey());
    if (mood != null) {
      await _storage.write(key: _moodKey, value: mood.toString());
    }
    if (energy != null) {
      await _storage.write(key: _energyKey, value: energy.name);
    }
    if (locked != null) {
      await _storage.write(key: _lockedKey, value: locked ? '1' : '0');
    }
  }

  Future<bool> isLockedToday() async {
    final savedDate = await _storage.read(key: _dateKey);
    if (savedDate != _todayKey()) return false;
    return (await _storage.read(key: _lockedKey)) == '1';
  }

  Future<({int? mood, EnergyLevel? energy, bool locked})?> loadToday() async {
    final savedDate = await _storage.read(key: _dateKey);
    if (savedDate != _todayKey()) {
      await clear();
      return null;
    }

    final moodStr = await _storage.read(key: _moodKey);
    final energyStr = await _storage.read(key: _energyKey);
    if (moodStr == null && energyStr == null) return null;

    return (
      mood: moodStr != null ? int.tryParse(moodStr) : null,
      energy: _parseEnergy(energyStr),
      locked: (await _storage.read(key: _lockedKey)) == '1',
    );
  }

  EnergyLevel? _parseEnergy(String? value) {
    if (value == null) return null;
    for (final level in EnergyLevel.values) {
      if (level.name == value) return level;
    }
    return null;
  }

  Future<void> clear() async {
    await _storage.delete(key: _dateKey);
    await _storage.delete(key: _moodKey);
    await _storage.delete(key: _energyKey);
    await _storage.delete(key: _lockedKey);
  }
}
