import 'package:health/data/datasources/mock_wellness_datasource.dart';
import 'package:health/domain/repositories/wellness_repository.dart';
import 'package:health/shared/models/app_models.dart';

class WellnessRepositoryImpl implements WellnessRepository {
  @override
  Map<EnergyLevel, List<RoutineItem>> get habitsByEnergy =>
      MockWellnessDataSource.habitsByEnergy;

  @override
  List<({EnergyLevel level, String label, String emoji})> get energyOptions =>
      MockWellnessDataSource.energyOptions;

  @override
  List<({String emoji, String label})> get moods => MockWellnessDataSource.moods;

  @override
  List<String> get weekDays => MockWellnessDataSource.weekDays;

  @override
  Map<String, String> get suggestionEmojis =>
      MockWellnessDataSource.suggestionEmojis;

  @override
  List<AudioTrack> get allTracks => MockWellnessDataSource.allTracks;

  @override
  List<({String id, String label, String emoji})> get audioCategories =>
      MockWellnessDataSource.audioCategories;

  @override
  Map<int, List<MoodTrack>> get moodTracks => MockWellnessDataSource.moodTracks;

  @override
  List<({int id, String name, int score, String avatar, int streak, bool isMe})>
      get teamMembers => MockWellnessDataSource.teamMembers;

  @override
  List<({String id, String name, int members, String emoji})> get existingGroups =>
      MockWellnessDataSource.existingGroups;

  @override
  List<HabitRecord> generateMockHistory() =>
      MockWellnessDataSource.generateMockHistory();

  @override
  List<RoutineSuggestion> getRoutineSuggestions(
    EnergyLevel? energy,
    int? mood,
  ) =>
      MockWellnessDataSource.getRoutineSuggestions(energy, mood);
}
