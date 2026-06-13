import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/constants/routine_catalog.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/core/utils/weekly_planner_utils.dart';
import 'package:health/domain/entities/routine_entities.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:provider/provider.dart';

/// Màn hình đặt routine 7 ngày (T2–CN).
class RoutinePlannerSheet extends StatefulWidget {
  const RoutinePlannerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RoutinePlannerSheet(),
    );
  }

  @override
  State<RoutinePlannerSheet> createState() => _RoutinePlannerSheetState();
}

class _RoutinePlannerSheetState extends State<RoutinePlannerSheet> {
  late Map<int, List<RoutineItem>> _draft;
  late int _selectedDay;
  final _taskController = TextEditingController();
  bool _saving = false;
  String? _customCategory;

  bool get _canAddCustomTask =>
      _dayEditable &&
      _taskController.text.trim().isNotEmpty &&
      _customCategory != null;

  @override
  void initState() {
    super.initState();
    _taskController.addListener(_onTaskDraftChanged);
    final app = context.read<AppStateProvider>();
    _draft = app.customRoutines.map(
      (key, value) => MapEntry(key, List<RoutineItem>.from(value)),
    );
    _selectedDay = WeeklyPlannerUtils.firstEditableDayIndex();
  }

  @override
  void dispose() {
    _taskController.removeListener(_onTaskDraftChanged);
    _taskController.dispose();
    super.dispose();
  }

  void _onTaskDraftChanged() => setState(() {});

  bool get _dayEditable => WeeklyPlannerUtils.isDayEditable(_selectedDay);

  List<RoutineItem> get _dayItems =>
      List<RoutineItem>.from(_draft[_selectedDay] ?? const []);

  List<RoutineModel> get _suggestions {
    final app = context.read<AppStateProvider>();
    return app.plannerSuggestionPool;
  }

  List<String> get _categoryOptions {
    final app = context.read<AppStateProvider>();
    final fromApi =
        app.routines.map((r) => r.category.toLowerCase()).toSet();
    if (fromApi.isEmpty) {
      return List<String>.from(RoutineCatalog.categoryOrder);
    }
    final ordered = RoutineCatalog.categoryOrder
        .where((c) => fromApi.contains(c))
        .toList();
    if (!ordered.contains('other')) ordered.add('other');
    return ordered;
  }

  void _selectDay(int day) {
    setState(() => _selectedDay = day);
    if (!WeeklyPlannerUtils.isDayEditable(day)) {
      AppSnackBar.show(
        context,
        'Không thể chỉnh sửa ngày đã qua hoặc hôm nay.',
      );
    }
  }

  void _addRoutine(RoutineModel routine) {
    if (!_dayEditable) return;
    final current = _dayItems;
    if (current.any((c) => c.id.toLowerCase() == routine.id.toLowerCase())) {
      return;
    }
    setState(() {
      _draft[_selectedDay] = [
        ...current,
        RoutineItem(
          id: routine.id,
          text: routine.title,
          category: routine.category,
        ),
      ];
    });
  }

  void _addCustomTask() {
    if (!_canAddCustomTask) return;
    final text = _taskController.text.trim();
    final category = _customCategory!;
    final id = 'custom-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _draft[_selectedDay] = [
        ..._dayItems,
        RoutineItem(
          id: id,
          text: text,
          category: category,
        ),
      ];
      _taskController.clear();
      _customCategory = null;
    });
  }

  void _removeItem(String id) {
    if (!_dayEditable) return;
    setState(() {
      _draft[_selectedDay] =
          _dayItems.where((item) => item.id != id).toList();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final result =
          await context.read<AppStateProvider>().saveCustomWeeklyPlan(_draft);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackBar.show(context, result.userMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayItems = _dayItems;
    final hasEditableDay = WeeklyPlannerUtils.firstEditableDayIndex() >
        WeeklyPlannerUtils.todayWeekIndex;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Routine 7 ngày',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.foreground,
                          ),
                        ),
                        Text(
                          hasEditableDay
                              ? 'Tạo to-do list cho từng ngày'
                              : 'Tuần này không còn ngày có thể chỉnh sửa',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: List.generate(7, (i) {
                  final label = WeeklyPlannerUtils.weekDayLabels[i];
                  final active = _selectedDay == i;
                  final count = (_draft[i] ?? const []).length;
                  final editable = WeeklyPlannerUtils.isDayEditable(i);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                      child: HpTapScale(
                        scale: 0.93,
                        onTap: () => _selectDay(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : (editable
                                          ? AppColors.foreground
                                          : AppColors.muted),
                                ),
                              ),
                              if (count > 0 && active)
                                Text(
                                  '$count việc',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                )
                              else if (count > 0 && !active)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (!_dayEditable)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Ngày ${WeeklyPlannerUtils.weekDayLabels[_selectedDay]} — chỉ xem, không chỉnh sửa được.',
                  style: AppTypography.caption,
                ),
              ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (_dayEditable) ...[
                    const Text(
                      'GỢI Ý ROUTINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final routine = _suggestions[index];
                          final added = dayItems.any(
                            (c) =>
                                c.id.toLowerCase() ==
                                routine.id.toLowerCase(),
                          );
                          return HpTapScale(
                            scale: 0.93,
                            onTap: added ? null : () => _addRoutine(routine),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: added
                                      ? AppColors.primary
                                          .withValues(alpha: 0.3)
                                      : AppColors.border,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                color: added
                                    ? AppColors.primary.withValues(alpha: 0.06)
                                    : Colors.white,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    routine.title,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    added ? Icons.check : Icons.add,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TỰ THÊM VIỆC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nhập tên việc và chọn nhóm — sau đó bấm +',
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taskController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      autocorrect: true,
                      enableSuggestions: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Tự thêm việc...',
                        hintStyle: AppTypography.hint.copyWith(fontSize: 12),
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        color: AppColors.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                      onSubmitted: (_) {
                        if (_canAddCustomTask) _addCustomTask();
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categoryOptions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                final cat = _categoryOptions[index];
                                final selected = _customCategory == cat;
                                final meta = RoutineCatalog.categories[cat];
                                return HpTapScale(
                                  scale: 0.93,
                                  onTap: () =>
                                      setState(() => _customCategory = cat),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                      color: selected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.08)
                                          : Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          meta?.emoji ?? '💡',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          meta?.label ?? cat,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: selected
                                                ? AppColors.primary
                                                : AppColors.foreground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        HpTapScale(
                          scale: 0.9,
                          enabled: _canAddCustomTask,
                          onTap: _addCustomTask,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _canAddCustomTask
                                  ? AppColors.primary
                                  : AppColors.muted.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'VIỆC NGÀY ${WeeklyPlannerUtils.weekDayLabels[_selectedDay]} (${dayItems.length})'
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (dayItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.muted.withValues(alpha: 0.5),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dayEditable
                                ? 'Chưa có việc nào — thêm từ gợi ý hoặc tự nhập'
                                : 'Chưa có việc nào cho ngày này',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(dayItems.length, (i) {
                      final item = dayItems[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.text,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    RoutineCatalog.categoryLabel(item.category),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.muted.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_dayEditable)
                              IconButton(
                                onPressed: () => _removeItem(item.id),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFD45A5A),
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_saving ? 'Đang lưu...' : 'Lưu routine'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
