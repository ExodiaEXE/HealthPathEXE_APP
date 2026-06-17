import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class SocialLoginUseCase {
  const SocialLoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required String provider,
    required String providerToken,
  }) =>
      _repository.socialLogin(
        provider: provider,
        providerToken: providerToken,
      );
}
