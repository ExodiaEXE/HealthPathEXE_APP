import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult?> call() => _repository.restoreSession();
}
