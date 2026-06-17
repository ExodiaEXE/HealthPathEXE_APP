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
      await context.read<CompanionProvider>().loadCatalog(null);
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
            Expanded(
              child: SingleChildScrollView(
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
                    const Text('Chọn phòng',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text(
                      'Nhấn để thay đổi nền phòng',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.3,
                      children: [
                        _roomCard(companion, 'room_1', 'Phòng 1'),
                        _roomCard(companion, 'room_2', 'Phòng 2'),
                        _roomCard(companion, 'room_3', 'Phòng 3'),
                        _roomCard(companion, 'room_4', 'Phòng 4'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _roomCard(
    CompanionProvider companion,
    String roomKey,
    String label,
  ) {
    final selected =
        CompanionAssets.normalizeRoomTheme(companion.state.roomTheme) == roomKey;
    final imagePath = CompanionAssets.roomImageAssets[roomKey];
    final unlocked = CompanionCosmetics.isRoomUnlocked(roomKey, companion.catalog);
    final bgSku = CompanionCosmetics.backgroundSkuForRoom(roomKey);
    CompanionCatalogItem? bgItem;
    if (bgSku != null) {
      for (final item in companion.catalog) {
        if (item.sku == bgSku) {
          bgItem = item;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () async {
        if (!unlocked) {
          final price = bgItem?.price ?? 0;
          AppSnackBar.show(
            context,
            price > 0
                ? 'Mua $label tại cửa hàng ($price xu)'
                : 'Mua $label tại cửa hàng',
          );
          return;
        }
        final ok = await companion.applyRoomTheme(roomKey);
        if (!mounted) return;
        if (!ok) {
          AppSnackBar.show(context, companion.lastMessage ?? 'Không đổi được phòng');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceMuted,
                  child: const Icon(Icons.image_not_supported, color: AppColors.muted),
                ),
              )
            else
              Container(
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.home, color: AppColors.muted),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.check_circle, size: 14, color: Colors.white),
                      ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!unlocked)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, color: Colors.white, size: 28),
                      if ((bgItem?.price ?? 0) > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '🪙 ${bgItem!.price}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _equipTile(CompanionProvider companion, CompanionCatalogItem item) {
    return GestureDetector(
      onTap: () async {
        final ok = await companion.equipItem(item.sku);
        if (!mounted) return;
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
