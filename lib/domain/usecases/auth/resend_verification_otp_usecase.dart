import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class ResendVerificationOtpUseCase {
  const ResendVerificationOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({required String email}) =>
      _repository.resendVerificationOtp(email: email);
}
