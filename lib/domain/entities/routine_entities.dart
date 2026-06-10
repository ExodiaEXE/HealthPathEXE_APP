/// Routine từ API `GET /api/Routine` — khớp `RoutineDto` backend.
class RoutineModel {
  const RoutineModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    this.isPremium = false,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String? description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final bool isPremium;
  final String? thumbnailUrl;

  factory RoutineModel.fromJson(Map<String, dynamic> json) => RoutineModel(
        id: (json['id'] as String).toLowerCase(),
        title: json['title'] as String,
        description: json['description'] as String?,
        category: (json['category'] as String?)?.toLowerCase() ?? 'other',
        difficulty: (json['difficulty'] as String?)?.toLowerCase() ?? 'easy',
        durationMinutes: json['durationMinutes'] as int? ?? 10,
        isPremium: json['isPremium'] == true,
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );
}

/// Một nhóm UI (sức khỏe / tinh thần / giải trí) chứa nhiều category.
class RoutineUiGroup {
  const RoutineUiGroup({
    required this.id,
    required this.label,
    required this.emoji,
    required this.sections,
  });

  final String id;
  final String label;
  final String emoji;
  final List<RoutineCategorySection> sections;
}

/// Routine theo category backend (exercise, yoga, …).
class RoutineCategorySection {
  const RoutineCategorySection({
    required this.category,
    required this.label,
    required this.emoji,
    required this.routines,
  });

  final String category;
  final String label;
  final String emoji;
  final List<RoutineModel> routines;
}
