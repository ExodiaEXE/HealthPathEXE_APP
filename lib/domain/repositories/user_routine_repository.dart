import 'package:health/domain/entities/complete_routine_result.dart';
import 'package:health/domain/entities/recurring_template_entities.dart';
import 'package:health/domain/entities/user_routine_entities.dart';
import 'package:health/domain/entities/weekly_plan_sync_result.dart';
import 'package:health/shared/models/app_models.dart';

abstract class UserRoutineRepository {
  bool get isOnline;

  Future<List<UserRoutineRecord>> fetchScheduleForDate(DateTime date);

  Future<CompleteRoutineResult> completeRoutineForToday({
    required String routineId,
    int? durationMinutes,
  });

  Future<List<RecurringTemplateRecord>> fetchRecurringTemplates();

  Future<bool> createRecurringTemplate({
    required String routineId,
    required List<int> daysOfWeek,
    String scheduledTime = '09:00:00',
  });

  Future<bool> deleteRecurringTemplate(String templateId);

  /// Đồng bộ plan 7 ngày lên API (recurring templates).
  Future<WeeklyPlanSyncResult> syncWeeklyPlan(Map<int, List<RoutineItem>> plan);
}