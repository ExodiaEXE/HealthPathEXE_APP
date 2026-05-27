import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/otp_input.dart';
import 'package:provider/provider.dart';

class PaymentModal extends StatefulWidget {
  const PaymentModal({super.key});

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal>
    with TickerProviderStateMixin {
  late final AnimationController _sheetCtrl;
  late final Animation<Offset> _sheetSlide;
  late final AnimationController _confettiCtrl;
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final List<_ConfettiPiece> _confetti;

  String _otp = '';
  bool _otpError = false;
  bool _processingStarted = false;

  late final TextEditingController _momoPhone;
  late final TextEditingController _momoName;
  late final TextEditingController _bankAccount;
  late final TextEditingController _bankName;
  late final TextEditingController _bankHolder;
  late final TextEditingController _visaCard;
  late final TextEditingController _visaHolder;
  late final TextEditingController _visaExpiry;
  late final TextEditingController _visaCvv;

  static const _confettiColors = [
    Color(0xFF3D7A2E),
    Color(0xFF4A90C8),
    Color(0xFFE8A87C),
    Color(0xFFEFE5DC),
    Color(0xFF8CC084),
  ];

  @override
  void initState() {
    super.initState();

    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
    _sheetCtrl.forward();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );

    final rng = Random();
    _confetti = List.generate(
      40,
      (_) => _ConfettiPiece(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.4,
        rotation: rng.nextDouble() * 2 * pi,
        speed: (rng.nextDouble() - 0.5) * 6,
        w: 4 + rng.nextDouble() * 6,
        h: 8 + rng.nextDouble() * 8,
        color: _confettiColors[rng.nextInt(_confettiColors.length)],
      ),
    );

    _momoPhone = TextEditingController();
    _momoName = TextEditingController();
    _bankAccount = TextEditingController();
    _bankName = TextEditingController();
    _bankHolder = TextEditingController();
    _visaCard = TextEditingController();
    _visaHolder = TextEditingController();
    _visaExpiry = TextEditingController();
    _visaCvv = TextEditingController();
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _confettiCtrl.dispose();
    _successCtrl.dispose();
    _momoPhone.dispose();
    _momoName.dispose();
    _bankAccount.dispose();
    _bankName.dispose();
    _bankHolder.dispose();
    _visaCard.dispose();
    _visaHolder.dispose();
    _visaExpiry.dispose();
    _visaCvv.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    final idx = email.indexOf('@');
    if (idx < 2) return email;
    final local = email.substring(0, idx);
    return '${local[0]}***${local[local.length - 1]}${email.substring(idx)}';
  }

  bool _hasSaved(AppStateProvider app, PaymentMethodType? m) {
    if (m == null) return false;
    return app.savedPaymentMethods.any((s) => s.type == m);
  }

  void _goBack(AppStateProvider app, PaymentStep step) {
    switch (step) {
      case PaymentStep.method:
        app.setPaymentStep(PaymentStep.plan);
      case PaymentStep.input:
        app.setPaymentStep(PaymentStep.method);
      case PaymentStep.otp:
        app.setPaymentStep(
          _hasSaved(app, app.paymentMethod)
              ? PaymentStep.method
              : PaymentStep.input,
        );
      default:
        break;
    }
  }

  String _headerTitle(PaymentStep step) => switch (step) {
        PaymentStep.plan => 'Premium',
        PaymentStep.method => 'Phương thức',
        PaymentStep.input => 'Thanh toán',
        PaymentStep.otp => 'Xác minh',
        _ => '',
      };

