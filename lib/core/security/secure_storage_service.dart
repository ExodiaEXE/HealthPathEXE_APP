import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform secure storage for tokens and sensitive prefs.
/// Never log values from this service.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'hp_access_token';
  static const _refreshTokenKey = 'hp_refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeTokens({required String access, String? refresh}) async {
    await _storage.write(key: _accessTokenKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshTokenKey, value: refresh);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
