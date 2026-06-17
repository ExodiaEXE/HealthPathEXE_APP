import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/features/companion/presentation/widgets/companion_mascot_3d.dart';

/// Phòng 2.5D + mascot 3D (Phase 2). Fallback emoji nếu GLB lỗi.
class CompanionScene extends StatefulWidget {
  const CompanionScene({
    super.key,
    required this.state,
    required this.expression,
    this.assets,
    this.onTapPet,
  });

  final CompanionState state;
  final String expression;
  final CompanionAssets? assets;
  final VoidCallback? onTapPet;

  @override
  State<CompanionScene> createState() => _CompanionSceneState();
}

class _CompanionSceneState extends State<CompanionScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounce;
  bool _use3DFallback = false;

  CompanionAssets get _assets => widget.assets ?? CompanionAssets.fallback;

  bool get _canUse3D =>
      !_use3DFallback && _assets.enable3D && _assets.mascotGlbUrl.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CompanionScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression &&
        widget.expression != 'idle') {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.state.roomTheme;
    final bg = switch (theme) {
      'modern' => const [Color(0xFFF4F6FA), Color(0xFFE8ECF4)],
      'nature' => const [Color(0xFFF0F7F2), Color(0xFFE3F0E8)],
      _ => const [Color(0xFFF8FAF8), Color(0xFFF0F4F0)],
    };
    final room3dUrl = _assets.roomUrlFor(theme) ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bg,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (room3dUrl.isNotEmpty && _canUse3D)
            Positioned.fill(child: CompanionRoom3D(url: room3dUrl))
          else
            _roomBackdrop(theme),
          ..._furnitureLayer(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: _canUse3D ? 4 : 12),
              child: _canUse3D
                  ? SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: CompanionMascot3D(
                        assets: _assets,
                        expression: widget.expression,
                        onTap: widget.onTapPet,
                        onFailed: () {
                          if (mounted) setState(() => _use3DFallback = true);
                        },
                      ),
                    )
                  : GestureDetector(
                      onTap: widget.onTapPet,
                      child: AnimatedBuilder(
                        animation: _bounce,
                        builder: (context, child) {
                          final dy = widget.expression == 'idle'
                              ? math.sin(_bounce.value * math.pi) * 4
                              : -8.0;
                          return Transform.translate(
                            offset: Offset(0, dy),
                            child: child,
                          );
                        },
                        child: _catMascot2D(widget.expression),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomBackdrop(String theme) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _RoomPainter(theme: theme),
      ),
    );
  }

  List<Widget> _furnitureLayer() {
    final equipped = widget.state.equippedItemSkus.toSet();
    final items = <Widget>[];

    if (equipped.contains('plant_green') || equipped.isEmpty) {
      items.add(const Positioned(
        left: 16,
        bottom: 28,
        child: Text('🪴', style: TextStyle(fontSize: 28)),
      ));
    }
    if (equipped.contains('desk_books')) {
      items.add(const Positioned(
        right: 20,
        bottom: 32,
        child: Text('📚', style: TextStyle(fontSize: 26)),
      ));
    }
    if (equipped.contains('sofa_blue')) {
      items.add(const Positioned(
        right: 48,
        bottom: 24,
        child: Text('🛋️', style: TextStyle(fontSize: 22)),
      ));
    }
    if (equipped.contains('lamp_warm')) {
      items.add(const Positioned(
        right: 24,
        top: 48,
        child: Text('💡', style: TextStyle(fontSize: 22)),
      ));
    }
    return items;
  }

  Widget _catMascot2D(String expression) {
    final face = switch (expression) {
      'happy' || 'wave' => '😸',
      'eat' => '😋',
      'hungry' => '😿',
      'sleepy' => '😴',
      'sad' => '😾',
      _ => '🐱',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7BC67E), Color(0xFF3D7A2E)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D7A2E).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text('🐾',
                  style: TextStyle(fontSize: 18, color: Colors.white54)),
              Text(face, style: const TextStyle(fontSize: 52)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Mèo Xanh',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D7A2E),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomPainter extends CustomPainter {
  _RoomPainter({required this.theme});
  final String theme;

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xFFEEF2EE).withValues(alpha: 0.9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.65), wall);

    final floor = Paint()..color = const Color(0xFFE4EBE4).withValues(alpha: 0.85);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      floor,
    );

    final window = Paint()..color = const Color(0xFFD4E8F4).withValues(alpha: 0.75);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.12, size.width * 0.32,
            size.height * 0.28),
        const Radius.circular(8),
      ),
      window,
    );

    final shelf = Paint()..color = const Color(0xFF3D7A2E).withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.38, size.width * 0.35, 6),
      shelf,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.theme != theme;
}
