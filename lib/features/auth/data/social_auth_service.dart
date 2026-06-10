import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/shared/models/app_models.dart';

/// Token lấy được từ SDK của nhà cung cấp, sẽ gửi lên backend để xác minh + liên kết.
class SocialCredential {
  const SocialCredential({required this.provider, required this.token});

  /// "google" hoặc "facebook".
  final String provider;

  /// Google: id_token. Facebook: access_token.
  final String token;
}

/// Lấy token đăng nhập mạng xã hội từ thiết bị.
abstract class SocialAuthService {
  Future<SocialCredential?> signIn(AuthProviderType provider);
}

/// Chọn SDK thật khi đã cấu hình key, ngược lại mock (dev).
SocialAuthService createSocialAuthService() {
  if (EnvConfig.hasGoogleSignIn || EnvConfig.hasFacebookLogin) {
    return SdkSocialAuthService();
  }
  return const MockSocialAuthService();
}

/// Mock — khớp backend `mock_google_token_*` / `mock_facebook_token_*` (Development).
class MockSocialAuthService implements SocialAuthService {
  const MockSocialAuthService();

  @override
  Future<SocialCredential?> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return switch (provider) {
      AuthProviderType.google => const SocialCredential(
          provider: 'google',
          token: 'mock_google_token_dev',
        ),
      AuthProviderType.facebook => const SocialCredential(
          provider: 'facebook',
          token: 'mock_facebook_token_dev',
        ),
      AuthProviderType.email => null,
    };
  }
}

/// Google Sign-In + Facebook Login qua SDK native.
class SdkSocialAuthService implements SocialAuthService {
  SdkSocialAuthService();

  static bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: EnvConfig.googleClientId,
    );
    _googleInitialized = true;
  }

  @override
  Future<SocialCredential?> signIn(AuthProviderType provider) async {
    return switch (provider) {
      AuthProviderType.google => _signInGoogle(),
      AuthProviderType.facebook => _signInFacebook(),
      AuthProviderType.email => null,
    };
  }

  Future<SocialCredential?> _signInGoogle() async {
    if (!EnvConfig.hasGoogleSignIn) {
      return const MockSocialAuthService().signIn(AuthProviderType.google);
    }
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Google Sign-In: id_token null — kiểm tra GOOGLE_CLIENT_ID (Web client).',
          );
        }
        return null;
      }
      return SocialCredential(provider: 'google', token: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      if (kDebugMode) debugPrint('Google Sign-In: $e');
      return null;
    } catch (e, st) {
      if (kDebugMode) debugPrint('Google Sign-In error: $e\n$st');
      return null;
    }
  }

  Future<SocialCredential?> _signInFacebook() async {
    if (!EnvConfig.hasFacebookLogin) {
      return const MockSocialAuthService().signIn(AuthProviderType.facebook);
    }
    try {
      // Bật quyền email trên Meta: Trường hợp sử dụng → Facebook Login → Quyền.
      final result = await FacebookAuth.instance.login(
        permissions: const ['public_profile', 'email'],
      );
      if (result.status != LoginStatus.success) return null;
      final token = result.accessToken?.tokenString;
      if (token == null || token.isEmpty) return null;
      return SocialCredential(provider: 'facebook', token: token);
    } catch (e, st) {
      if (kDebugMode) debugPrint('Facebook Login error: $e\n$st');
      return null;
    }
  }
}
