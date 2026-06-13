import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/features/companion/providers/companion_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:provider/provider.dart';

const _hubBg = AppColors.background;

class CompanionShopScreen extends StatefulWidget {
  const CompanionShopScreen({super.key});

  @override
  State<CompanionShopScreen> createState() => _CompanionShopScreenState();
}

class _CompanionShopScreenState extends State<CompanionShopScreen> {
  String _cat = 'furniture';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<CompanionProvider>().loadCatalog(_cat);
  }

  @override
  Widget build(BuildContext context) {
    final companion = context.watch<CompanionProvider>();
    final coins = companion.state.coins;

    return Scaffold(
      backgroundColor: _hubBg,
      body: SafeArea(
        child: Column(
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
                      'Cửa hàng',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text('🪙 $coins', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _catChip('Nội thất', 'furniture'),
                  const SizedBox(width: 8),
                  _catChip('Nền', 'background'),
                  const SizedBox(width: 8),
                  _catChip('Trang phục', 'outfit'),
                ],
              ),
            ),
            Expanded(
              child: companion.loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: companion.catalog.length,
                      itemBuilder: (context, i) =>
                          _itemCard(companion, companion.catalog[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catChip(String label, String key) {
    final selected = _cat == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _cat = key);
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

  Widget _itemCard(CompanionProvider companion, CompanionCatalogItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(item.iconEmoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (item.isOwned)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Sở hữu',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () async {
                final ok = await companion.buyItem(item.sku);
                if (!mounted) return;
                if (ok) {
                  AppSnackBar.show(context, companion.lastMessage ?? 'Đã mua!');
                  _load();
                } else {
                  AppSnackBar.show(context, companion.lastMessage ?? 'Không mua được');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '🪙 ${item.price}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
