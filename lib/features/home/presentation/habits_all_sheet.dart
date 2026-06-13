import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/habit_row_tile.dart';
import 'package:provider/provider.dart';

/// Sheet xem đủ thói quen hôm nay (khi > 5 item trên Home).
class HabitsAllSheet extends StatelessWidget {
  const HabitsAllSheet({super.key, this.title = 'Thói quen của bạn'});

  final String title;

  static Future<void> show(
    BuildContext context, {
    String title = 'Thói quen của bạn',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HabitsAllSheet(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final habits = app.getActiveHabits();
    final completed =
        habits.where((h) => app.isHabitCompleted(h.id)).length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completed/${habits.length} hoàn thành',
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
                      backgroundColor: AppColors.surfaceMuted,
                      minimumSize: const Size(36, 36),
                    ),
                    icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: habits.length,
                itemBuilder: (context, i) {
                  final h = habits[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: HabitRowTile(habitId: h.id, label: h.text),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
