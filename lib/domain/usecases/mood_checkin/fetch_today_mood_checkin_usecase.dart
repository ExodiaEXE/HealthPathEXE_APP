import 'package:health/domain/entities/mood_checkin_entities.dart';
import 'package:health/domain/repositories/mood_checkin_repository.dart';

class FetchTodayMoodCheckinUseCase {
  const FetchTodayMoodCheckinUseCase(this._repository);

  final MoodCheckinRepository _repository;

  Future<MoodCheckinRecord?> call() => _repository.fetchTodayCheckin();
}
