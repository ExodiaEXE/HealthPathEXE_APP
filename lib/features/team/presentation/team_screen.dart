import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/shared/data/mock_data.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  String _noTeamPage = 'main';
  final _newGroupName = TextEditingController();
  final _joinSearch = TextEditingController();
  final _cheered = <int>{};
  bool _showCheckInToast = false;
  bool _inviteSheetOpen = false;

  @override
  void dispose() {
    _newGroupName.dispose();
    _joinSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    if (!app.hasTeam) return _buildNoTeamView(app);
    return _teamDashboard(app);
  }

  // ─── NO-TEAM VIEW ───────────────────────────────────────────────────────────

  Widget _buildNoTeamView(AppStateProvider app) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _noTeamPage == 'create'
          ? _buildCreateGroup(app)
          : _noTeamPage == 'join'
              ? _buildJoinGroup(app)
              : _buildNoTeamMain(),
    );
  }

  Widget _buildNoTeamMain() {
    return ListView(
      key: const ValueKey('no-team-main'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text('Nhóm', style: AppTypography.title),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups, size: 48, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bạn chưa có nhóm',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.foreground),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tạo nhóm mới hoặc tham gia nhóm đã có sẵn để cùng nhau rèn luyện sức khỏe',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        _buildActionCard(
          onTap: () => setState(() => _noTeamPage = 'create'),
          backgroundColor: AppColors.primary,
          icon: Icons.add,
          iconBgColor: Colors.white.withValues(alpha: 0.2),
          iconColor: Colors.white,
          title: 'Tạo nhóm mới',
          titleColor: Colors.white,
          subtitle: 'Mời bạn bè cùng tham gia',
          subtitleColor: Colors.white.withValues(alpha: 0.7),
          chevronColor: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          onTap: () => setState(() => _noTeamPage = 'join'),
          backgroundColor: Colors.white,
          borderColor: AppColors.border,
          icon: Icons.login,
          iconBgColor: AppColors.accent.withValues(alpha: 0.1),
          iconColor: AppColors.accent,
          title: 'Tham gia nhóm',
          titleColor: AppColors.foreground,
          subtitle: 'Tìm và tham gia nhóm đã có',
          subtitleColor: AppColors.muted,
          chevronColor: AppColors.muted,
        ),
        const SizedBox(height: 20),
        _buildBenefitsCard(),
      ],
    );
  }

  Widget _buildActionCard({
    required VoidCallback onTap,
    required Color backgroundColor,
    Color? borderColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String subtitle,
    required Color subtitleColor,
    required Color chevronColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: titleColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: chevronColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsCard() {
    const benefits = [
      ('🏆', 'Thử thách nhóm hàng tuần'),
      ('🔥', 'Động lực từ bạn bè'),
      ('📈', 'Bảng xếp hạng nhóm'),
      ('🤝', 'Cổ vũ và hỗ trợ lẫn nhau'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LỢI ÍCH KHI CÓ NHÓM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(b.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(b.$2, style: const TextStyle(fontSize: 13, color: AppColors.foreground)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── CREATE GROUP ───────────────────────────────────────────────────────────

  Widget _buildCreateGroup(AppStateProvider app) {
    final isValid = _newGroupName.text.trim().isNotEmpty;
    return Padding(
      key: const ValueKey('create-group'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _backButton(() => setState(() => _noTeamPage = 'main')),
              const SizedBox(width: 12),
              const Text(
                'Tạo nhóm mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups, size: 32, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tên nhóm',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newGroupName,
            maxLength: 30,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'VD: Nhóm Sức Khỏe',
              hintStyle: AppTypography.hint,
              counterText: '${_newGroupName.text.length}/30',
              counterStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: isValid
                ? () {
                    app.setHasTeam(true, name: _newGroupName.text.trim());
                    setState(() {
                      _noTeamPage = 'main';
                      _newGroupName.clear();
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: isValid ? AppColors.primary : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                'Tạo nhóm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isValid ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── JOIN GROUP ─────────────────────────────────────────────────────────────

  Widget _buildJoinGroup(AppStateProvider app) {
    final groups = MockData.existingGroups
        .where((g) => g.name.toLowerCase().contains(_joinSearch.text.toLowerCase()))
        .toList();

    return Column(
      key: const ValueKey('join-group'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(() => setState(() {
                        _noTeamPage = 'main';
                        _joinSearch.clear();
                      })),
                  const SizedBox(width: 12),
                  const Text(
                    'Tham gia nhóm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _joinSearch,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm nhóm...',
                  hintStyle: AppTypography.hint,
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'NHÓM PHỔ BIẾN (${groups.length})',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? _buildEmptySearch()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: groups.length,
                  separatorBuilder: (context, idx) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final g = groups[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(g.emoji, style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                Text('${g.members} thành viên', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              app.setHasTeam(true, name: g.name);
                              setState(() {
                                _noTeamPage = 'main';
                                _joinSearch.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Tham gia',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy nhóm nào',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TEAM DASHBOARD ─────────────────────────────────────────────────────────

  Widget _teamDashboard(AppStateProvider app) {
    final inviteCode =
        'HP-${app.teamName.replaceAll(' ', '').substring(0, app.teamName.length.clamp(0, 4)).toUpperCase()}-2026';
    final habits = app.getActiveHabits();
    final completed = habits.where((h) => app.todayCheckedHabits.contains(h.id)).length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _buildDashboardHeader(app),
            const SizedBox(height: 16),
            if (_showCheckInToast) _buildCheckInToast(),
            _buildChallengeCard(),
            const SizedBox(height: 20),
            _buildSharedHabits(app, habits, completed),
            const SizedBox(height: 20),
            _buildLeaderboard(),
            const SizedBox(height: 20),
            _buildMotivationalQuote(),
          ],
        ),
        if (_inviteSheetOpen) _buildInviteOverlay(app, inviteCode),
      ],
    );
  }

  Widget _buildDashboardHeader(AppStateProvider app) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('👥', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.teamName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Text('4 thành viên', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _inviteSheetOpen = true),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_outlined, size: 18, color: AppColors.accent),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (!app.teamCheckInToday) {
              app.setTeamCheckInToday(true);
              setState(() => _showCheckInToast = true);
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) setState(() => _showCheckInToast = false);
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: app.teamCheckInToday
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              app.teamCheckInToday ? 'Đã điểm danh' : 'Điểm danh',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: app.teamCheckInToday ? AppColors.primary : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInToast() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.star, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tuyệt vời! Bạn đã điểm danh hôm nay',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    const progressValue = 0.65;
    const completedDays = 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Thử thách 7 ngày thả lỏng',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _CircularProgressPainter(progress: progressValue),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('65%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text('hoàn thành', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final isDone = i < completedDays;
              return Container(
                width: 28,
                height: 28,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: isDone ? null : Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedHabits(AppStateProvider app, List<RoutineItem> habits, int completed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nhiệm vụ nhóm hôm nay',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
            ),
            Text(
              '$completed/${habits.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty) _buildNoHabitsInfo() else ...habits.map((h) => _buildHabitItem(app, h)),
      ],
    );
  }

  Widget _buildNoHabitsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chưa có nhiệm vụ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => context.read<AppStateProvider>().navigateTo(ActiveTab.home),
                  child: const Text(
                    'Đặt routine hoặc chọn năng lượng ở Trang chủ',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(AppStateProvider app, RoutineItem h) {
    final done = app.todayCheckedHabits.contains(h.id);
    return GestureDetector(
      onTap: () => app.toggleTodayHabit(h.id, h.text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: done ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: done ? null : Border.all(color: AppColors.border, width: 2),
              ),
              child: done ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                h.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: done ? AppColors.muted : AppColors.foreground,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LEADERBOARD ────────────────────────────────────────────────────────────

  Widget _buildLeaderboard() {
    final members = List.of(MockData.teamMembers)..sort((a, b) => b.score.compareTo(a.score));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BẢNG XẾP HẠNG',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ...List.generate(members.length, (i) {
          final m = members[i];
          final rank = i + 1;
          final isFirst = rank == 1;
          final isCheered = _cheered.contains(m.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isFirst ? const Color(0xFFE8A87C) : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isFirst
                      ? const Icon(Icons.emoji_events, size: 13, color: Colors.white)
                      : Text('$rank', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m.avatar,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      if (m.isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BẠN',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (d) {
                    final filled = d < m.score;
                    return Container(
                      width: 14,
                      height: 14,
                      margin: EdgeInsets.only(left: d == 0 ? 0 : 2),
                      decoration: BoxDecoration(
                        color: filled ? AppColors.primary : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: filled ? const Icon(Icons.check, size: 9, color: Colors.white) : null,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                if (!m.isMe)
                  GestureDetector(
                    onTap: () => setState(() => _cheered.add(m.id)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCheered
                            ? AppColors.destructive.withValues(alpha: 0.1)
                            : AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCheered ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isCheered ? AppColors.destructive : AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMotivationalQuote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, size: 20, color: AppColors.accent.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Mỗi bước nhỏ hôm nay là nền tảng cho sức khỏe ngày mai. Hãy cùng nhau tiến bước!',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INVITE MODAL ───────────────────────────────────────────────────────────

  Widget _buildInviteOverlay(AppStateProvider app, String inviteCode) {
    return GestureDetector(
      onTap: () => setState(() => _inviteSheetOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mời thành viên',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _inviteSheetOpen = false),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: AppColors.foreground),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_outlined, size: 26, color: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chia sẻ mã mời để bạn bè tham gia nhóm "${app.teamName}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          inviteCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Clipboard.setData(ClipboardData(text: inviteCode)),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.copy, size: 16, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      setState(() => _inviteSheetOpen = false);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Chia sẻ mã mời',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── COMMON WIDGETS ─────────────────────────────────────────────────────────

  Widget _backButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_left, size: 20, color: AppColors.foreground),
      ),
    );
  }
}

// ─── CIRCULAR PROGRESS PAINTER ──────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 52.0;
    const strokeWidth = 7.0;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
