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
///
/// Bản thật sẽ dùng `google_sign_in` / `flutter_facebook_auth` để mở luồng OAuth
/// và lấy id_token / access_token. Ở đây tách interface để app build/test được
/// ngay cả khi chưa cấu hình SDK native (chưa có google-services.json…).
abstract class SocialAuthService {
  Future<SocialCredential?> signIn(AuthProviderType provider);
}

/// Bản giả lập: trả token theo đúng định dạng mà backend `MockSocialTokenVerifier`
/// hiểu được (`providerUserId|email|fullName`). Nhờ vậy luồng "bấm Google/Facebook
/// → backend tạo/liên kết User → trả JWT" chạy thật end-to-end khi backend bật
/// UseMockVerifier=true, mà không cần Client ID thật.
class MockSocialAuthService implements SocialAuthService {
  const MockSocialAuthService();

  @override
  Future<SocialCredential?> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return switch (provider) {
      AuthProviderType.google => const SocialCredential(
          provider: 'google',
          token: 'google-dev-uid|user@gmail.com|Google User',
        ),
      AuthProviderType.facebook => const SocialCredential(
          provider: 'facebook',
          token: 'facebook-dev-uid|user@facebook.com|Facebook User',
        ),
      AuthProviderType.email => null,
    };
  }
}
