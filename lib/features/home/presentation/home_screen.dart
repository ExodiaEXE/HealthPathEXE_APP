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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final habits = app.getActiveHabits();
    final completed = habits.where((h) => app.todayCheckedHabits.contains(h.id)).length;
    final suggestions = MockData.getRoutineSuggestions(app.energyLevel, app.selectedMood);
    final today = DateTime.now();
    const dayNames = ['Chu nhat', 'Thu Hai', 'Thu Ba', 'Thu Tu', 'Thu Nam', 'Thu Sau', 'Thu Bay'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Text('${dayNames[today.weekday % 7]}, ${today.day} thang ${today.month}', style: AppTypography.caption),
        Row(
          children: [
            Expanded(child: Text('Xin chao, ${app.userName} 👋', style: AppTypography.display.copyWith(fontSize: 20))),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('🌿', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _checkInCard(app),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: app.selectedMood != null && !_moodDismissed
              ? Padding(padding: const EdgeInsets.only(top: 12), child: _moodPlayer(app))
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        const Text('Muc nang luong', style: AppTypography.section),
        const SizedBox(height: 8),
        Row(
          children: MockData.energyOptions.map((e) {
            final active = app.energyLevel == e.level;
            final borderColor = active
                ? (e.level == EnergyLevel.low
                    ? const Color(0xFFD45A5A)
                    : e.level == EnergyLevel.medium
                        ? AppColors.coral
                        : AppColors.primary)
                : AppColors.border;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: HpTapScale(
                  scale: 0.95,
                  onTap: () => app.setEnergyLevel(e.level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: active ? borderColor.withValues(alpha: 0.08) : Colors.white,
                      boxShadow: active
                          ? [BoxShadow(color: borderColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(e.emoji, style: const TextStyle(fontSize: 22)),
                        Text(e.label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (habits.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Routine cua ban', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$completed/${habits.length}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(end: habits.isEmpty ? 0.0 : completed / habits.length),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFFF0F0F0),
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          ...habits.map((h) {
            final done = app.todayCheckedHabits.contains(h.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: done ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: done ? AppColors.primary : Colors.white,
                  child: done ? const Icon(Icons.check, color: Colors.white, size: 18) : const Icon(Icons.circle_outlined, color: AppColors.border),
                ),
                title: Text(h.text, style: TextStyle(decoration: done ? TextDecoration.lineThrough : null, color: done ? AppColors.primary : AppColors.foreground)),
                onTap: () => app.toggleTodayHabit(h.id, h.text),
              ),
            );
          }),
        ],
        if (app.energyLevel == null && !app.hasCustomRoutines)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('Chon tam trang va nang luong de nhan goi y', style: TextStyle(fontSize: 12, color: AppColors.muted))),
          ),
        const SizedBox(height: 8),
        const Text('Routine hom nay', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = suggestions[i];
              final emoji = MockData.suggestionEmojis[s.icon] ?? '💡';
              return Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(s.text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 2),
                    Text(s.note, style: const TextStyle(fontSize: 9, color: AppColors.muted), maxLines: 2),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _weeklyChart(),
        const SizedBox(height: 12),
        ListTile(
          onTap: () => app.navigateTo(ActiveTab.team),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x334A90C8))),
          tileColor: const Color(0x0D4A90C8),
          leading: const Text('👥', style: TextStyle(fontSize: 22)),
          title: const Text('Nhom Exodia', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Thu thach 7 ngay - 65% hoan thanh', style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right),
        ),
        if (!app.isPremium) ...[
          const SizedBox(height: 8),
          ListTile(
            onTap: () => app.setPaymentStep(PaymentStep.plan),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.coral.withValues(alpha: 0.25))),
            tileColor: AppColors.coral.withValues(alpha: 0.05),
            leading: const Icon(Icons.workspace_premium, color: AppColors.coral),
            title: const Text('Nang cap Premium', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }

  Widget _checkInCard(AppStateProvider app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('✨ Daily Check-in', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [const Icon(Icons.local_fire_department, color: AppColors.streakOrange, size: 14), Text(' ${app.dailyStreak}', style: const TextStyle(color: AppColors.streakOrange, fontSize: 10, fontWeight: FontWeight.bold))]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Hom nay ban cam thay the nao?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)] : null,
                      ),
                      child: Column(
                        children: [
                          Text(m.emoji),
                          Text(
                            m.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active ? AppColors.darkGreen : Colors.white,
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

  Widget _moodPlayer(AppStateProvider app) {
    final mood = app.selectedMood!;
    final tracks = MockData.moodTracks[mood]!;
    final track = tracks[_moodTrackIdx.clamp(0, tracks.length - 1)];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text('Nhac cho tam trang "${MockData.moods[mood].label}"', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary))),
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _moodDismissed = true)),
              ],
            ),
            Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(track.artist, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            Row(
              children: [
                IconButton(
                  icon: Icon(_moodMusicPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppColors.primary),
                  onPressed: () => setState(() => _moodMusicPlaying = !_moodMusicPlaying),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => setState(() => _moodTrackIdx = (_moodTrackIdx + 1) % tracks.length),
                ),
                TextButton(onPressed: () => app.navigateTo(ActiveTab.audio), child: const Text('Mo thu vien', style: TextStyle(fontSize: 10))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyChart() {
    const data = [3, 2, 3, 2, 1, 0, 0];
    const max = 3;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [Icon(Icons.trending_up, color: AppColors.primary, size: 18), SizedBox(width: 6), Text('Tuan nay', style: TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final val = data[i];
                  final h = max > 0 ? (val / max) * 56 : 4.0;
                  final isToday = i == (DateTime.now().weekday - 1) % 7;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: h.clamp(4, 56),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: val > 0 ? (isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4)) : const Color(0xFFF0F0F0),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(MockData.weekDays[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isToday ? AppColors.primary : const Color(0xFFBBBBBB))),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
