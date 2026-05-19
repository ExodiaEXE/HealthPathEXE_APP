import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';

/// Animated gradient + floating blobs (web `animate-gradient`, `animate-float`).
class HpAnimatedAuthBackground extends StatefulWidget {
  const HpAnimatedAuthBackground({super.key});

  @override
  State<HpAnimatedAuthBackground> createState() => _HpAnimatedAuthBackgroundState();
}

class _HpAnimatedAuthBackgroundState extends State<HpAnimatedAuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + t * 2, -1),
                  end: Alignment(1 - t * 2, 1),
                  colors: const [
                    Color(0xFF3D7A2E),
                    Color(0xFF4A90C8),
                    Color(0xFFF5EDE4),
                    Color(0xFF3D7A2E),
                    Color(0xFFD4855A),
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
            _blob(
              left: 24,
              top: 64 + math.sin(t * math.pi * 2) * 12,
              size: 176,
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
            _blob(
              right: 16,
              bottom: 112 + math.sin(t * math.pi * 2 + 1.5) * 10,
              size: 224,
              color: AppColors.accent.withValues(alpha: 0.28),
            ),
            _blob(
              right: 80,
              top: 180 + math.sin(t * math.pi * 2 + 0.5) * 8,
              size: 96,
              color: AppColors.coral.withValues(alpha: 0.22),
            ),
          ],
        );
      },
    );
  }

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
