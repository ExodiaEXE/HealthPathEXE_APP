import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/core/constants/app_colors.dart';

/// OTP 6 ô — một TextField ẩn nhận phím (tương thích IME / bàn phím EN-VI).
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onChanged,
    this.length = 6,
  });

  final ValueChanged<String> onChanged;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    final hasFocus = _focusNode.hasFocus;
    // Ô đang chờ nhập: bằng độ dài hiện tại (kẹp khi đã đủ 6).
    final activeIndex = code.length < widget.length
        ? code.length
        : widget.length - 1;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final char = i < code.length ? code[i] : '';
              final highlighted = hasFocus && i == activeIndex;

              return Padding(
                padding: EdgeInsets.only(right: i < widget.length - 1 ? 8 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 40,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: highlighted ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    char,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              );
            }),
          ),
          // TextField trong suốt — nhận toàn bộ input (paste, autofill, phím số).
          Opacity(
            opacity: 0.01,
            child: SizedBox(
              width: widget.length * 48.0,
              height: 48,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableSuggestions: false,
                autocorrect: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                showCursor: false,
                enableIMEPersonalizedLearning: false,
                style: const TextStyle(fontSize: 1, height: 1),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
