import 'package:health/domain/entities/complete_routine_result.dart';
import 'package:health/domain/repositories/user_routine_repository.dart';

class CompleteTodayRoutineUseCase {
  const CompleteTodayRoutineUseCase(this._repository);

  final UserRoutineRepository _repository;

  bool get isOnline => _repository.isOnline;

  Future<CompleteRoutineResult> call({
    required String routineId,
    int? durationMinutes,
  }) {
    return _repository.completeRoutineForToday(
      routineId: routineId,
      durationMinutes: durationMinutes,
    );
  }
}
