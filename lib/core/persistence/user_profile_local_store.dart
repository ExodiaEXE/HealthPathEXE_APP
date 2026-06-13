import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health/shared/models/app_models.dart';

/// Lưu hồ sơ cá nhân trên máy (backend chưa có API cập nhật profile).
/// Key theo email để mỗi tài khoản có hồ sơ riêng.
class UserProfileLocalStore {
  UserProfileLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  String _key(String email) =>
      'hp_user_profile_${email.trim().toLowerCase()}';

  Future<UserProfile?> load(String email) async {
    final key = email.trim();
    if (key.isEmpty) return null;
    final raw = await _storage.read(key: _key(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String email, UserProfile profile) async {
    final key = email.trim();
    if (key.isEmpty) return;
    await _storage.write(
      key: _key(key),
      value: jsonEncode(profile.toJson()),
    );
  }

  Future<void> clear(String email) async {
    final key = email.trim();
    if (key.isEmpty) return;
    await _storage.delete(key: _key(key));
  }
}
