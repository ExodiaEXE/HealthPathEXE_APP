import 'package:health/core/config/env_config.dart';

/// HTTP client placeholder — routes to mock when [EnvConfig.useMockBackend].
class MockApiClient {
  const MockApiClient();

  Future<Map<String, dynamic>> get(String path) async {
    if (!EnvConfig.useMockBackend) {
      throw UnsupportedError(
        'Real API not configured. Set API_BASE_URL via --dart-define.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return {'ok': true, 'path': path, 'mock': true};
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (!EnvConfig.useMockBackend) {
      throw UnsupportedError(
        'Real API not configured. Set API_BASE_URL via --dart-define.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return {'ok': true, 'path': path, 'body': body, 'mock': true};
  }
}
