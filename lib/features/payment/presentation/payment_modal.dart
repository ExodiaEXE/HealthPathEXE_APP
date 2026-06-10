import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/subscription_entities.dart';
import 'package:health/domain/usecases/subscription/subscription_usecases.dart';
import 'package:health/features/subscription/services/play_billing_service.dart';
import 'package:health/features/subscription/services/subscription_billing_coordinator.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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

  List<SubscriptionPlanRecord> _plans = [];
  final Map<String, ProductDetails> _storeProducts = {};
  String? _selectedProductId;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  bool _billingAvailable = false;

  static const _benefits = [
  ('Không quảng cáo', Icons.block, Color(0xFFE57373)),
  ('Toàn bộ audio thư giãn', Icons.headphones, Color(0xFF4A90C8)),
  ('Hỗ trợ ưu tiên', Icons.auto_awesome, Color(0xFFE8A87C)),
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

    SubscriptionBillingCoordinator.setHandlers(
      onSuccess: _onPurchaseVerified,
      onError: _onPurchaseError,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    SubscriptionBillingCoordinator.setHandlers();
    _sheetCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final fetchPlans = context.read<FetchSubscriptionPlansUseCase>();
    final billing = context.read<PlayBillingService>();
    await SubscriptionBillingCoordinator.ensureStarted();

    final plansResult = await fetchPlans();
    final plans = plansResult.plans
        .where((p) => p.googleProductId != null && p.googleProductId!.isNotEmpty)
        .toList();

    _billingAvailable = await billing.isAvailable;
    final productIds = plans
        .map((p) => p.googleProductId!)
        .toSet();

    if (_billingAvailable && productIds.isNotEmpty) {
      final response = await billing.queryProducts(productIds);
      if (response.error != null && kDebugMode) {
        debugPrint('PlayBilling query error: ${response.error}');
      }
      for (final product in response.productDetails) {
        _storeProducts[product.id] = product;
      }
    }

    if (!mounted) return;
    setState(() {
      _plans = plans;
      _selectedProductId ??= plans.isNotEmpty ? plans.first.googleProductId : null;
      _loading = false;
      if (!plansResult.success && plans.isEmpty) {
        _error = plansResult.message ?? 'Không tải được gói đăng ký.';
      }
    });
  }

  Future<void> _onPurchaseVerified(SubscriptionOperationResult result) async {
    if (!mounted) return;
    final app = context.read<AppStateProvider>();
    await app.applySubscriptionFromServer(result);
    setState(() => _purchasing = false);
    app.setPaymentStep(PaymentStep.success);
  }

  void _onPurchaseError(String message) {
    if (!mounted) return;
    setState(() => _purchasing = false);
    AppSnackBar.show(context, message);
  }

  Future<void> _subscribe() async {
    final productId = _selectedProductId;
    final product = productId != null ? _storeProducts[productId] : null;
    if (product == null) {
      AppSnackBar.show(
        context,
        'Chưa kết nối được Google Play. Thử lại sau khi tải app từ Internal testing.',
      );
      return;
    }

    setState(() => _purchasing = true);
    final app = context.read<AppStateProvider>();
    app.setPaymentStep(PaymentStep.processing);

    final billing = context.read<PlayBillingService>();
    final started = await billing.purchase(product);
    if (!started && mounted) {
      setState(() => _purchasing = false);
      app.setPaymentStep(PaymentStep.plan);
      AppSnackBar.show(context, 'Không mở được màn hình thanh toán Google Play.');
    }
  }

  Future<void> _restore() async {
    if (!_billingAvailable) {
      AppSnackBar.show(context, 'Google Play Billing chưa sẵn sàng trên thiết bị này.');
      return;
    }
    setState(() => _purchasing = true);
    final app = context.read<AppStateProvider>();
    app.setPaymentStep(PaymentStep.processing);
    await context.read<PlayBillingService>().restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await app.syncSubscriptionFromServer();
    setState(() => _purchasing = false);
    app.setPaymentStep(
      app.isPremium ? PaymentStep.success : PaymentStep.plan,
    );
    if (!app.isPremium) {
      AppSnackBar.show(context, 'Không tìm thấy gói đã mua trên tài khoản Google này.');
    }
  }

  Future<void> _devMockActivate() async {
    if (!kDebugMode || _plans.isEmpty) return;
    final plan = _plans.firstWhere(
      (p) => p.googleProductId == _selectedProductId,
      orElse: () => _plans.first,
    );
    final verify = context.read<VerifySubscriptionPurchaseUseCase>();
    setState(() => _purchasing = true);
    final result = await verify(
      productId: plan.googleProductId ?? plan.code,
      purchaseToken: 'mock_google_play_dev',
      billingCycle: plan.isYearly ? 'yearly' : 'monthly',
    );
    if (!mounted) return;
    if (result.success) {
      await _onPurchaseVerified(result);
    } else {
      setState(() => _purchasing = false);
      AppSnackBar.show(context, result.message ?? 'Mock verify thất bại.');
    }
  }

  void _handleSuccessClose() {
    final app = context.read<AppStateProvider>();
    app.setPaymentStep(null);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final step = app.paymentStep;
    if (step == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: step == PaymentStep.plan ? () => app.setPaymentStep(null) : null,
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
                      maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 25,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _header(app, step),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: switch (step) {
                              PaymentStep.plan => _buildPlan(app),
                              PaymentStep.processing => _buildProcessing(),
                              PaymentStep.success => _buildSuccess(),
                            },
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

  Widget _header(AppStateProvider app, PaymentStep step) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              switch (step) {
                PaymentStep.plan => 'HealthPath Cao cấp',
                PaymentStep.processing => 'Đang xử lý',
                PaymentStep.success => 'Thành công',
              },
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildPlan(AppStateProvider app) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
              ),
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đăng ký qua Google Play',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Thanh toán an toàn qua cửa hàng Google Play. Hủy bất cứ lúc nào trong Cài đặt Google Play.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.4),
        ),
        const SizedBox(height: 20),
        for (final item in _benefits) ...[
          _benefitRow(item.$2, item.$3, item.$1),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFE57373), fontSize: 12)),
          ),
        if (_plans.isEmpty)
          const Text(
            'Chưa có gói trên máy chủ. Kiểm tra backend seed subscription.',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          )
        else
          ..._plans.map(_planTile),
        const SizedBox(height: 20),
        _primaryBtn(
          _purchasing ? 'Đang xử lý...' : 'Đăng ký qua Google Play',
          _purchasing || _selectedProductId == null ? null : _subscribe,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _purchasing ? null : _restore,
          child: const Text(
            'Khôi phục gói đã mua',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
        if (kDebugMode && !_billingAvailable && EnvConfig.apiBaseUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: _purchasing ? null : _devMockActivate,
              child: const Text(
                'Kích hoạt thử (dev — backend mock)',
                style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
            ),
          ),
        if (!_billingAvailable)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Google Play Billing chỉ hoạt động khi cài app từ Play Console (internal/closed testing) với gói đã tạo trên Console.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA), height: 1.35),
            ),
          ),
      ],
    );
  }

  Widget _planTile(SubscriptionPlanRecord plan) {
    final productId = plan.googleProductId!;
    final store = _storeProducts[productId];
    final selected = _selectedProductId == productId;
    final priceLabel = store?.price ??
        (plan.isYearly
            ? '${_formatVnd(plan.priceYearly)} / năm'
            : '${_formatVnd(plan.priceMonthly)} / tháng');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedProductId = productId),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : const Color(0xFFCCCCCC),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(priceLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang xử lý với Google Play...', style: TextStyle(fontSize: 14)),
          SizedBox(height: 8),
          Text(
            'Vui lòng hoàn tất trong cửa sổ thanh toán nếu đã hiện.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chúc mừng!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gói HealthPath Cao cấp đã được kích hoạt.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          _primaryBtn('Bắt đầu sử dụng', _handleSuccessClose),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, Color color, String text) {
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  String _formatVnd(double amount) {
    final n = amount.round();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} đ';
  }
}
