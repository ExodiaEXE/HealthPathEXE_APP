import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/features/companion/presentation/companion_tab_shell.dart';
import 'package:health/features/companion/presentation/widgets/companion_scene.dart';
import 'package:health/features/companion/providers/companion_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:provider/provider.dart';

class CompanionHubScreen extends StatefulWidget {
  const CompanionHubScreen({super.key, this.embeddedInShell = false});

  /// Tab trong [AppShell] — giữ bottom nav, không nút back.
  final bool embeddedInShell;

  @override
  State<CompanionHubScreen> createState() => _CompanionHubScreenState();
}

class _CompanionHubScreenState extends State<CompanionHubScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CompanionProvider>();
      await Future.wait([
        provider.loadAssets(),
        provider.loadState(),
      ]);
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) context.read<CompanionProvider>().loadState();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _toast(String? msg) {
    if (msg == null || msg.isEmpty || !mounted) return;
    AppSnackBar.show(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final companion = context.watch<CompanionProvider>();
    final s = companion.state;

    if (companion.loading && s.level == 1 && s.xp == 0) {
      return const SizedBox.expand(
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(s.coins),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _nameLevelBadges(s.level),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 340,
                          child: CompanionScene(
                            state: s,
                            expression: companion.petExpression,
                            assets: companion.assets,
                            onTapPet: () {
                              companion.onPetTapped();
                              unawaited(companion.interactPet().then((ok) {
                                if (!ok) _toast(companion.lastMessage);
                              }));
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chạm mascot để tương tác · 3D tích hợp sẵn',
                          textAlign: TextAlign.center,
                          style: AppTypography.micro.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _statBar('Đói', s.hunger, AppColors.accent),
                        _statBar('Vui', s.happiness, AppColors.primaryLight),
                        _statBar('Năng', s.energy, AppColors.streakOrange),
                        _statBar(
                          'Kinh nghiệm',
                          s.xpForNextLevel > 0
                              ? ((s.xp / s.xpForNextLevel) * 100).round()
                              : 0,
                          AppColors.primary,
                          labelRight: '${s.xp}/${s.xpForNextLevel}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _primaryActions(companion, s),
                const SizedBox(height: 10),
                _secondaryActions(),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _header(int coins) {
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.embeddedInShell ? 16 : 8, 4, 16, 4),
      child: Row(
        children: [
          if (!widget.embeddedInShell)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          Expanded(
            child: Text(
              'Bạn đồng hành',
              style: AppTypography.title.copyWith(fontSize: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameLevelBadges(int level) {
    return Row(
      children: [
        Expanded(
          child: _infoBadge(
            label: 'Tên',
            value: 'Mèo Xanh',
            icon: '🐱',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _infoBadge(
            label: 'Cấp',
            value: 'Level $level',
            icon: '⭐',
          ),
        ),
      ],
    );
  }

  Widget _infoBadge({
    required String label,
    required String value,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBar(String label, int value, Color color, {String? labelRight}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTypography.micro.copyWith(
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (value.clamp(0, 100)) / 100,
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              labelRight ?? '$value/100',
              textAlign: TextAlign.right,
              style: AppTypography.micro.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryActions(CompanionProvider companion, CompanionState s) {
    return Row(
      children: [
        Expanded(
          child: _primaryBtn(
            label: 'Cho ăn',
            emoji: '🍖',
            enabled: s.canFeed,
            onTap: () async {
              final ok = await companion.feedPet();
              _toast(
                ok
                    ? companion.lastMessage
                    : s.feedBlockedReason ?? companion.lastMessage,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _primaryBtn(
            label: 'Vuốt ve',
            emoji: '✨',
            enabled: s.canPet,
            onTap: () async {
              final ok = await companion.interactPet();
              _toast(
                ok
                    ? companion.lastMessage
                    : s.petBlockedReason ?? companion.lastMessage,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _primaryBtn({
    required String label,
    required String emoji,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return HpTapScale(
      onTap: enabled ? onTap : () {},
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.primaryGradient : null,
            color: enabled ? null : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: enabled ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryActions() {
    return Row(
      children: [
        Expanded(
          child: _secondaryBtn(
            label: 'Nhiệm vụ',
            icon: Icons.task_alt_rounded,
            onTap: () => Navigator.of(context).pushNamed(
              CompanionTabShell.missionsRoute,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _secondaryBtn(
            label: 'Cửa hàng',
            icon: Icons.storefront_outlined,
            onTap: () => Navigator.of(context).pushNamed(
              CompanionTabShell.shopRoute,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _secondaryBtn(
            label: 'Phòng',
            icon: Icons.home_outlined,
            onTap: () => Navigator.of(context).pushNamed(
              CompanionTabShell.roomRoute,
            ),
          ),
        ),
      ],
    );
  }

  Widget _secondaryBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return HpTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.micro.copyWith(
                color: AppColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
