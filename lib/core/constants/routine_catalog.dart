import 'package:health/domain/entities/routine_entities.dart';

/// Metadata category + icon — map seed backend ↔ emoji mock mobile.
abstract final class RoutineCatalog {
  static const groupOrder = ['health', 'mental', 'lifestyle'];

  static const groups = {
    'health': (label: 'Sức khỏe thể chất', emoji: '💪'),
    'mental': (label: 'Tinh thần & thư giãn', emoji: '🧠'),
    'lifestyle': (label: 'Giải trí & thói quen', emoji: '🌿'),
  };

  static const categoryOrder = [
    'exercise',
    'yoga',
    'meditation',
    'breathing',
    'reading',
    'other',
  ];

  static const categories = {
    'exercise': (
      label: 'Vận động',
      emoji: '🏋️',
      group: 'health',
    ),
    'yoga': (
      label: 'Yoga',
      emoji: '🧘',
      group: 'health',
    ),
    'meditation': (
      label: 'Thiền',
      emoji: '🧠',
      group: 'mental',
    ),
    'breathing': (
      label: 'Hơi thở',
      emoji: '🌬️',
      group: 'mental',
    ),
    'reading': (
      label: 'Đọc & nghe',
      emoji: '📚',
      group: 'lifestyle',
    ),
    'other': (
      label: 'Thói quen ngày',
      emoji: '☕',
      group: 'lifestyle',
    ),
  };

  static const difficultyLabels = {
    'easy': 'Nhẹ',
    'medium': 'Vừa',
    'hard': 'Khó',
  };

  static String difficultyLabel(String difficulty) =>
      difficultyLabels[difficulty.toLowerCase()] ?? difficulty;

  static String categoryLabel(String category) =>
      categories[category.toLowerCase()]?.label ?? category;

  static String categoryEmoji(String category) =>
      categories[category.toLowerCase()]?.emoji ?? '💡';

  /// Icon emoji cho từng routine — ưu tiên thumbnailUrl ở UI, đây là fallback.
  static String routineEmoji(RoutineModel routine) {
    final t = routine.title.toLowerCase();
    if (t.contains('nước') || t.contains('uống')) return '☕';
    if (t.contains('biết ơn')) return '✏️';
    if (t.contains('mục tiêu')) return '🎯';
    if (t.contains('nhạc')) return '🎵';
    if (t.contains('vẽ') || t.contains('tô màu')) return '🎨';
    if (t.contains('bữa sáng') || t.contains('ăn')) return '🥗';
    if (t.contains('đi bộ') || t.contains('đi dạo') || t.contains('chạy bộ')) {
      return '🚶';
    }
    if (t.contains('giãn cơ') || t.contains('kéo giãn')) return '🧘';
    if (t.contains('squat') || t.contains('plank') || t.contains('hiit')) {
      return '🏋️';
    }
    if (t.contains('podcast')) return '🎧';
    if (t.contains('sách') || t.contains('đọc')) return '📚';
    if (t.contains('nhật ký')) return '✏️';
    if (t.contains('video')) return '🎯';
    if (t.contains('thiền') || t.contains('body scan')) return '🧠';
    if (t.contains('thở')) return '🌬️';
    if (routine.category == 'yoga') return '🧘';
    return categoryEmoji(routine.category);
  }

  static List<RoutineUiGroup> groupRoutines(List<RoutineModel> routines) {
    final byCategory = <String, List<RoutineModel>>{};
    for (final r in routines) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }

    final result = <RoutineUiGroup>[];
    for (final groupId in groupOrder) {
      final meta = groups[groupId]!;
      final sections = <RoutineCategorySection>[];

      for (final cat in categoryOrder) {
        final catMeta = categories[cat];
        if (catMeta == null || catMeta.group != groupId) continue;
        final items = byCategory[cat];
        if (items == null || items.isEmpty) continue;
        sections.add(
          RoutineCategorySection(
            category: cat,
            label: catMeta.label,
            emoji: catMeta.emoji,
            routines: List<RoutineModel>.from(items),
          ),
        );
      }

      if (sections.isNotEmpty) {
        result.add(
          RoutineUiGroup(
            id: groupId,
            label: meta.label,
            emoji: meta.emoji,
            sections: sections,
          ),
        );
      }
    }
    return result;
  }

  /// Slot gợi ý — map 1:1 pool `remove-companion` (rs1–rs12) ↔ seed API.
  static const _suggestionSlots = <({List<String> keywords, String category})>[
    (keywords: ['yoga'], category: 'yoga'),
    (keywords: ['đọc sách'], category: 'reading'),
    (keywords: ['thiền 5'], category: 'meditation'),
    (keywords: ['nhật ký'], category: 'reading'),
    (keywords: ['nước', 'uống'], category: 'other'),
    (keywords: ['giãn cơ'], category: 'exercise'),
    (keywords: ['podcast'], category: 'reading'),
    (keywords: ['đi bộ'], category: 'exercise'),
    (keywords: ['thở bụng', 'thở sâu'], category: 'breathing'),
    (keywords: ['mục tiêu'], category: 'other'),
    (keywords: ['nhạc'], category: 'other'),
    (keywords: ['plank'], category: 'exercise'),
  ];

  /// Thứ tự ưu tiên giống `getRoutineSuggestions` trong remove-companion.
  static List<int> suggestionSlotIndices({String? energyKey, int? mood}) {
    if (mood == 0 && energyKey == 'low') return [0, 2, 8, 10, 4];
    if (mood == 0) return [0, 2, 4, 8, 10];
    if (mood == 2 && energyKey == 'high') return [11, 7, 5, 9, 1];
    if (mood == 2) return [3, 8, 5, 9, 2];
    if (energyKey == 'low') return [0, 2, 4, 8, 10];
    if (energyKey == 'medium') return [1, 3, 5, 7, 9];
    if (energyKey == 'high') return [5, 7, 9, 11, 1];
    if (mood == 1) return [1, 3, 5, 7, 9];
    return [0, 1, 2, 3, 4];
  }

  static RoutineModel? _matchSlot(
    List<RoutineModel> pool,
    int slotIndex,
    Set<String> usedIds,
  ) {
    if (slotIndex < 0 || slotIndex >= _suggestionSlots.length) return null;
    final slot = _suggestionSlots[slotIndex];
    RoutineModel? best;
    var bestScore = 0;

    for (final routine in pool) {
      if (usedIds.contains(routine.id)) continue;
      var score = 0;
      final title = routine.title.toLowerCase();
      for (final keyword in slot.keywords) {
        if (title.contains(keyword)) score += 10;
      }
      if (routine.category == slot.category) score += 3;
      if (score > bestScore) {
        bestScore = score;
        best = routine;
      }
    }
    return best;
  }

  /// Gợi ý routine trên Home — logic remove-companion, áp lên catalog API.
  static List<RoutineModel> pickHomeHighlights(
    List<RoutineModel> all, {
    String? energyKey,
    int? mood,
    int limit = 5,
  }) {
    if (all.isEmpty) return const [];

    final indices = suggestionSlotIndices(energyKey: energyKey, mood: mood);
    final used = <String>{};
    final result = <RoutineModel>[];

    for (final slotIndex in indices) {
      if (result.length >= limit) break;
      final match = _matchSlot(all, slotIndex, used);
      if (match != null) {
        result.add(match);
        used.add(match.id);
      }
    }

    if (result.length < limit) {
      for (final routine in all) {
        if (result.length >= limit) break;
        if (!used.contains(routine.id)) {
          result.add(routine);
          used.add(routine.id);
        }
      }
    }
    return result;
  }
}
