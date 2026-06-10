import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình runtime — đọc từ file `.env` (giống backend).
///
/// Thứ tự ưu tiên (cao → thấp):
/// 1. `--dart-define` (CI / build release)
/// 2. File `.env` ở thư mục gốc project (dev hàng ngày — không commit)
/// 3. `.env.example` (fallback khi chưa tạo `.env`)
///
/// Lần đầu: chạy `.\scripts\setup_env.ps1` hoặc copy `.env.example` → `.env`
class EnvConfig {
  EnvConfig._();

  static bool _loaded = false;

  /// Gọi một lần trong `main()` trước `runApp`.
  static Future<void> load() async {
    if (_loaded) return;
    // Ưu tiên `.env` (file bạn sửa hàng ngày), không có thì dùng mẫu `.env.example`
    for (final file in ['.env', '.env.example']) {
      try {
        await dotenv.load(fileName: file);
        if (kDebugMode) debugPrint('EnvConfig: loaded $file');
        break;
      } catch (_) {
        continue;
      }
    }
    _loaded = true;
  }

  /// Dùng trong unit/widget test — không đọc file, không gọi network.
  @visibleForTesting
  static void loadForTest({Map<String, String> values = const {}}) {
    dotenv.clean();
    const defaults = <String, String>{
      'API_BASE_URL': '',
      'JWT_ISSUER': 'healthpath',
    };
    final merged = {...defaults, ...values};
    dotenv.loadFromString(
      envString: merged.entries.map((e) => '${e.key}=${e.value}').join('\n'),
    );
    _loaded = true;
  }

  static String _env(String key, {String dartDefineKey = ''}) {
    final defineKey = dartDefineKey.isEmpty ? key : dartDefineKey;
    final fromDefine = String.fromEnvironment(defineKey, defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (!_loaded) return '';
    return dotenv.env[key]?.trim() ?? '';
  }

  static String get apiBaseUrl => _env('API_BASE_URL');

  static String get jwtIssuer => _env('JWT_ISSUER');

  static String get googleClientId => _env('GOOGLE_CLIENT_ID');

  static String get facebookAppId => _env('FACEBOOK_APP_ID');

  /// `true` khi chưa cấu hình URL backend — chỉ dùng mock UI.
  static bool get useMockBackend => apiBaseUrl.isEmpty;

  static bool get hasJwtConfig => apiBaseUrl.isNotEmpty && jwtIssuer.isNotEmpty;
}
