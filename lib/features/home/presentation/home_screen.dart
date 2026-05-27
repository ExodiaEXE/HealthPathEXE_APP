import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/shared/data/mock_data.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _moodMusicPlaying = false;
  int _moodTrackIdx = 0;
  bool _moodDismissed = false;

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
    final habits = app.getActiveHabits();
    final completed =
        habits.where((h) => app.todayCheckedHabits.contains(h.id)).length;
    final suggestions =
        MockData.getRoutineSuggestions(app.energyLevel, app.selectedMood);
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

        // Mood Music Player
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: app.selectedMood != null && !_moodDismissed
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildMoodPlayer(app),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),

        // Energy Selector
        Text('Mức năng lượng',
            style: AppTypography.section.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(MockData.energyOptions.length, (i) {
            final e = MockData.energyOptions[i];
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
                  onTap: () => app.setEnergyLevel(e.level),
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
              const Text('Routine của bạn',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.foreground)),
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
          ...List.generate(habits.length, (i) {
            final h = habits[i];
            final done = app.todayCheckedHabits.contains(h.id);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (i * 60)),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - value)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HpTapScale(
                  scale: 0.98,
                  onTap: () => app.toggleTodayHabit(h.id, h.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: done
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: done
                          ? AppColors.primary.withValues(alpha: 0.04)
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: done
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: done
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            h.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: done
                                  ? AppColors.primary
                                  : AppColors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],

        // Empty state
        if (app.energyLevel == null && !app.hasCustomRoutines)
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

        // Routine Suggestions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Routine hôm nay',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.foreground)),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Xem tất cả \u2192',
                style: AppTypography.link.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (context, idx) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = suggestions[i];
              final emoji = MockData.suggestionEmojis[s.icon] ?? '💡';
              final added = app.todayCheckedHabits.contains(s.id);
              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
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
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(s.text,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(s.note,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.muted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Nhẹ',
                                style: TextStyle(
                                    fontSize: 9, color: AppColors.muted)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () =>
                              app.toggleTodayHabit(s.id, s.text),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: added
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: added
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              added ? Icons.check : Icons.add,
                              size: 12,
                              color:
                                  added ? Colors.white : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Setup routine button
        HpTapScale(
          scale: 0.98,
          onTap: () {},
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
                      const Text(
                        'Tùy chỉnh thói quen hàng ngày',
                        style: TextStyle(
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
        _buildWeeklyChart(),
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
                        Text('Nâng cấp Premium',
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
                  '✨ Daily Check-in',
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
            children: List.generate(MockData.moods.length, (i) {
              final m = MockData.moods[i];
              final active = app.selectedMood == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: HpTapScale(
                    scale: 0.93,
                    onTap: () {
                      app.setSelectedMood(i);
                      setState(() {
                        _moodTrackIdx = 0;
                        _moodMusicPlaying = true;
                        _moodDismissed = false;
                      });
                    },
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

  Widget _buildMoodPlayer(AppStateProvider app) {
    final mood = app.selectedMood!;
    final tracks = MockData.moodTracks[mood]!;
    final track = tracks[_moodTrackIdx.clamp(0, tracks.length - 1)];
    final trackColor = Color(track.color);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            trackColor.withValues(alpha: 0.08),
            trackColor.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎵', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Nhạc cho tâm trạng \'${MockData.moods[mood].label}\'',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _moodDismissed = true),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14,
                      color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tracks.length,
              separatorBuilder: (context, idx) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = tracks[i];
                final tColor = Color(t.color);
                final isCurrent = i == _moodTrackIdx;
                return GestureDetector(
                  onTap: () => setState(() {
                    _moodTrackIdx = i;
                    _moodMusicPlaying = true;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? tColor.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                      color: isCurrent
                          ? tColor.withValues(alpha: 0.08)
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(t.title,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(t.artist,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.muted),
                            maxLines: 1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() => _moodMusicPlaying = !_moodMusicPlaying),
                child: Icon(
                  _moodMusicPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(
                    () => _moodTrackIdx = (_moodTrackIdx + 1) % tracks.length),
                child: const Icon(Icons.skip_next_rounded,
                    color: AppColors.foreground, size: 24),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => app.navigateTo(ActiveTab.audio),
                child: Text(
                  'Mở thư viện',
                  style: AppTypography.link.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    const data = [3, 2, 3, 2, 1, 0, 0];
    const maxVal = 3;
    final todayIdx = (DateTime.now().weekday - 1) % 7;

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
              const Text('Tuần này',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = data[i];
                final h =
                    maxVal > 0 ? (val / maxVal) * 56 : 4.0;
                final isToday = i == todayIdx;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: h.clamp(4, 56)),
                        duration: Duration(milliseconds: 400 + i * 50),
                        curve: Curves.easeOut,
                        builder: (context, value, child) => Container(
                          height: value,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: val > 0
                                ? (isToday
                                    ? AppColors.primary
                                    : AppColors.primary
                                        .withValues(alpha: 0.6))
                                : const Color(0xFFF0F0F0),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        MockData.weekDays[i],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? AppColors.primary
                              : const Color(0xFFBBBBBB),
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
}
