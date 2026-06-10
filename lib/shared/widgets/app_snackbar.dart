import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/utils/user_facing_message.dart';

/// Thông báo phản hồi — luôn hiển thị trên overlay gốc, không bị bottom sheet / nav che.
abstract final class AppSnackBar {
  static const TextStyle _textStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
    height: 1.35,
  );

  static const Color _surfaceColor = Color(0xFFEAF4E6);

  static BoxDecoration get decoration => BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static OverlayEntry? _entry;
  static Timer? _hideTimer;

  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
    String? fallback,
  }) {
    if (!context.mounted) return;

    final text = UserFacingMessage.sanitize(
      message,
      fallback: fallback ?? 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
    );

    final overlay = _rootOverlay(context);
    if (overlay == null) return;

    _dismiss();

    _entry = OverlayEntry(
      builder: (overlayContext) => _ToastOverlay(
        message: text,
        onDismiss: _dismiss,
      ),
    );
    overlay.insert(_entry!);

    _hideTimer = Timer(duration ?? const Duration(seconds: 3), _dismiss);
  }

  static OverlayState? _rootOverlay(BuildContext context) {
    final rootNav = Navigator.maybeOf(context, rootNavigator: true);
    if (rootNav?.overlay != null) return rootNav!.overlay;
    return Overlay.maybeOf(context, rootOverlay: true);
  }

  static void _dismiss() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _entry?.remove();
    _entry = null;
  }

  @Deprecated('Dùng AppSnackBar.show — overlay gốc, không dùng SnackBar widget.')
  static SnackBar build(String message, {Duration? duration}) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: duration ?? const Duration(seconds: 3),
      content: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Text(message, style: _textStyle),
        ),
      ),
    );
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismissAnimated() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: topInset + 12,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.15),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: _fade,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity!.abs() > 120) {
                      unawaited(_dismissAnimated());
                    }
                  },
                  onTap: () => unawaited(_dismissAnimated()),
                  child: Material(
                    elevation: 24,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    child: DecoratedBox(
                      decoration: AppSnackBar.decoration,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Text(
                          widget.message,
                          style: AppSnackBar._textStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner inline (ví dụ điểm danh nhóm) cùng tông màu với [AppSnackBar].
class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({
    super.key,
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppSnackBar.decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primaryDark, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: AppSnackBar._textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
