import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class VerifyRegisterOtpUseCase {
  const VerifyRegisterOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required String email,
    required String otpCode,
  }) =>
      _repository.verifyRegisterOtp(email: email, otpCode: otpCode);
}
