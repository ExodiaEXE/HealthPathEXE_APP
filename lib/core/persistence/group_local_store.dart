import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu nhóm đang chọn theo email — khôi phục sau khi mở lại app.
class GroupLocalStore {
  GroupLocalStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  String _key(String email) =>
      'hp_active_group_${email.trim().toLowerCase()}';

  Future<String?> loadActiveGroupId(String email) async {
    final key = email.trim();
    if (key.isEmpty) return null;
    return _storage.read(key: _key(key));
  }

  Future<void> saveActiveGroupId(String email, String groupId) async {
    final key = email.trim();
    if (key.isEmpty || groupId.isEmpty) return;
    await _storage.write(key: _key(key), value: groupId.toLowerCase());
  }

  Future<void> clearActiveGroupId(String email) async {
    final key = email.trim();
    if (key.isEmpty) return;
    await _storage.delete(key: _key(key));
  }
}
