import 'package:health/domain/entities/user_routine_entities.dart';
import 'package:health/domain/repositories/user_routine_repository.dart';

class FetchTodayScheduleUseCase {
  const FetchTodayScheduleUseCase(this._repository);

  final UserRoutineRepository _repository;

  Future<List<UserRoutineRecord>> call([DateTime? date]) {
    return _repository.fetchScheduleForDate(date ?? DateTime.now());
  }
}
