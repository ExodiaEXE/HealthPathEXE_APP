import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction for persisting auth tokens (lets us fake storage in tests).
abstract class TokenStore {
  Future<String?> readAccessToken();
  Future<void> writeTokens({required String access, String? refresh});
  Future<void> clearTokens();
}

/// Platform secure storage for tokens and sensitive prefs.
/// Never log values from this service.
class SecureStorageService implements TokenStore {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'hp_access_token';
  static const _refreshTokenKey = 'hp_refresh_token';
  static const _loginProviderPrefix = 'hp_login_provider_';

  String _loginProviderKey(String email) =>
      '$_loginProviderPrefix${email.trim().toLowerCase()}';

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeTokens({required String access, String? refresh}) async {
    await _storage.write(key: _accessTokenKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshTokenKey, value: refresh);
    }
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> writeLoginProvider(String email, String provider) async {
    final key = email.trim();
    if (key.isEmpty) return;
    await _storage.write(key: _loginProviderKey(key), value: provider);
  }

  Future<String?> readLoginProvider(String email) async {
    final key = email.trim();
    if (key.isEmpty) return null;
    return _storage.read(key: _loginProviderKey(key));
  }

  Future<void> clearLoginProvider(String email) async {
    final key = email.trim();
    if (key.isEmpty) return;
    await _storage.delete(key: _loginProviderKey(key));
  }

  Future<void> clearAll() => _storage.deleteAll();
}
