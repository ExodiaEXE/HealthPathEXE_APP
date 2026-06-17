import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/constants/routine_catalog.dart';
import 'package:health/domain/entities/routine_entities.dart';

/// Card ngang trên Home — giống remove-companion (emoji + nút +, mô tả, độ khó).
class RoutineHomeCard extends StatelessWidget {
  const RoutineHomeCard({
    super.key,
    required this.routine,
    required this.added,
    required this.onToggle,
  });

  final RoutineModel routine;
  final bool added;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final emoji = RoutineCatalog.routineEmoji(routine);
    final diff = RoutineCatalog.difficultyLabel(routine.difficulty);
    final note = routine.description ?? '${routine.durationMinutes} phút';

    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: added
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(16),
        color: added
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoutineIcon(routine: routine, emoji: emoji, size: 26),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: added ? AppColors.primary : Colors.white,
                    border: added
                        ? null
                        : Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Icon(
                    added ? Icons.check : Icons.add,
                    size: 14,
                    color: added ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            routine.title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.foreground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
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
              Text(
                diff,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hàng trong danh sách "Xem tất cả".
class RoutineListTile extends StatelessWidget {
  const RoutineListTile({
    super.key,
    required this.routine,
    required this.added,
    required this.onToggle,
  });

  final RoutineModel routine;
  final bool added;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final emoji = RoutineCatalog.routineEmoji(routine);
    final diff = RoutineCatalog.difficultyLabel(routine.difficulty);
    final note = routine.description ?? '${routine.durationMinutes} phút';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: added
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(16),
            color: added
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _RoutineIcon(routine: routine, emoji: emoji, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (added)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      diff,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineIcon extends StatelessWidget {
  const _RoutineIcon({
    required this.routine,
    required this.emoji,
    required this.size,
  });

  final RoutineModel routine;
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = routine.thumbnailUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: size + 4,
          height: size + 4,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Text(emoji, style: TextStyle(fontSize: size)),
        ),
      );
    }
    return Text(emoji, style: TextStyle(fontSize: size));
  }
}
