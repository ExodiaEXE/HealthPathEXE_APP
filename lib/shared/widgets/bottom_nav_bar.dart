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
  });

  final ActiveTab activeTab;
  final ValueChanged<ActiveTab> onTabSelected;

  static const _tabs = [
    (ActiveTab.home, Icons.home_rounded, 'Trang chu'),
    (ActiveTab.audio, Icons.headphones_rounded, 'Am thanh'),
    (ActiveTab.team, Icons.groups_rounded, 'Nhom'),
    (ActiveTab.settings, Icons.person_rounded, 'Ca nhan'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: const Border(top: BorderSide(color: Color(0xCCEEEEEE))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _tabs.map((t) {
                  final selected = activeTab == t.$1;
                  return HpTapScale(
                    scale: 0.9,
                    onTap: () => onTabSelected(t.$1),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            t.$2,
                            size: 20,
                            color: selected ? AppColors.primary : const Color(0xFFBBBBBB),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.$3,
                            style: AppTypography.micro.copyWith(
                              color: selected ? AppColors.primary : const Color(0xFFBBBBBB),
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            width: selected ? 4 : 0,
                            height: selected ? 4 : 0,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
