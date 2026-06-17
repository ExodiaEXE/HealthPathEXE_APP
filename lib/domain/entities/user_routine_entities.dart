class UserRoutineRecord {
  const UserRoutineRecord({
    required this.id,
    required this.routineId,
    required this.status,
    this.scheduledAt,
    this.completedAt,
    this.actualDurationMinutes,
  });

  final String id;
  final String routineId;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final int? actualDurationMinutes;

  bool get isCompleted => status == 'completed';

  factory UserRoutineRecord.fromJson(Map<String, dynamic> json) =>
      UserRoutineRecord(
        id: (json['id'] as String).toLowerCase(),
        routineId: (json['routineId'] as String).toLowerCase(),
        status: json['status'] as String? ?? 'pending',
        scheduledAt: json['scheduledAt'] != null
            ? DateTime.tryParse(json['scheduledAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        actualDurationMinutes: json['actualDurationMinutes'] as int?,
      );
}
