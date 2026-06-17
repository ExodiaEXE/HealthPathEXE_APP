class MoodCheckinRecord {
  const MoodCheckinRecord({
    required this.id,
    required this.mood,
    required this.energyLevel,
    required this.streakDay,
    required this.checkedAt,
    this.note,
  });

  final String id;
  final String mood;
  final String energyLevel;
  final int streakDay;
  final DateTime checkedAt;
  final String? note;

  factory MoodCheckinRecord.fromJson(Map<String, dynamic> json) =>
      MoodCheckinRecord(
        id: json['id'] as String,
        mood: json['mood'] as String? ?? '',
        energyLevel: json['energyLevel'] as String? ?? '',
        streakDay: json['streakDay'] as int? ?? 1,
        note: json['note'] as String?,
        checkedAt: DateTime.tryParse(json['checkedAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
}

class MoodStats {
  const MoodStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCheckins,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalCheckins;

  factory MoodStats.fromJson(Map<String, dynamic> json) => MoodStats(
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        totalCheckins: json['totalCheckins'] as int? ?? 0,
      );
}
