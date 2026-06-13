import 'package:health/domain/entities/auth_entities.dart';
import 'package:health/domain/repositories/auth_repository.dart';

class FetchUserProfileUseCase {
  const FetchUserProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult?> call() => _repository.fetchUserProfile();
}

class UpdateUserProfileUseCase {
  const UpdateUserProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required String fullName,
    String? phone,
  }) =>
      _repository.updateUserProfile(fullName: fullName, phone: phone);
}

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthOperationResult> call({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) =>
      _repository.uploadAvatar(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
}
