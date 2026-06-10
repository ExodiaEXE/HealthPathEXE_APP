import 'package:health/domain/entities/mood_checkin_entities.dart';

abstract class MoodCheckinRepository {
  bool get isOnline;

  Future<MoodCheckinRecord?> upsertTodayCheckin({
    required String mood,
    required String energyLevel,
  });

  Future<MoodCheckinRecord?> fetchTodayCheckin();

  Future<MoodStats?> fetchStats();
}
