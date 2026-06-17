import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/domain/entities/group_entities.dart';
import 'package:health/domain/usecases/wellness/wellness_content_usecase.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/features/home/presentation/habits_all_sheet.dart';
import 'package:health/features/team/presentation/create_group_screen.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:health/shared/widgets/habit_row_tile.dart';
import 'package:provider/provider.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  WellnessContentUseCase get _content =>
      context.read<AppStateProvider>().wellness;

  /// main | manage | dashboard | join
  String _teamPage = 'main';
  final _joinSearch = TextEditingController();
  bool _showCheckInToast = false;
  bool _inviteSheetOpen = false;
  String? _openingGroupId;
  String? _joiningGroupId;

  @override
  void dispose() {
    _joinSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    if (_teamPage == 'dashboard' && app.hasTeam) {
      return _teamDashboard(app);
    }

    if (_teamPage == 'join') {
      return _JoinGroupPage(
        key: const ValueKey('join-group'),
        controller: _joinSearch,
        onBack: () => setState(() {
          _teamPage = 'main';
          _joinSearch.clear();
        }),
        buildJoinRow: _buildJoinRow,
        buildEmptySearch: _buildEmptySearch,
        buildLoadingList: _buildJoinLoadingList,
      );
    }

    if (_teamPage == 'manage') {
      return _buildManageTeamsView(app);
    }

    if (app.teamLoading && !app.hasAnyTeam) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildTeamMainPage(app);
  }

  // ─── TRANG NHÓM CHÍNH ───────────────────────────────────────────────────────

  Widget _buildTeamMainPage(AppStateProvider app) {
    final hasTeams = app.hasAnyTeam;
    return ListView(
      key: const ValueKey('team-main'),
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
        Text(
          hasTeams ? 'Nhóm sức khỏe của bạn' : 'Bạn chưa có nhóm',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasTeams
              ? 'Tạo nhóm mới, tham gia nhóm khác hoặc quản lý các nhóm đang tham gia'
              : 'Tạo nhóm mới hoặc tham gia nhóm đã có sẵn để cùng nhau rèn luyện sức khỏe',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        _buildActionCard(
          onTap: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            );
            if (created == true && mounted) {
              setState(() => _teamPage = 'dashboard');
            }
          },
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
          onTap: () {
            setState(() => _teamPage = 'join');
            context.read<AppStateProvider>().searchPublicGroups('');
          },
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
        if (hasTeams) ...[
          const SizedBox(height: 12),
          _buildActionCard(
            onTap: () => setState(() => _teamPage = 'manage'),
            backgroundColor: Colors.white,
            borderColor: AppColors.border,
            icon: Icons.folder_shared_outlined,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
            title: 'Quản lý nhóm',
            titleColor: AppColors.foreground,
            subtitle: '${app.myTeams.length} nhóm đang tham gia',
            subtitleColor: AppColors.muted,
            chevronColor: AppColors.muted,
          ),
        ],
        if (!hasTeams) ...[
          const SizedBox(height: 20),
          _buildBenefitsCard(),
        ],
      ],
    );
  }

  Widget _buildJoinLoadingList() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
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
                    Expanded(
                      child: Text(b.$2,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.foreground)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildJoinRow({
    required AppStateProvider app,
    required String emoji,
    required String name,
    required int memberCount,
    required String groupId,
    required Future<bool> Function() onJoin,
  }) {
    final isJoining = _joiningGroupId == groupId;
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
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text('$memberCount thành viên',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: (_joiningGroupId != null && !isJoining)
                ? null
                : () async {
                    setState(() => _joiningGroupId = groupId);
                    final ok = await onJoin();
                    if (!mounted) return;
                    setState(() => _joiningGroupId = null);
                    if (ok) {
                      setState(() {
                        _joinSearch.clear();
                        _teamPage = 'dashboard';
                      });
                    } else if (app.teamError != null) {
                      AppSnackBar.show(context, app.teamError!);
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isJoining
                    ? AppColors.accent.withValues(alpha: 0.6)
                    : AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isJoining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Tham gia',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required String name,
    required String avatar,
    required int points,
    required bool isMe,
    required int rank,
  }) {
    final isFirst = rank == 1;
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
                : Text('$rank',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted)),
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
              avatar,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BẠN',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$points điểm',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
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

  // ─── QUẢN LÝ NHÓM ───────────────────────────────────────────────────────────

  Widget _buildManageTeamsView(AppStateProvider app) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: app.loadTeamState,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Row(
                children: [
                  _TeamBackButton(
                    onTap: _openingGroupId == null
                        ? () => setState(() => _teamPage = 'main')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Quản lý nhóm',
                      style: AppTypography.title,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${app.myTeams.length} nhóm đang tham gia',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              if (app.myTeams.isEmpty)
                _buildEmptyManageTeams()
              else
                ...app.myTeams.map(_buildManageGroupCard),
            ],
          ),
        ),
        if (_openingGroupId != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyManageTeams() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, size: 40, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'Bạn chưa tham gia nhóm nào',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Tạo hoặc tham gia nhóm từ trang Nhóm',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildManageGroupCard(GroupRecord group) {
    final isOpening = _openingGroupId == group.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _openingGroupId != null
            ? null
            : () async {
                setState(() => _openingGroupId = group.id);
                await context.read<AppStateProvider>().openTeamGroup(group);
                if (!mounted) return;
                setState(() {
                  _openingGroupId = null;
                  _teamPage = 'dashboard';
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOpening ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOpening ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (group.description != null && group.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        group.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} thành viên',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (isOpening)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeaveTeam(AppStateProvider app) async {
    final isLastMember = app.teamMemberCount <= 1;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLastMember ? Icons.group_remove_outlined : Icons.logout_rounded,
                  color: AppColors.destructive,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isLastMember ? 'Rời nhóm và giải tán?' : 'Rời nhóm?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isLastMember
                    ? 'Bạn là thành viên cuối cùng còn lại. Nếu rời nhóm, nhóm "${app.teamName}" sẽ bị xóa và không thể khôi phục.'
                    : 'Bạn có chắc muốn rời khỏi nhóm "${app.teamName}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.destructive,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isLastMember ? 'Rời và giải tán' : 'Rời nhóm',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final message = await app.leaveCurrentTeam();
    if (!mounted) return;

    final stillHasTeams = context.read<AppStateProvider>().hasAnyTeam;
    setState(() => _teamPage = stillHasTeams ? 'manage' : 'main');

    if (message != null && message.isNotEmpty) {
      AppSnackBar.show(context, message);
    }
  }

  // ─── TEAM DASHBOARD ─────────────────────────────────────────────────────────

  Widget _teamDashboard(AppStateProvider app) {
    final inviteCode = app.teamInviteCode.isNotEmpty
        ? app.teamInviteCode
        : 'HP-${app.teamName.replaceAll(' ', '').substring(0, app.teamName.length.clamp(0, 4)).toUpperCase()}-2026';
    final habits = app.getActiveHabits();
    final completed = habits.where((h) => app.isHabitCompleted(h.id)).length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _buildDashboardHeader(app),
            const SizedBox(height: 16),
            if (_showCheckInToast) _buildCheckInToast(),
            _buildChallengeCard(app),
            const SizedBox(height: 20),
            _buildSharedHabits(app, habits, completed),
            const SizedBox(height: 20),
            _buildLeaderboard(app),
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
        GestureDetector(
          onTap: () {
            app.closeTeamDashboard();
            setState(() => _teamPage = 'manage');
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: AppColors.foreground),
          ),
        ),
        const SizedBox(width: 8),
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
              Text('${app.teamMemberCount} thành viên', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
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
          onTap: app.teamLoading ? null : () => _confirmLeaveTeam(app),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Rời nhóm',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.destructive,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: app.teamLoading
              ? null
              : () async {
                  if (app.teamCheckInToday) return;
                  final err = await app.setTeamCheckInToday(true);
                  if (!mounted) return;
                  if (err != null) {
                    AppSnackBar.show(context, err);
                    return;
                  }
                  setState(() => _showCheckInToast = true);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _showCheckInToast = false);
                  });
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
      child: const AppNoticeBanner(
        icon: Icons.star_rounded,
        message: 'Tuyệt vời! Bạn đã điểm danh hôm nay',
      ),
    );
  }

  Widget _buildChallengeCard(AppStateProvider app) {
    final challenge = app.teamActiveChallenge;
    final title = challenge?.title ?? 'Thử thách 7 ngày thả lỏng';
    final progressValue = app.currentWeekChallengeProgress;
    final progressPercent = app.currentWeekChallengePercent;
    final dayDone = app.currentWeekChallengeDayDone;

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
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _CircularProgressPainter(progress: progressValue),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$progressPercent%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const Text('hoàn thành', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) {
              final isDone = i < dayDone.length && dayDone[i];
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
    final visibleHabits = habits.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nhiệm vụ nhóm hôm nay',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completed/${habits.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (habits.length > 5) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => HabitsAllSheet.show(
                  context,
                  title: 'Nhiệm vụ nhóm hôm nay',
                ),
                child: Text(
                  'Xem tất cả \u2192',
                  style: AppTypography.link.copyWith(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          _buildNoHabitsInfo()
        else
          ...visibleHabits.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HabitRowTile(habitId: h.id, label: h.text),
            ),
          ),
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

  // ─── LEADERBOARD ────────────────────────────────────────────────────────────

  Widget _buildLeaderboard(AppStateProvider app) {
    final useApi = app.teamMembers.isNotEmpty;
    final mockMembers = List.of(_content.teamMembers);

    final apiRows = app.teamMembers.map((m) {
      return (
        name: m.name,
        avatar: m.avatar,
        points: app.weeklyLeaderboardPointsFor(m),
        isMe: m.isCurrentUser,
      );
    }).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    final mockRows = mockMembers.map((m) {
      final points = m.isMe
          ? app.myWeeklyLeaderboardPointsRounded
          : (m.score * (100 / 14)).round().clamp(0, 100);
      return (
        name: m.name,
        avatar: m.avatar,
        points: points,
        isMe: m.isMe,
      );
    }).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    final rows = useApi ? apiRows : mockRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BẢNG XẾP HẠNG',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thang điểm tuần này: tối đa 100 điểm (điểm danh + routine)',
          style: TextStyle(fontSize: 10, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        ...List.generate(rows.length, (i) {
          final row = rows[i];
          return _buildLeaderboardRow(
            name: row.name,
            avatar: row.avatar,
            points: row.points,
            isMe: row.isMe,
            rank: i + 1,
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

class _TeamBackButton extends StatelessWidget {
  const _TeamBackButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_left, size: 20, color: AppColors.foreground),
        ),
      ),
    );
  }
}

class _JoinGroupPage extends StatelessWidget {
  const _JoinGroupPage({
    super.key,
    required this.controller,
    required this.onBack,
    required this.buildJoinRow,
    required this.buildEmptySearch,
    required this.buildLoadingList,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final Widget Function({
    required AppStateProvider app,
    required String emoji,
    required String name,
    required int memberCount,
    required String groupId,
    required Future<bool> Function() onJoin,
  }) buildJoinRow;
  final Widget Function() buildEmptySearch;
  final Widget Function() buildLoadingList;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TeamBackButton(onTap: onBack),
                  const SizedBox(width: 12),
                  const Text(
                    'Tham gia nhóm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _JoinSearchField(
                controller: controller,
                onSearch: context.read<AppStateProvider>().searchPublicGroups,
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<AppStateProvider>(
            builder: (context, app, _) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, searchValue, _) {
                  final query = searchValue.text.toLowerCase();
                  final filteredApi = app.publicGroups
                      .where((g) => g.name.toLowerCase().contains(query))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Text(
                          'NHÓM CÔNG KHAI (${filteredApi.length})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: app.teamLoading && app.publicGroups.isEmpty
                            ? buildLoadingList()
                            : filteredApi.isEmpty
                                ? buildEmptySearch()
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 100),
                                    itemCount: filteredApi.length,
                                    separatorBuilder: (context, idx) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, i) => buildJoinRow(
                                      app: app,
                                      emoji: '👥',
                                      name: filteredApi[i].name,
                                      memberCount: filteredApi[i].memberCount,
                                      groupId: filteredApi[i].id,
                                      onJoin: () =>
                                          app.joinTeamById(filteredApi[i].id),
                                    ),
                                  ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _JoinSearchField extends StatefulWidget {
  const _JoinSearchField({
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  State<_JoinSearchField> createState() => _JoinSearchFieldState();
}

class _JoinSearchFieldState extends State<_JoinSearchField> {
  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.sentences,
      onChanged: widget.onSearch,
      style: const TextStyle(
        fontSize: 14,
        height: 1.35,
        color: AppColors.foreground,
      ),
      decoration: InputDecoration(
        hintText: 'Tìm nhóm...',
        hintStyle: AppTypography.hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border.copyWith(
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
