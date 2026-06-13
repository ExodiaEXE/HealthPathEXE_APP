import 'package:health/core/config/env_config.dart';
import 'package:health/core/security/secure_storage_service.dart';

/// JWT session layer — mock until backend is ready.
class JwtAuthService {
  JwtAuthService(this._storage);

  final SecureStorageService _storage;

  Future<bool> hasValidSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return false;
    if (EnvConfig.useMockBackend) return true;
    // TODO: decode JWT exp, refresh via API when backend ready
    return true;
  }

  /// Mock login — stores opaque token locally (no real JWT until API exists).
  Future<void> signInMock({required String email}) async {
    final mockToken = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.writeTokens(access: mockToken, refresh: 'mock_refresh');
  }

  /// Persist a real JWT obtained from the backend.
  Future<void> persistToken(String token) =>
      _storage.writeTokens(access: token);

  Future<String?> currentToken() => _storage.readAccessToken();

  Future<void> signOut() => _storage.clearTokens();

  Future<void> persistLoginProvider({
    required String email,
    required String provider,
  }) =>
      _storage.writeLoginProvider(email, provider);

  Future<String?> loginProviderFor(String email) =>
      _storage.readLoginProvider(email);

  Future<void> clearLoginProvider(String email) =>
      _storage.clearLoginProvider(email);
}
