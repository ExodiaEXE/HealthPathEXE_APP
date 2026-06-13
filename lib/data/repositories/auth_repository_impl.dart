import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart' as domain;

class AuthRepositoryImpl implements domain.AuthRepository {
  AuthRepositoryImpl({ApiClient? api, TokenStore? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  final ApiClient _api;
  final TokenStore _storage;

  @override
  bool get isOnline => _api.hasBaseUrl;

  @override
  String get apiBaseUrl => EnvConfig.apiBaseUrl;

  bool get _online => isOnline;

  @override
  Future<AuthOperationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!_online) {
      return const AuthOperationResult(
        success: true,
        message: 'Đăng ký thành công!',
      );
    }
    final res = await _api.postJson('/api/Auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
    final ok = res.json['success'] == true;
    return AuthOperationResult(
      success: ok,
      message: res.json['message'] as String? ??
          (ok ? 'Đăng ký thành công!' : 'Đăng ký thất bại.'),
    );
  }

  @override
  Future<AuthOperationResult> login({
    required String email,
    required String password,
  }) async {
    if (!_online) {
      const mock = 'mock_session';
      await _storage.writeTokens(access: mock, refresh: 'mock_refresh');
      return AuthOperationResult(success: true, token: mock, userEmail: email);
    }
    if (email.trim().isEmpty || password.isEmpty) {
      return AuthOperationResult.fail('Vui lòng nhập email và mật khẩu.');
    }
    final res = await _api.postJson('/api/Auth/login', {
      'email': email.trim(),
      'password': password,
    });
    return _enrichWithProfile(await _handleAuthResponse(res));
  }

  @override
  Future<AuthOperationResult> socialLogin({
    required String provider,
    required String providerToken,
  }) async {
    if (!_online) {
      const mock = 'mock_social_session';
      await _storage.writeTokens(access: mock, refresh: 'mock_refresh');
      final parts = providerToken.split('|');
      return AuthOperationResult(
        success: true,
        token: mock,
        userEmail: parts.length > 1 ? parts[1] : '$provider@healthpath.vn',
        userName: parts.length > 2 ? parts[2] : null,
      );
    }
    final res = await _api.postJson('/api/Auth/social-login', {
      'provider': provider,
      'token': providerToken,
    });
    return _enrichWithProfile(await _handleAuthResponse(res));
  }

  @override
  Future<AuthOperationResult> verifyRegisterOtp({
    required String email,
    required String otpCode,
  }) =>
      _simplePost(
        '/api/Auth/verify-register-otp',
        {'email': email.trim(), 'otpCode': otpCode},
        offlineMessage: 'Xác thực thành công!',
        failMessage: 'Xác thực thất bại.',
      );

  @override
  Future<AuthOperationResult> resendVerificationOtp({required String email}) =>
      _simplePost(
        '/api/Auth/resend-verification-otp',
        {'email': email.trim()},
        offlineMessage: 'Đã gửi mã xác thực!',
        failMessage: 'Không gửi được mã xác thực.',
      );

  @override
  Future<AuthOperationResult> forgotPassword({required String email}) =>
      _simplePost(
        '/api/Auth/forgot-password',
        {'email': email.trim()},
        offlineMessage: 'Đã gửi mã xác thực!',
        failMessage: 'Không gửi được mã xác thực.',
      );

  @override
  Future<AuthOperationResult> resetPasswordWithOtp({
    required String email,
    required String otpCode,
    required String newPassword,
  }) =>
      _simplePost(
        '/api/Auth/reset-password-with-otp',
        {
          'email': email.trim(),
          'otpCode': otpCode,
          'newPassword': newPassword,
        },
        offlineMessage: 'Đặt lại mật khẩu thành công!',
        failMessage: 'Đặt lại mật khẩu thất bại.',
      );

  @override
  Future<AuthOperationResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!_online) {
      return const AuthOperationResult(
        success: true,
        message: 'Đổi mật khẩu thành công!',
      );
    }
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return AuthOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    final client = _api.withBearer(token);
    try {
      final res = await client.postJson('/api/Auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      final ok = res.json['success'] == true;
      return AuthOperationResult(
        success: ok,
        message: res.json['message'] as String? ??
            (ok ? 'Đổi mật khẩu thành công!' : 'Đổi mật khẩu thất bại.'),
      );
    } on ApiException catch (e) {
      return AuthOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  Future<AuthOperationResult> _simplePost(
    String path,
    Map<String, dynamic> body, {
    required String offlineMessage,
    required String failMessage,
  }) async {
    if (!_online) {
      return AuthOperationResult(success: true, message: offlineMessage);
    }
    final res = await _api.postJson(path, body);
    final ok = res.json['success'] == true;
    return AuthOperationResult(
      success: ok,
      message: res.json['message'] as String? ??
          (ok ? offlineMessage : failMessage),
      errorCode: res.json['errorCode'] as String?,
    );
  }

  Future<AuthOperationResult> _enrichWithProfile(AuthOperationResult result) async {
    if (!result.success || result.token == null) return result;
    if (result.userEmail != null && result.userName != null) return result;
    final me = await fetchMe(token: result.token);
    return me ?? result;
  }

  Future<AuthOperationResult> _handleAuthResponse(ApiResult res) async {
    final ok = res.json['success'] == true;
    if (!ok) {
      return AuthOperationResult.fail(
        res.json['message'] as String? ?? 'Đăng nhập thất bại.',
        errorCode: res.json['errorCode'] as String?,
      );
    }
    final data = res.json['data'] as Map<String, dynamic>?;
    final token = data?['token'] as String?;
    if (token == null || token.isEmpty) {
      return AuthOperationResult.fail('Máy chủ không trả về phiên đăng nhập.');
    }
    await _storage.writeTokens(access: token);
    final user = data?['user'] as Map<String, dynamic>?;
    return AuthOperationResult(
      success: true,
      token: token,
      message: res.json['message'] as String?,
      userName: user?['name'] as String?,
      userEmail: user?['email'] as String?,
      isPremium: user?['isPremium'] == true,
    );
  }

  @override
  Future<AuthOperationResult?> restoreSession() async {
    if (!_online) return null;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return null;
    }
    return fetchMe(token: token);
  }

  @override
  Future<AuthOperationResult?> fetchUserProfile() => fetchMe();

  @override
  Future<AuthOperationResult> updateUserProfile({
    required String fullName,
    String? phone,
  }) async {
    if (!_online) {
      return AuthOperationResult(
        success: true,
        userName: fullName,
        userPhone: phone,
        message: 'Đã lưu thay đổi',
      );
    }
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return AuthOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    final client = _api.withBearer(token);
    try {
      final res = await client.putJson('/api/Users/me', {
        'fullName': fullName.trim(),
        'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      });
      if (!res.isOk) {
        return AuthOperationResult.fail(
          res.json['message'] as String? ?? 'Không lưu được hồ sơ.',
        );
      }
      return _parseUserJson(res.json, token: token).copyWith(
        success: true,
        message: 'Đã lưu thay đổi',
      );
    } on ApiException catch (e) {
      return AuthOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<AuthOperationResult> uploadAvatar({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    if (!_online) {
      return const AuthOperationResult(
        success: true,
        avatarUrl: 'https://via.placeholder.com/128',
        message: 'Đã cập nhật ảnh đại diện',
      );
    }
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return AuthOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    final client = _api.withBearer(token);
    try {
      final res = await client.postMultipart(
        '/api/File/avatar',
        fieldName: 'file',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
      if (!res.isOk) {
        final msg = res.json['message'] as String? ??
            (res.json['errors'] as List?)?.join(', ') ??
            'Không tải được ảnh đại diện.';
        return AuthOperationResult.fail(msg);
      }
      final data = res.json['data'] as Map<String, dynamic>?;
      final url = _resolveMediaUrl(data?['url'] as String?);
      if (url == null || url.isEmpty) {
        return AuthOperationResult.fail('Máy chủ không trả về URL ảnh.');
      }
      return AuthOperationResult(
        success: true,
        token: token,
        avatarUrl: url,
        message: 'Đã cập nhật ảnh đại diện',
      );
    } on ApiException catch (e) {
      return AuthOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  Future<AuthOperationResult?> fetchMe({String? token}) async {
    if (!_online) return null;
    final bearer = token ?? await _storage.readAccessToken();
    if (bearer == null || bearer.isEmpty) return null;

    final client = _api.withBearer(bearer);
    try {
      final res = await client.getJson('/api/Users/me');
      if (!res.isOk) return null;
      return _parseUserJson(res.json, token: bearer);
    } on ApiException {
      return null;
    } finally {
      client.close();
    }
  }

  AuthOperationResult _parseUserJson(
    Map<String, dynamic> json, {
    required String token,
  }) {
    return AuthOperationResult(
      success: true,
      token: token,
      userName: json['name'] as String?,
      userEmail: json['email'] as String?,
      userPhone: json['phone'] as String?,
      avatarUrl: _resolveMediaUrl(json['avatarUrl'] as String?),
      isPremium: json['isPremium'] == true,
      googleLinked: json['googleLinked'] == true,
      facebookLinked: json['facebookLinked'] == true,
    );
  }

  String? _resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return url;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }
}