  void _startProcessing() {
    if (_processingStarted) return;
    _processingStarted = true;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final app = context.read<AppStateProvider>();
      if (app.paymentStep != PaymentStep.processing) {
        _processingStarted = false;
        return;
      }
      app.setPaymentStep(PaymentStep.success);
      _confettiCtrl
        ..reset()
        ..forward();
      _successCtrl
        ..reset()
        ..forward();
      _processingStarted = false;
    });
  }

  void _handleSuccess() {
    final app = context.read<AppStateProvider>();
    app.setIsPremium(true);
    app.setPremiumInfo(PremiumInfo(
      productId: 'HP-PRE-MOCK',
      productName: 'HealthPath Premium',
      benefits: const [
        'Không quảng cáo',
        'Toàn bộ audio thư giãn',
        'Hỗ trợ ưu tiên',
      ],
      amountVnd: 59000,
      paidWith: app.paymentMethod?.name ?? 'mock',
      paidAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    ));
    app.navigateTo(ActiveTab.audio);
    app.setPaymentStep(null);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final step = app.paymentStep;
    if (step == null) return const SizedBox.shrink();

    if (step == PaymentStep.processing) {
      _startProcessing();
    }

    final showHeader =
        step != PaymentStep.processing && step != PaymentStep.success;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: showHeader ? () => app.setPaymentStep(null) : null,
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: SlideTransition(
                  position: _sheetSlide,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 25,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showHeader) _buildHeader(app, step),
                        if (step == PaymentStep.success)
                          Flexible(child: _buildSuccess())
                        else
                          Flexible(
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: _buildStep(app, step),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(AppStateProvider app, PaymentStep step) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        children: [
          if (step != PaymentStep.plan)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => _goBack(app, step),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              _headerTitle(step),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => app.setPaymentStep(null),
          ),
        ],
      ),
    );
  }

  // ── Step router ──

  Widget _buildStep(AppStateProvider app, PaymentStep step) => switch (step) {
        PaymentStep.plan => _buildPlan(app),
        PaymentStep.method => _buildMethod(app),
        PaymentStep.input => _buildInput(app),
        PaymentStep.otp => _buildOtp(app),
        PaymentStep.processing => _buildProcessing(),
        PaymentStep.success => const SizedBox.shrink(),
      };

  // ── Step 1: Plan ──

  Widget _buildPlan(AppStateProvider app) {
    final complete = app.profile.isComplete;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF8CC084)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mở khóa toàn bộ trải nghiệm',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '59,000',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'VND / thang',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _benefitRow(
          Icons.block,
          const Color(0xFFE57373).withValues(alpha: 0.15),
          const Color(0xFFE57373),
          'Không quảng cáo',
        ),
        const SizedBox(height: 8),
        _benefitRow(
          Icons.headphones,
          const Color(0xFF4A90C8).withValues(alpha: 0.15),
          const Color(0xFF4A90C8),
          'Toàn bộ audio thư giãn',
        ),
        const SizedBox(height: 8),
        _benefitRow(
          Icons.auto_awesome,
          const Color(0xFFE8A87C).withValues(alpha: 0.15),
          const Color(0xFFE8A87C),
          'Hỗ trợ ưu tiên',
        ),
        const SizedBox(height: 20),
        if (!complete) ...[
          _profileWarning(app),
          const SizedBox(height: 16),
        ],
        _primaryBtn(
          'Tiếp tục',
          complete ? () => app.setPaymentStep(PaymentStep.method) : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _benefitRow(IconData icon, Color bg, Color fg, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileWarning(AppStateProvider app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.destructive, size: 20),
              SizedBox(width: 8),
              Text(
                'Cần hoàn thiện hồ sơ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn cần nhập đầy đủ thông tin cá nhân trước khi thanh toán.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      app.setPaymentStep(null);
                      app.setSettingsView(SettingsView.editProfile);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Sửa hồ sơ',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => app.setPaymentStep(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.foreground,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Để sau',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2: Method ──

  Widget _buildMethod(AppStateProvider app) {
    final sel = app.paymentMethod;
    final saved = sel != null && _hasSaved(app, sel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Chọn phương thức thanh toán',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _methodCard(
          app,
          PaymentMethodType.momo,
          sel,
          Icons.account_balance_wallet,
          const Color(0xFFD63384),
          'Ví MoMo',
        ),
        const SizedBox(height: 10),
        _methodCard(
          app,
          PaymentMethodType.bank,
          sel,
          Icons.credit_card,
          const Color(0xFF4A90C8),
          'Thẻ Ngân Hàng (Napas)',
        ),
        const SizedBox(height: 10),
        _methodCard(
          app,
          PaymentMethodType.visa,
          sel,
          Icons.credit_card,
          const Color(0xFF1A1F71),
          'Visa / Mastercard',
        ),
        if (saved) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Đã lưu thông tin - chỉ cần xác thực',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _primaryBtn(
          saved ? 'Xác thực & Thanh toán' : 'Tiếp tục',
          sel != null
              ? () => app.setPaymentStep(
                    saved ? PaymentStep.otp : PaymentStep.input,
                  )
              : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _methodCard(
    AppStateProvider app,
    PaymentMethodType type,
    PaymentMethodType? selected,
    IconData icon,
    Color accent,
    String label,
  ) {
    final active = selected == type;
    return GestureDetector(
      onTap: () => app.setPaymentMethod(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.muted,
                  width: 2,
                ),
                color: active ? AppColors.primary : Colors.transparent,
              ),
              child: active
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Input ──

  Widget _buildInput(AppStateProvider app) => switch (app.paymentMethod) {
        PaymentMethodType.momo => _momoInput(app),
        PaymentMethodType.bank => _bankInput(app),
        PaymentMethodType.visa => _visaInput(app),
        null => const SizedBox.shrink(),
      };

  Widget _momoInput(AppStateProvider app) {
    const accent = Color(0xFFD63384);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Liên kết Ví MoMo',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Nhập số điện thoại đã đăng ký MoMo để liên kết',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        _field(_momoPhone, 'Số điện thoại MoMo', '0912 345 678', accent,
            keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _field(_momoName, 'Tên chủ tài khoản', 'NGUYEN VAN A', accent),
        const SizedBox(height: 24),
        _accentBtn(
          'Gửi mã OTP để liên kết',
          accent,
          () => app.setPaymentStep(PaymentStep.otp),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _bankInput(AppStateProvider app) {
    const accent = Color(0xFF4A90C8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Thông tin ngân hàng',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _field(_bankAccount, 'Số tài khoản', '0123456789', accent,
            keyboard: TextInputType.number),
        const SizedBox(height: 12),
        _field(_bankName, 'Tên ngân hàng', 'VD: Vietcombank', accent),
        const SizedBox(height: 12),
        _field(_bankHolder, 'Tên chủ tài khoản', 'NGUYEN VAN A', accent),
        const SizedBox(height: 24),
        _accentBtn(
          'Thanh toán 59,000 VND',
          accent,
          () => app.setPaymentStep(PaymentStep.otp),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _visaInput(AppStateProvider app) {
    const accent = Color(0xFF1A1F71);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Thông tin thẻ',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _field(_visaCard, 'Số thẻ (16 số)', '0000 0000 0000 0000', accent,
            keyboard: TextInputType.number, mono: true),
        const SizedBox(height: 12),
        _field(_visaHolder, 'Tên chủ thẻ', 'NGUYEN VAN A', accent),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                  _visaExpiry, 'Hạn thẻ', 'MM/YY', accent,
                  keyboard: TextInputType.datetime),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_visaCvv, 'CVV', '***', accent,
                  keyboard: TextInputType.number, obscure: true),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _accentBtn(
          'Thanh toán 59,000 VND',
          accent,
          () => app.setPaymentStep(PaymentStep.otp),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint,
    Color focus, {
    TextInputType? keyboard,
    bool mono = false,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          style: TextStyle(
            fontFamily: mono ? 'monospace' : null,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: AppColors.muted.withValues(alpha: 0.6)),
            filled: true,
            fillColor: AppColors.surfaceMuted,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focus, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4: OTP ──

  Widget _buildOtp(AppStateProvider app) {
    final masked = _maskEmail(app.userEmail);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user,
                color: AppColors.primary, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nhập mã OTP',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mã xác minh 6 số đã được gửi đến',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  masked,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OtpInput(
          onChanged: (v) => setState(() {
            _otp = v;
            _otpError = false;
          }),
        ),
        if (_otpError) ...[
          const SizedBox(height: 8),
          const Text(
            'Ma OTP khong chinh xac',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: AppColors.destructive),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: Text.rich(
            TextSpan(
              style:
                  const TextStyle(fontSize: 13, color: AppColors.muted),
              children: [
                const TextSpan(text: 'Không nhận được mã? '),
                TextSpan(
                  text: 'Gửi lại',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _primaryBtn(
          'Xác nhận',
          _otp.length == 6
              ? () => app.setPaymentStep(PaymentStep.processing)
              : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step 5: Processing ──

  Widget _buildProcessing() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang xử lý giao dịch an toàn...',
            style: TextStyle(fontSize: 15, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // ── Step 6: Success ──

  Widget _buildSuccess() {
    final totalH =
        min(400.0, MediaQuery.sizeOf(context).height * 0.6);
    final screenW = MediaQuery.sizeOf(context).width;

    return ClipRect(
      child: SizedBox(
        height: totalH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _successScale,
                    child: const Icon(Icons.check_circle,
                        size: 80, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Thanh toán thành công!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chào mừng bạn đến với Premium.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleSuccess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Bắt đầu trải nghiệm',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (_, _) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: _confetti.map((p) {
                        final t = _confettiCtrl.value;
                        final dt = p.delay >= t
                            ? 0.0
                            : min(1.0,
                                (t - p.delay) / (1.0 - p.delay));
                        final opacity = dt < 0.8
                            ? 1.0
                            : max(0.0, (1.0 - dt) / 0.2);
                        return Positioned(
                          left: p.x * screenW,
                          top: -20 + dt * (totalH + 40),
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.rotate(
                              angle:
                                  p.rotation + p.speed * dt * pi,
                              child: Container(
                                width: p.w,
                                height: p.h,
                                decoration: BoxDecoration(
                                  color: p.color,
                                  borderRadius:
                                      BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared buttons ──

  Widget _primaryBtn(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor:
              Colors.white.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _accentBtn(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.rotation,
    required this.speed,
    required this.w,
    required this.h,
    required this.color,
  });

  final double x;
  final double delay;
  final double rotation;
  final double speed;
  final double w;
  final double h;
  final Color color;
}
