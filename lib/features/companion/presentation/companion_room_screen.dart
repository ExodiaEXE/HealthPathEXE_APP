import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/features/companion/presentation/widgets/companion_scene.dart';
import 'package:health/features/companion/providers/companion_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

const _hubBg = AppColors.background;

class CompanionRoomScreen extends StatefulWidget {
  const CompanionRoomScreen({super.key});

  @override
  State<CompanionRoomScreen> createState() => _CompanionRoomScreenState();
}

class _CompanionRoomScreenState extends State<CompanionRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CompanionProvider>().loadCatalog('furniture');
    });
  }

  @override
  Widget build(BuildContext context) {
    final companion = context.watch<CompanionProvider>();
    final s = companion.state;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trang trí phòng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Chỉnh sửa phòng của bạn',
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Phòng của bạn',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: CompanionScene(
                      state: s,
                      expression: s.mascotMood,
                      assets: companion.assets,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nền phòng',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _themeChip(companion, 'cozy', 'Ấm cúng', '🏠'),
                      const SizedBox(width: 8),
                      _themeChip(companion, 'modern', 'Hiện đại', '🏢'),
                      const SizedBox(width: 8),
                      _themeChip(companion, 'nature', 'Thiên nhiên', '🌿'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Nội thất đã sở hữu',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: companion.catalog
                          .where((c) => c.isOwned && c.category == 'furniture')
                          .map((item) => _equipTile(companion, item))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(
    CompanionProvider companion,
    String theme,
    String label,
    String emoji,
  ) {
    final selected = companion.state.roomTheme == theme;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final ok = await companion.applyRoomTheme(theme);
          if (!context.mounted) return;
          if (!ok) {
            AppSnackBar.show(context, companion.lastMessage ?? 'Không đổi được nền');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _equipTile(CompanionProvider companion, CompanionCatalogItem item) {
    return GestureDetector(
      onTap: () async {
        final ok = await companion.equipItem(item.sku);
        if (!context.mounted) return;
        AppSnackBar.show(
          context,
          ok ? (companion.lastMessage ?? 'Đã trang trí!') : (companion.lastMessage ?? 'Lỗi'),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isEquipped ? AppColors.primary : AppColors.border,
            width: item.isEquipped ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
