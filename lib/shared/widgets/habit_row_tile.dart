import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:provider/provider.dart';

/// Một dòng thói quen — tick, gạch ngang và trạng thái loading đồng bộ.
class HabitRowTile extends StatelessWidget {
  const HabitRowTile({
    super.key,
    required this.habitId,
    required this.label,
    this.entranceIndex,
  });

  final String habitId;
  final String label;
  final int? entranceIndex;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final done = app.isHabitCompleted(habitId);
    final loading = app.isHabitCompleting(habitId);

    final tile = _HabitRowBody(
      habitId: habitId,
      label: label,
      done: done,
      loading: loading,
      onTap: done || loading ? null : () => app.completeTodayHabit(habitId),
    );

    if (entranceIndex == null) return tile;
    return _HabitEntrance(index: entranceIndex!, child: tile);
  }
}

class _HabitEntrance extends StatefulWidget {
  const _HabitEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_HabitEntrance> createState() => _HabitEntranceState();
}

class _HabitEntranceState extends State<_HabitEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 60)),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _HabitRowBody extends StatelessWidget {
  const _HabitRowBody({
    required this.habitId,
    required this.label,
    required this.done,
    required this.loading,
    required this.onTap,
  });

  final String habitId;
  final String label;
  final bool done;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HpTapScale(
        scale: done ? 1 : 0.98,
        onTap: onTap,
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
              if (loading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: done ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    inherit: false,
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: AppColors.primary,
                    decorationThickness: 2,
                    color: done ? AppColors.primary : AppColors.foreground,
                  ),
                  child: Text(label, key: ValueKey('$habitId-$done')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
