import 'package:health/shared/models/app_models.dart';

/// Hợp đồng domain cho thói quen, âm thanh, nhóm — tách khỏi nguồn mock/API.
abstract class WellnessRepository {
  Map<EnergyLevel, List<RoutineItem>> get habitsByEnergy;
  List<({EnergyLevel level, String label, String emoji})> get energyOptions;
  List<({String emoji, String label})> get moods;
  List<String> get weekDays;
  Map<String, String> get suggestionEmojis;
  List<AudioTrack> get allTracks;
  List<({String id, String label, String emoji})> get audioCategories;
  Map<int, List<MoodTrack>> get moodTracks;
  List<({int id, String name, int score, String avatar, int streak, bool isMe})>
      get teamMembers;
  List<({String id, String name, int members, String emoji})> get existingGroups;

  List<HabitRecord> generateMockHistory();
  List<RoutineSuggestion> getRoutineSuggestions(
    EnergyLevel? energy,
    int? mood,
  );
}
