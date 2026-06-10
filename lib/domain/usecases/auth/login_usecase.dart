import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required String email,
    required String password,
  }) =>
      _repository.login(email: email, password: password);
}
