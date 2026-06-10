import 'package:health/domain/entities/auth_entities.dart';

/// Hợp đồng tầng domain cho xác thực — presentation chỉ gọi qua use case.
abstract class AuthRepository {
  bool get isOnline;
  String get apiBaseUrl;

  Future<AuthOperationResult> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AuthOperationResult> login({
    required String email,
    required String password,
  });

  Future<AuthOperationResult> socialLogin({
    required String provider,
    required String providerToken,
  });

  Future<AuthOperationResult> verifyRegisterOtp({
    required String email,
    required String otpCode,
  });

  Future<AuthOperationResult> resendVerificationOtp({required String email});

  Future<AuthOperationResult> forgotPassword({required String email});

  Future<AuthOperationResult> resetPasswordWithOtp({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  Future<AuthOperationResult> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AuthOperationResult?> restoreSession();
}
