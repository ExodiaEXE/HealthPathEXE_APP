import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required String email,
    required String otpCode,
    required String newPassword,
  }) =>
      _repository.resetPasswordWithOtp(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
      );
}
