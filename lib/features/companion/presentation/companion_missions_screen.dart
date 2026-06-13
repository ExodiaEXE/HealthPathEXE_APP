import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/features/companion/providers/companion_provider.dart';
import 'package:provider/provider.dart';

const _hubBg = AppColors.background;

class CompanionMissionsScreen extends StatefulWidget {
  const CompanionMissionsScreen({super.key});

  @override
  State<CompanionMissionsScreen> createState() => _CompanionMissionsScreenState();
}

class _CompanionMissionsScreenState extends State<CompanionMissionsScreen> {
  String _tab = 'daily';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<CompanionProvider>().loadMissions(_tab);
  }

  @override
  Widget build(BuildContext context) {
    final companion = context.watch<CompanionProvider>();
    final bundle = companion.missions;

    return Scaffold(
      backgroundColor: _hubBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const Expanded(
                    child: Text(
                      'Nhiệm vụ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (bundle != null)
                    Text(
                      '${bundle.completedCount}/${bundle.totalCount} hoàn thành',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _tabChip('Hàng ngày', 'daily'),
                  const SizedBox(width: 8),
                  _tabChip('Hàng tuần', 'weekly'),
                  const SizedBox(width: 8),
                  _tabChip('Một lần', 'once'),
                ],
              ),
            ),
            Expanded(
              child: companion.loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          if (bundle == null || bundle.missions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('Chưa có nhiệm vụ')),
                            )
                          else
                            ...bundle.missions.map(_missionCard),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, String key) {
    final selected = _tab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tab = key);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _missionCard(CompanionMission m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isCompleted
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            m.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: m.isCompleted ? AppColors.primary : AppColors.muted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.description,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: m.targetCount > 0 ? m.progress / m.targetCount : 0,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('🪙 ${m.rewardCoins}',
                        style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 12),
                    Text('⭐ ${m.rewardXp} XP',
                        style: const TextStyle(fontSize: 10)),
                    const Spacer(),
                    Text(
                      '${m.progress}/${m.targetCount}',
                      style: const TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
