import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';

class HealthBottomNav extends StatelessWidget {
  const HealthBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onCompanionTap,
  });

  final ActiveTab activeTab;
  final ValueChanged<ActiveTab> onTabSelected;
  final VoidCallback onCompanionTap;

  static const _leftTabs = [
    (ActiveTab.home, Icons.home_rounded, 'Trang chủ'),
    (ActiveTab.audio, Icons.headphones_rounded, 'Âm thanh'),
  ];

  static const _rightTabs = [
    (ActiveTab.team, Icons.groups_rounded, 'Nhóm'),
    (ActiveTab.settings, Icons.person_rounded, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: const Border(
              top: BorderSide(color: Color(0xCCEEEEEE)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ..._leftTabs.map((t) => _buildTab(t)),
                  _buildCenterButton(),
                  ..._rightTabs.map((t) => _buildTab(t)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
      (ActiveTab, IconData, String) tab) {
    final selected = activeTab == tab.$1;
    return HpTapScale(
      scale: 0.9,
      onTap: () => onTabSelected(tab.$1),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.$2,
              size: 20,
              color: selected ? AppColors.primary : const Color(0xFFBBBBBB),
            ),
            const SizedBox(height: 2),
            Text(
              tab.$3,
              style: AppTypography.micro.copyWith(
                color: selected ? AppColors.primary : const Color(0xFFBBBBBB),
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            // Indicator dot. Web animates `scale` (0↔1) with an overshoot
            // curve; AnimatedScale keeps a fixed 4x4 box so the easeOutBack
            // overshoot can never produce negative layout constraints.
            SizedBox(
              width: 4,
              height: 4,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: selected ? 1 : 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final selected = activeTab == ActiveTab.companion;
    return HpTapScale(
      scale: 0.9,
      onTap: onCompanionTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryDark : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(
              'Bạn đồng hành',
              style: AppTypography.micro.copyWith(
                color: selected ? AppColors.primaryDark : AppColors.primary,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
