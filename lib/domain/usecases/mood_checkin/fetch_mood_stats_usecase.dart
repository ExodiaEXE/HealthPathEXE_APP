import 'package:health/domain/entities/mood_checkin_entities.dart';
import 'package:health/domain/repositories/mood_checkin_repository.dart';

class FetchMoodStatsUseCase {
  const FetchMoodStatsUseCase(this._repository);

  final MoodCheckinRepository _repository;

  Future<MoodStats?> call() => _repository.fetchStats();
}
