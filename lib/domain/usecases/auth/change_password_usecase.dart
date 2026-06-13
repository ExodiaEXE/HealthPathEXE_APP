import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}
