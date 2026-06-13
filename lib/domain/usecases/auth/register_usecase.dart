import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
}
