import 'dart:async';
import 'dart:io' show Platform;

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

class SocialSignInResult {
  const SocialSignInResult._({
    this.credential,
    this.message,
    this.cancelled = false,
  });

  const SocialSignInResult.success(SocialCredential cred)
      : this._(credential: cred);

  const SocialSignInResult.cancelled() : this._(cancelled: true);

  const SocialSignInResult.failed(String msg) : this._(message: msg);

  final SocialCredential? credential;
  final String? message;
  final bool cancelled;
}

/// Lấy token đăng nhập mạng xã hội từ thiết bị.
abstract class SocialAuthService {
  Future<SocialSignInResult> signIn(AuthProviderType provider);
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
  Future<SocialSignInResult> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return switch (provider) {
      AuthProviderType.google => const SocialSignInResult.success(
          SocialCredential(provider: 'google', token: 'mock_google_token_dev'),
        ),
      AuthProviderType.facebook => const SocialSignInResult.success(
          SocialCredential(
            provider: 'facebook',
            token: 'mock_facebook_token_dev',
          ),
        ),
      AuthProviderType.email => const SocialSignInResult.failed(
          'Email không dùng social login.',
        ),
    };
  }
}

/// Google Sign-In + Facebook Login qua SDK native.
class SdkSocialAuthService implements SocialAuthService {
  SdkSocialAuthService();

  static bool _googleInitialized = false;

  static const _googleShaHint =
      'Google Cloud OAuth Android: package com.exodiateam.healthpath + '
      'SHA-1 App signing CE:A1:27:... (GG_sign) cho app cai tu Play; '
      'SHA-1 upload 0B:00:95:... (HealthPath_App). Web client trong GOOGLE_CLIENT_ID.';

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: EnvConfig.googleClientId,
    );
    _googleInitialized = true;
  }

  @override
  Future<SocialSignInResult> signIn(AuthProviderType provider) async {
    return switch (provider) {
      AuthProviderType.google => _signInGoogle(),
      AuthProviderType.facebook => _signInFacebook(),
      AuthProviderType.email => const SocialSignInResult.failed(
          'Email không dùng social login.',
        ),
    };
  }

  Future<SocialSignInResult> _signInGoogle() async {
    if (!EnvConfig.hasGoogleSignIn) {
      return const MockSocialAuthService().signIn(AuthProviderType.google);
    }
    try {
      await _ensureGoogleInitialized();
      // Xóa session Credential Manager cũ (đổi package name dễ gây [16] reauth failed).
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (kDebugMode) {
          debugPrint('Google Sign-In: id_token null — $_googleShaHint');
        }
        return const SocialSignInResult.failed(
          'Không lấy được mã Google. GOOGLE_CLIENT_ID phải là Web client. $_googleShaHint',
        );
      }
      return SocialSignInResult.success(
        SocialCredential(provider: 'google', token: idToken),
      );
    } on GoogleSignInException catch (e) {
      if (kDebugMode) debugPrint('Google Sign-In: $e');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        final detail = e.toString();
        if (detail.contains('[16]') || detail.contains('reauth')) {
          return SocialSignInResult.failed(
            'Google lỗi cấu hình (SHA-1/package). $_googleShaHint',
          );
        }
        return const SocialSignInResult.cancelled();
      }
      final detail = e.toString();
      if (detail.contains('28444') ||
          detail.contains('not set up correctly') ||
          detail.contains('[10]')) {
        return const SocialSignInResult.failed(
          'Google Cloud chua khop app (loi 10): kiem tra OAuth consent screen '
          '(test users), Android client GG_sign + SHA-1 App signing, '
          'Web client trong GOOGLE_CLIENT_ID, va cap nhat app tu Play.',
        );
      }
      return SocialSignInResult.failed('Google Sign-In: ${e.code.name}');
    } catch (e, st) {
      if (kDebugMode) debugPrint('Google Sign-In error: $e\n$st');
      return SocialSignInResult.failed('Lỗi Google Sign-In: $e');
    }
  }

  Future<SocialSignInResult> _signInFacebook() async {
    if (!EnvConfig.hasFacebookLogin) {
      return const MockSocialAuthService().signIn(AuthProviderType.facebook);
    }
    try {
      // webOnly hay treo trắng m.facebook.com trên emulator — ưu tiên native/dialog.
      final behaviors = Platform.isAndroid
          ? [
              LoginBehavior.nativeWithFallback,
              LoginBehavior.dialogOnly,
            ]
          : [LoginBehavior.nativeWithFallback];

      LoginResult? lastResult;
      for (final behavior in behaviors) {
        try {
          final result = await FacebookAuth.instance
              .login(
                permissions: const ['public_profile', 'email'],
                loginBehavior: behavior,
                loginTracking: LoginTracking.enabled,
              )
              .timeout(const Duration(seconds: 45));
          if (result.status == LoginStatus.cancelled) {
            return const SocialSignInResult.cancelled();
          }
          if (result.status == LoginStatus.success) {
            final token = result.accessToken?.tokenString;
            if (token == null || token.isEmpty) {
              return const SocialSignInResult.failed(
                'Facebook không trả access token.',
              );
            }
            return SocialSignInResult.success(
              SocialCredential(provider: 'facebook', token: token),
            );
          }
          lastResult = result;
          if (kDebugMode) {
            debugPrint(
              'Facebook Login ($behavior): ${result.status} ${result.message}',
            );
          }
        } on TimeoutException {
          if (kDebugMode) {
            debugPrint('Facebook Login ($behavior): timeout — thử cách khác');
          }
        }
      }

      final detail = lastResult?.message?.trim();
      return SocialSignInResult.failed(
        detail?.isNotEmpty == true
            ? detail!
            : 'Facebook không đăng nhập được. Cài app Facebook trên emulator '
                'hoặc thêm tài khoản Tester trên Meta.',
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('Facebook Login error: $e\n$st');
      return SocialSignInResult.failed('Lỗi Facebook Login: $e');
    }
  }
}
