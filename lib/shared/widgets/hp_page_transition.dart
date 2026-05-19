import 'package:flutter/material.dart';

/// Tab / auth view fade (~150ms like web AnimatePresence).
class HpFadeTransition extends StatelessWidget {
  const HpFadeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final Duration duration;

  static Widget builder(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => child;
}

/// Horizontal slide for auth login ↔ register (web `x: ±20`).
class HpAuthSlideTransition extends StatelessWidget {
  const HpAuthSlideTransition({
    super.key,
    required this.child,
    required this.animation,
    this.enterFromLeft = false,
  });

  final Widget child;
  final Animation<double> animation;
  final bool enterFromLeft;

  @override
  Widget build(BuildContext context) {
    final offset = enterFromLeft ? const Offset(-0.08, 0) : const Offset(0.08, 0);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: offset, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
