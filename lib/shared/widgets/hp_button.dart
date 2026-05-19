import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';

class HpPrimaryButton extends StatelessWidget {
  const HpPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null || loading
              ? LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.5), AppColors.primary.withValues(alpha: 0.5)])
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed == null || loading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[icon!, const SizedBox(width: 8)],
                        Text(label, style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
    return btn;
  }
}

class HpCard extends StatelessWidget {
  const HpCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
