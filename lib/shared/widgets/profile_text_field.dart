import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';

/// Ô nhập hồ sơ — tách widget để bộ gõ tiếng Việt không bị mất dấu khi rebuild.
class ProfileTextField extends StatefulWidget {
  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.placeholder,
    this.helper,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String placeholder;
  final String? helper;
  final bool readOnly;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;

  @override
  State<ProfileTextField> createState() => _ProfileTextFieldState();
}

class _ProfileTextFieldState extends State<ProfileTextField> {
  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 12, color: const Color(0xFF666666)),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.helper!,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ),
        TextField(
          controller: widget.controller,
          readOnly: widget.readOnly,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          textCapitalization: widget.readOnly
              ? TextCapitalization.none
              : TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: widget.readOnly ? AppColors.muted : AppColors.foreground,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
            filled: true,
            fillColor:
                widget.readOnly ? const Color(0xFFF8F8F8) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: _border,
            enabledBorder: _border,
            focusedBorder: _border.copyWith(
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
