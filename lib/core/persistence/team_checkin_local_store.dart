import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu điểm danh nhóm theo tuần (T2–CN), tự xóa ngày cũ khi sang tuần mới.
class TeamCheckinLocalStore {
  TeamCheckinLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static DateTime currentWeekMonday([DateTime? reference]) {
    final today = reference ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String todayKey() => dateKey(DateTime.now());

  String _storageKey(String email) =>
      'hp_team_checkin_${email.trim().toLowerCase()}';

  Future<Map<String, List<String>>> _loadAll(String email) async {
    final raw = await _storage.read(key: _storageKey(email));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (groupId, dates) => MapEntry(
          groupId.toLowerCase(),
          List<String>.from(dates as List<dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(String email, Map<String, List<String>> data) async {
    await _storage.write(key: _storageKey(email), value: jsonEncode(data));
  }

  List<String> _pruneToCurrentWeek(List<String> dates) {
    final monday = currentWeekMonday();
    final sunday = monday.add(const Duration(days: 6));
    return dates.where((raw) {
      final parts = raw.split('-');
      if (parts.length != 3) return false;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(monday) && !day.isAfter(sunday);
    }).toList();
  }

  Future<bool> hasCheckedInToday(String email, String groupId) async {
    final dates = await weekCheckInDates(email, groupId);
    return dates.contains(todayKey());
  }

  Future<Set<String>> weekCheckInDates(String email, String groupId) async {
    final all = await _loadAll(email);
    final gid = groupId.toLowerCase();
    final pruned = _pruneToCurrentWeek(List<String>.from(all[gid] ?? []));
    if (pruned.length != (all[gid]?.length ?? 0)) {
      all[gid] = pruned;
      await _saveAll(email, all);
    }
    return pruned.toSet();
  }

  Future<void> recordCheckIn(String email, String groupId) async {
    final all = await _loadAll(email);
    final gid = groupId.toLowerCase();
    final dates = _pruneToCurrentWeek(List<String>.from(all[gid] ?? []));
    final today = todayKey();
    if (!dates.contains(today)) {
      dates.add(today);
    }
    all[gid] = dates;
    await _saveAll(email, all);
  }
}
