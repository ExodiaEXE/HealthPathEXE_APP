import 'package:health/domain/entities/routine_entities.dart';
import 'package:health/domain/repositories/routine_repository.dart';

class FetchRoutinesUseCase {
  const FetchRoutinesUseCase(this._repository);

  final RoutineRepository _repository;

  bool get isOnline => _repository.isOnline;

  Future<List<RoutineModel>> call() => _repository.fetchAllRoutines();
}
