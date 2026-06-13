import 'package:health/domain/entities/mood_checkin_entities.dart';
import 'package:health/domain/repositories/mood_checkin_repository.dart';
import 'package:health/shared/models/app_models.dart';

class SyncMoodCheckinUseCase {
  const SyncMoodCheckinUseCase(this._repository);

  final MoodCheckinRepository _repository;

  bool get isOnline => _repository.isOnline;

  Future<MoodCheckinRecord?> call({
    required int moodIndex,
    required EnergyLevel energy,
  }) {
    return _repository.upsertTodayCheckin(
      mood: _moodLabel(moodIndex),
      energyLevel: _energyLabel(energy),
    );
  }

  static String moodLabel(int index) {
    switch (index) {
      case 0:
        return 'Mệt';
      case 2:
        return 'Căng thẳng';
      default:
        return 'Ổn';
    }
  }

  static String energyLabel(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.low:
        return 'Low';
      case EnergyLevel.high:
        return 'High';
      case EnergyLevel.medium:
        return 'Medium';
    }
  }

  static int? moodIndexFromApi(String mood) {
    final normalized = mood.toLowerCase().trim();
    if (normalized.contains('mệt') || normalized == 'tired') return 0;
    if (normalized.contains('căng') || normalized == 'stressed') return 2;
    if (normalized.contains('ổn') ||
        normalized == 'neutral' ||
        normalized == 'okay' ||
        normalized == 'ok') {
      return 1;
    }
    return null;
  }

  static EnergyLevel? energyFromApi(String level) {
    switch (level.toLowerCase().trim()) {
      case 'low':
        return EnergyLevel.low;
      case 'high':
        return EnergyLevel.high;
      case 'medium':
        return EnergyLevel.medium;
      default:
        return null;
    }
  }

  static String _moodLabel(int index) => moodLabel(index);

  static String _energyLabel(EnergyLevel energy) => energyLabel(energy);
}
