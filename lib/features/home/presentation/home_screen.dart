import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/features/home/presentation/habits_all_sheet.dart';
import 'package:health/features/home/presentation/routine_planner_sheet.dart';
import 'package:health/features/home/presentation/routine_all_sheet.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:health/shared/widgets/habit_row_tile.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:health/shared/widgets/routine_suggestion_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppStateProvider>();
      if (app.homeDataLoading || app.routines.isNotEmpty || app.routinesLoading) {
        return;
      }
      await app.loadRoutineCatalog();
      await app.loadWeeklyPlanFromApiIfNeeded();
      await app.loadTodayCompletedRoutines();
    });
  }

  static const _moodColors = [
    Color(0xFFD45A5A),
    Color(0xFFD4855A),
    Color(0xFF4A90C8),
  ];

  static const _energyColors = [
    Color(0xFFD45A5A),
    Color(0xFFD4855A),
    Color(0xFF3D7A2E),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    if (app.homeDataLoading || (app.routines.isEmpty && app.routinesLoading)) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    final w = app.wellness;
    final habits = app.getActiveHabits();
    final visibleHabits = habits.take(5).toList();
    final completed =
        habits.where((h) => app.isHabitCompleted(h.id)).length;
    final today = DateTime.now();
    const dayNames = [
      'Chủ nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];

    if (app.habitCompleteError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final msg = app.habitCompleteError;
        if (msg == null) return;
        context.read<AppStateProvider>().clearHabitCompleteError();
        AppSnackBar.show(context, msg);
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        // Greeting section
        Text(
          '${dayNames[today.weekday % 7]}, ${today.day} tháng ${today.month}',
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Xin chào, ${app.userName} 👋',
                style: AppTypography.display.copyWith(fontSize: 20),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🌿', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Daily Check-in Card
        _buildCheckInCard(app),
        const SizedBox(height: 16),

        // Energy Selector
        Text('Mức năng lượng',
            style: AppTypography.section.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(w.energyOptions.length, (i) {
            final e = w.energyOptions[i];
            final active = app.energyLevel == e.level;
            final color = _energyColors[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 4,
                  right: i == 2 ? 0 : 4,
                ),
                child: HpTapScale(
                  scale: 0.95,
                  onTap: app.dailyCheckinLocked && !active
                      ? null
                      : () => app.setEnergyLevel(e.level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: active ? color : AppColors.border,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: active
                          ? color.withValues(alpha: 0.1)
                          : Colors.white,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(e.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          e.label,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: active ? color : AppColors.muted,
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

        // Habits/Routine section
        if (habits.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Thói quen của bạn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.foreground)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completed/${habits.length} hoàn thành',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              if (habits.length > 5) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => HabitsAllSheet.show(context),
                  child: Text(
                    'Xem tất cả \u2192',
                    style: AppTypography.link.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(
                end: habits.isEmpty ? 0.0 : completed / habits.length),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, _) => Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(visibleHabits.length, (i) {
            final h = visibleHabits[i];
            return HabitRowTile(
              key: ValueKey('habit-${h.id}'),
              habitId: h.id,
              label: h.text,
              entranceIndex: i,
            );
          }),
        ],

        // Empty state
        if (habits.isEmpty && !app.hasCustomRoutines)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.battery_charging_full_rounded,
                    color: AppColors.muted.withValues(alpha: 0.5), size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Chọn tâm trạng và năng lượng để nhận gợi ý',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Routine catalog (API)
        _buildRoutineCatalogSection(context, app),
        const SizedBox(height: 16),

        // Setup routine button
        HpTapScale(
          scale: 0.98,
          onTap: () => RoutinePlannerSheet.show(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.hasCustomRoutines
                            ? 'Chỉnh sửa routine 7 ngày'
                            : 'Tự đặt routine 7 ngày',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                      Text(
                        app.hasCustomRoutines
                            ? 'Đang áp dụng routine cá nhân'
                            : 'Tùy chỉnh thói quen hàng ngày',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Weekly Chart
        _buildWeeklyChart(app),
        const SizedBox(height: 12),

        // Team challenge link
        HpTapScale(
          scale: 0.98,
          onTap: () => app.navigateTo(ActiveTab.team),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.accent.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                const Text('👥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.teamName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const Text('Thử thách 7 ngày - 65% hoàn thành',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.accent, size: 20),
              ],
            ),
          ),
        ),

        // Premium upsell
        if (!app.isPremium) ...[
          const SizedBox(height: 12),
          HpTapScale(
            scale: 0.98,
            onTap: () => app.setPaymentStep(PaymentStep.plan),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.coral.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(16),
                color: AppColors.coral.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: AppColors.coral, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nâng cấp gói cao cấp',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('Mở khóa tất cả tính năng nâng cao',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.coral, size: 20),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckInCard(AppStateProvider app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✨ Điểm danh hàng ngày',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${app.dailyStreak}',
                      style: const TextStyle(
                        color: AppColors.streakOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Hôm nay bạn cảm thấy thế nào?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(app.wellness.moods.length, (i) {
              final m = app.wellness.moods[i];
              final active = app.selectedMood == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: HpTapScale(
                    scale: 0.93,
                    onTap: app.dailyCheckinLocked && !active
                        ? null
                        : () => app.setSelectedMood(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(m.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            m.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? _moodColors[i]
                                  : Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(AppStateProvider app) {
    final data = app.lastWeekRoutineCompletions;
    final hasData = app.hasLastWeekRoutineData;
    final maxVal = hasData
        ? data.fold<int>(0, (max, v) => v > max ? v : max)
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Tuần trước',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Số routine hoàn thành mỗi ngày (${app.lastWeekRoutineRangeLabel})',
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Bạn chưa thực hiện bất kỳ routine nào trong tuần trước.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final val = data[i];
                  final barHeight =
                      maxVal > 0 ? (val / maxVal) * 56 : 4.0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '$val',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: barHeight.clamp(4, 56)),
                          duration: Duration(milliseconds: 400 + i * 50),
                          curve: Curves.easeOut,
                          builder: (context, value, child) => Container(
                            height: value,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: val > 0
                                  ? AppColors.primary.withValues(
                                      alpha: i == 6 ? 0.85 : 0.65,
                                    )
                                  : const Color(0xFFF0F0F0),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          app.wellness.weekDays[i],
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBBBBBB),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoutineCatalogSection(BuildContext context, AppStateProvider app) {
    final items = app.homeRoutineExtras;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Routine gợi ý thêm',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.foreground,
              ),
            ),
            GestureDetector(
              onTap: () => RoutineAllSheet.show(context),
              child: Text(
                'Xem tất cả \u2192',
                style: AppTypography.link.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (app.routinesLoading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.battery_3_bar,
                    size: 36, color: AppColors.muted.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(
                  app.routinesError ??
                      (app.hasDailySuggestionFilter
                          ? 'Không có thêm gợi ý cho hôm nay'
                          : 'Đang tải danh sách routine...'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final r = items[i];
                return RoutineHomeCard(
                  routine: r,
                  added: false,
                  onToggle: () => app.addRoutineToHabits(r.id),
                );
              },
            ),
          ),
      ],
    );
  }
}
