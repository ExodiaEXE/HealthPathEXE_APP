class RecurringTemplateRecord {
  const RecurringTemplateRecord({
    required this.id,
    required this.routineId,
    required this.daysOfWeek,
    required this.scheduledTime,
    this.routineTitle,
    this.routineCategory,
  });

  final String id;
  final String routineId;
  final List<int> daysOfWeek;
  final String scheduledTime;
  final String? routineTitle;
  final String? routineCategory;

  factory RecurringTemplateRecord.fromJson(Map<String, dynamic> json) {
    final routine = json['routine'] as Map<String, dynamic>?;
    return RecurringTemplateRecord(
      id: (json['id'] as String).toLowerCase(),
      routineId: (json['routineId'] as String).toLowerCase(),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      scheduledTime: json['scheduledTime'] as String? ?? '09:00:00',
      routineTitle: routine?['title'] as String?,
      routineCategory: (routine?['category'] as String?)?.toLowerCase(),
    );
  }
}
