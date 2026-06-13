import 'package:health/domain/repositories/wellness_repository.dart';
import 'package:health/shared/models/app_models.dart';

/// Use case tổng hợp nội dung wellness — presentation không gọi data trực tiếp.
class WellnessContentUseCase {
  const WellnessContentUseCase(this._repository);

  final WellnessRepository _repository;

  Map<EnergyLevel, List<RoutineItem>> get habitsByEnergy =>
      _repository.habitsByEnergy;

  List<({EnergyLevel level, String label, String emoji})> get energyOptions =>
      _repository.energyOptions;

  List<({String emoji, String label})> get moods => _repository.moods;

  List<String> get weekDays => _repository.weekDays;

  Map<String, String> get suggestionEmojis => _repository.suggestionEmojis;

  List<AudioTrack> get allTracks => _repository.allTracks;

  List<({String id, String label, String emoji})> get audioCategories =>
      _repository.audioCategories;

  Map<int, List<MoodTrack>> get moodTracks => _repository.moodTracks;

  List<({int id, String name, int score, String avatar, int streak, bool isMe})>
      get teamMembers => _repository.teamMembers;

  List<({String id, String name, int members, String emoji})> get existingGroups =>
      _repository.existingGroups;

  List<HabitRecord> generateMockHistory() => _repository.generateMockHistory();

  List<RoutineSuggestion> getRoutineSuggestions(
    EnergyLevel? energy,
    int? mood,
  ) =>
      _repository.getRoutineSuggestions(energy, mood);

  List<RoutineItem> getHabitsForEnergy(EnergyLevel? energy) {
    if (energy == null) return const [];
    return List<RoutineItem>.from(_repository.habitsByEnergy[energy] ?? []);
  }
}
