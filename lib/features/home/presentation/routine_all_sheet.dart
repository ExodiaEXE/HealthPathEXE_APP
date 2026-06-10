import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/domain/entities/routine_entities.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/routine_suggestion_card.dart';
import 'package:provider/provider.dart';

/// Sheet full màn "Xem tất cả" — category accordion thu gọn/mở rộng.
class RoutineAllSheet extends StatefulWidget {
  const RoutineAllSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RoutineAllSheet(),
    );
  }

  @override
  State<RoutineAllSheet> createState() => _RoutineAllSheetState();
}

class _RoutineAllSheetState extends State<RoutineAllSheet> {
  final Set<String> _expanded = {};
  bool _didInitExpanded = false;

  void _initExpandedIfNeeded(List<RoutineUiGroup> groups) {
    if (_didInitExpanded || groups.isEmpty) return;
    for (final group in groups) {
      if (group.sections.isNotEmpty) {
        _expanded.add(group.sections.first.category);
        break;
      }
    }
    _didInitExpanded = true;
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expanded.contains(category)) {
        _expanded.remove(category);
      } else {
        _expanded.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final groups = app.routineGroups;

    if (!_didInitExpanded && groups.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _initExpandedIfNeeded(groups));
      });
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'TẤT CẢ GỢI Ý (${app.routines.length})',
                    style: AppTypography.micro.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (app.routinesLoading && groups.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (groups.isEmpty)
                    Text(
                      app.routinesError ?? 'Chưa có thói quen.',
                      style: AppTypography.bodySm,
                    )
                  else
                    ...groups.expand((group) => [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Row(
                              children: [
                                Text(group.emoji,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  group.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...group.sections.map(
                            (section) => _CategoryAccordion(
                              section: section,
                              expanded:
                                  _expanded.contains(section.category),
                              onToggle: () =>
                                  _toggleCategory(section.category),
                              app: app,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryAccordion extends StatelessWidget {
  const _CategoryAccordion({
    required this.section,
    required this.expanded,
    required this.onToggle,
    required this.app,
  });

  final RoutineCategorySection section;
  final bool expanded;
  final VoidCallback onToggle;
  final AppStateProvider app;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: Radius.circular(expanded ? 0 : 14),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Text(section.emoji,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          section.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                      Text(
                        '${section.routines.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: section.routines
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RoutineListTile(
                          routine: r,
                          added: app.isHabitCompleted(r.id),
                          onToggle: () => app.completeTodayHabit(r.id),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final hasFilter = app.selectedMood != null || app.energyLevel != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tất cả gợi ý routine',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFilter
                      ? 'Gợi ý dựa trên tâm trạng và năng lượng của bạn'
                      : 'Chọn tâm trạng + năng lượng để có gợi ý tốt hơn',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
              minimumSize: const Size(36, 36),
            ),
            icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
