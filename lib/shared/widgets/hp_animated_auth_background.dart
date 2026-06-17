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
      duration: const Duration(seconds: 15),
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
        final rotation = t * 2 * math.pi;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base background
            const DecoratedBox(
              decoration: BoxDecoration(color: Colors.white),
            ),
            // Animating Gradient Layer
            Opacity(
              opacity: 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(math.cos(rotation), math.sin(rotation)),
                    end: Alignment(math.cos(rotation + math.pi), math.sin(rotation + math.pi)),
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.3),
                      Colors.green,
                    ],
                  ),
                ),
              ),
            ),
            // Floating Blobs with smoother movement
            _blob(
              left: 20 + math.sin(t * math.pi * 2) * 30,
              top: 100 + math.cos(t * math.pi * 2) * 40,
              size: 250,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            _blob(
              right: 10 + math.cos(t * math.pi * 2) * 20,
              bottom: 150 + math.sin(t * math.pi * 2) * 50,
              size: 300,
              color: AppColors.accent.withValues(alpha: 0.15),
            ),
            _blob(
              left: 100 + math.sin(t * math.pi * 2 + 2) * 40,
              bottom: 50 + math.cos(t * math.pi * 2 + 2) * 30,
              size: 180,
              color: Colors.green.withValues(alpha: 0.5),
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
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
