import 'package:health/domain/entities/recurring_template_entities.dart';
import 'package:health/domain/entities/weekly_plan_sync_result.dart';
import 'package:health/domain/repositories/user_routine_repository.dart';
import 'package:health/shared/models/app_models.dart';

class FetchRecurringTemplatesUseCase {
  const FetchRecurringTemplatesUseCase(this._repo);

  final UserRoutineRepository _repo;

  bool get isOnline => _repo.isOnline;

  Future<List<RecurringTemplateRecord>> call() =>
      _repo.fetchRecurringTemplates();
}

class SyncWeeklyPlanUseCase {
  const SyncWeeklyPlanUseCase(this._repo);

  final UserRoutineRepository _repo;

  bool get isOnline => _repo.isOnline;

  Future<WeeklyPlanSyncResult> call(Map<int, List<RoutineItem>> plan) =>
      _repo.syncWeeklyPlan(plan);
}

Map<int, List<RoutineItem>> weeklyPlanFromRecurringTemplates(
  List<RecurringTemplateRecord> templates,
) {
  final result = <int, List<RoutineItem>>{};
  for (final template in templates) {
    final title = template.routineTitle ?? 'Routine';
    for (final apiDay in template.daysOfWeek) {
      final dayIndex = apiDay - 1;
      if (dayIndex < 0 || dayIndex > 6) continue;
      final list = result.putIfAbsent(dayIndex, () => []);
      final rid = template.routineId.toLowerCase();
      if (list.any((item) => item.id.toLowerCase() == rid)) continue;
      list.add(RoutineItem(
        id: rid,
        text: title,
        category: template.routineCategory ?? 'other',
      ));
    }
  }
  return result;
}
