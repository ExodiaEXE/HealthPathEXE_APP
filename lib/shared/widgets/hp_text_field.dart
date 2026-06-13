import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';

/// Input matching remove-companion `INPUT_CLS` (icon left, border 2px, focus sage).
class HpTextField extends StatelessWidget {
  const HpTextField({
    super.key,
    this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.hint,
        filled: true,
        fillColor: AppColors.surfaceMuted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 18),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        enabledBorder: _border,
        focusedBorder: _border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        focusedErrorBorder: _border,
      ),
    );
  }
}
