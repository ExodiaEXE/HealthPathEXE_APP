import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_button.dart';
import 'package:health/shared/widgets/otp_input.dart';
import 'package:provider/provider.dart';

class PaymentModal extends StatefulWidget {
  const PaymentModal({super.key});

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _otp = '';
  final _cardNumber = TextEditingController();

  @override
  void dispose() {
    _cardNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final step = app.paymentStep;
    if (step == null) return const SizedBox.shrink();

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (step != PaymentStep.plan)
                      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _back(app, step)),
                    Expanded(child: Text(_title(step), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => app.setPaymentStep(null)),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _body(app, step),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(PaymentStep step) => switch (step) {
        PaymentStep.plan => 'HealthPath Premium',
        PaymentStep.method => 'Chon phuong thuc',
        PaymentStep.input => 'Nhap thong tin',
        PaymentStep.otp => 'Xac thuc OTP',
        PaymentStep.processing => 'Dang xu ly...',
        PaymentStep.success => 'Thanh cong!',
      };

  Widget _body(AppStateProvider app, PaymentStep step) {
    return switch (step) {
      PaymentStep.plan => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium, size: 48, color: AppColors.coral),
            const Text('59.000 VND/thang', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Text('• Khong quang cao\n• Toan bo audio\n• Chat luong cao\n• Ho tro uu tien'),
            const SizedBox(height: 16),
            if (!app.profile.isComplete)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.coral),
                    const SizedBox(width: 8),
                    Expanded(child: const Text('Hoan thien ho so truoc khi thanh toan', style: TextStyle(fontSize: 11))),
                    TextButton(onPressed: () { app.setPaymentStep(null); app.setSettingsView(SettingsView.editProfile); }, child: const Text('Sua')),
                  ],
                ),
              ),
            HpPrimaryButton(label: 'Tiep tuc', onPressed: app.profile.isComplete ? () => app.setPaymentStep(PaymentStep.method) : null),
          ],
        ),
      PaymentStep.method => Column(
          children: [
            _methodTile(app, PaymentMethodType.momo, 'Vi MoMo', Icons.account_balance_wallet),
            _methodTile(app, PaymentMethodType.bank, 'Ngan hang', Icons.account_balance),
            _methodTile(app, PaymentMethodType.visa, 'Visa/Mastercard', Icons.credit_card),
          ],
        ),
      PaymentStep.input => Column(
          children: [
            TextField(controller: _cardNumber, decoration: const InputDecoration(hintText: 'So tai khoan / the')),
            const SizedBox(height: 12),
            HpPrimaryButton(label: 'Tiep tuc', onPressed: () => app.setPaymentStep(PaymentStep.otp)),
          ],
        ),
      PaymentStep.otp => Column(
          children: [
            Text('Ma OTP gui den ${app.userEmail}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            OtpInput(onChanged: (v) => setState(() => _otp = v)),
            const SizedBox(height: 16),
            HpPrimaryButton(
              label: 'Xac nhan',
              onPressed: _otp.length == 6
                  ? () {
                      app.setPaymentStep(PaymentStep.processing);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (!mounted) return;
                        app.setIsPremium(true);
                        app.setPremiumInfo(PremiumInfo(
                          productId: 'HP-PRE-MOCK',
                          productName: 'HealthPath Premium',
                          benefits: const ['Khong quang cao', 'Audio day du'],
                          amountVnd: 59000,
                          paidWith: app.paymentMethod?.name ?? 'mock',
                          paidAt: DateTime.now(),
                          expiresAt: DateTime.now().add(const Duration(days: 30)),
                        ));
                        app.setPaymentStep(null);
                        app.navigateTo(ActiveTab.audio);
                      });
                    }
                  : null,
            ),
          ],
        ),
      PaymentStep.processing => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
      PaymentStep.success => const Icon(Icons.check_circle, size: 64, color: AppColors.primary),
    };
  }

  Widget _methodTile(AppStateProvider app, PaymentMethodType type, String label, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          app.setPaymentMethod(type);
          app.setPaymentStep(PaymentStep.input);
        },
      ),
    );
  }

  void _back(AppStateProvider app, PaymentStep step) {
    switch (step) {
      case PaymentStep.method:
        app.setPaymentStep(PaymentStep.plan);
      case PaymentStep.input:
        app.setPaymentStep(PaymentStep.method);
      case PaymentStep.otp:
        app.setPaymentStep(PaymentStep.input);
      default:
        app.setPaymentStep(null);
    }
  }
}
