/// Runtime configuration — secrets via `--dart-define`, never hardcoded.
///
/// Build example:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.example.com \
///   --dart-define=JWT_ISSUER=healthpath
/// ```
class EnvConfig {
  EnvConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String jwtIssuer = String.fromEnvironment(
    'JWT_ISSUER',
    defaultValue: '',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: '',
  );

  /// `true` when backend is not wired — mock repositories only.
  static bool get useMockBackend => apiBaseUrl.isEmpty;

  static bool get hasJwtConfig => apiBaseUrl.isNotEmpty && jwtIssuer.isNotEmpty;
}
