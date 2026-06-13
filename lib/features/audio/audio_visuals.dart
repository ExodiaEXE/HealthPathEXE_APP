import 'package:health/shared/models/app_models.dart';

/// Emoji + màu mock gán theo category API (không dùng coverUrl từ server).
class AudioVisuals {
  AudioVisuals._();

  static const _palette = <String, ({int color, String emoji})>{
    'meditation': (color: 0xFF5B8C4A, emoji: '🧘'),
    'sleep': (color: 0xFF8A7EC8, emoji: '🌙'),
    'focus': (color: 0xFF4A90C8, emoji: '🎯'),
    'relaxation': (color: 0xFFD4855A, emoji: '🌸'),
    'nature': (color: 0xFF7AB86D, emoji: '🌿'),
    'breathing': (color: 0xFF5B8C4A, emoji: '💮'),
    'soft': (color: 0xFF8A7EC8, emoji: '🌸'),
    'acoustic': (color: 0xFF7AB86D, emoji: '🎸'),
    'ambient': (color: 0xFF8A7EC8, emoji: '✨'),
  };

  static const categoryLabels = <String, String>{
    'meditation': 'Thiền',
    'sleep': 'Ngủ ngon',
    'focus': 'Tập trung',
    'relaxation': 'Thư giãn',
    'nature': 'Thiên nhiên',
    'breathing': 'Hít thở',
  };

  static int colorFor(String category) =>
      _palette[category.toLowerCase()]?.color ?? 0xFF4A90C8;

  static String emojiFor(String category) =>
      _palette[category.toLowerCase()]?.emoji ?? '🎵';

  static String labelFor(String category) =>
      categoryLabels[category.toLowerCase()] ??
      (category.isEmpty
          ? 'Khác'
          : '${category[0].toUpperCase()}${category.substring(1)}');

  static bool isRecommendedForEnergy(String category, EnergyLevel? energyLevel) {
    if (energyLevel == null) return false;
    final cat = category.toLowerCase();
    switch (energyLevel) {
      case EnergyLevel.low:
        return {
          'meditation',
          'sleep',
          'relaxation',
          'nature',
          'breathing',
        }.contains(cat);
      case EnergyLevel.medium:
        return {
          'relaxation',
          'nature',
          'focus',
          'meditation',
        }.contains(cat);
      case EnergyLevel.high:
        return {'focus', 'relaxation'}.contains(cat);
    }
  }
}
