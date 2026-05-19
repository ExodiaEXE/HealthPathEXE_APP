import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_button.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return switch (app.settingsView) {
      SettingsView.main => _MainSettings(onNavigate: app.setSettingsView),
      SettingsView.editProfile => _EditProfile(onBack: () => app.setSettingsView(SettingsView.main)),
      SettingsView.changePassword => _ChangePassword(onBack: () => app.setSettingsView(SettingsView.main)),
      SettingsView.notifications => _Notifications(onBack: () => app.setSettingsView(SettingsView.main)),
      SettingsView.history => _History(onBack: () => app.setSettingsView(SettingsView.main)),
      SettingsView.wallet => _Wallet(onBack: () => app.setSettingsView(SettingsView.main)),
    };
  }
}

class _MainSettings extends StatelessWidget {
  const _MainSettings({required this.onNavigate});

  final ValueChanged<SettingsView> onNavigate;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(app.userEmail, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (app.isPremium)
                    const Chip(label: Text('Premium', style: TextStyle(fontSize: 10)), backgroundColor: Color(0x33D4855A)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _tile(Icons.edit, 'Chinh sua ho so', () => onNavigate(SettingsView.editProfile)),
        _tile(Icons.lock_outline, 'Doi mat khau', () => onNavigate(SettingsView.changePassword)),
        _tile(Icons.notifications_outlined, 'Thong bao', () => onNavigate(SettingsView.notifications)),
        _tile(Icons.history, 'Lich su thoi quen', () => onNavigate(SettingsView.history)),
        _tile(Icons.account_balance_wallet_outlined, 'Vi & thanh toan', () => onNavigate(SettingsView.wallet)),
        if (!app.isPremium)
          _tile(Icons.workspace_premium, 'Nang cap Premium', () => app.setPaymentStep(PaymentStep.plan)),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.destructive),
          title: const Text('Dang xuat', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold)),
          onTap: () => app.logout(),
        ),
        const SizedBox(height: 24),
        const Center(child: Text('HealthPath v1.0.0', style: TextStyle(fontSize: 10, color: AppColors.muted))),
      ],
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}

class _EditProfile extends StatefulWidget {
  const _EditProfile({required this.onBack});
  final VoidCallback onBack;

  @override
  State<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<_EditProfile> {
  late final TextEditingController _lastName;
  late final TextEditingController _firstName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _dob;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppStateProvider>().profile;
    _lastName = TextEditingController(text: p.lastName);
    _firstName = TextEditingController(text: p.firstName);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _dob = TextEditingController(text: p.dob);
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppStateProvider>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)), const Text('Chinh sua ho so', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          TextField(controller: _lastName, decoration: const InputDecoration(labelText: 'Ho')),
          TextField(controller: _firstName, decoration: const InputDecoration(labelText: 'Ten')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'So dien thoai')),
          TextField(controller: _dob, decoration: const InputDecoration(labelText: 'Ngay sinh')),
          const Spacer(),
          HpPrimaryButton(
            label: 'Luu thay doi',
            onPressed: () {
              app.setProfile(UserProfile(
                lastName: _lastName.text,
                firstName: _firstName.text,
                email: _email.text,
                phone: _phone.text,
                dob: _dob.text,
              ));
              widget.onBack();
            },
          ),
        ],
      ),
    );
  }
}

class _ChangePassword extends StatelessWidget {
  const _ChangePassword({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)), const Text('Doi mat khau', style: TextStyle(fontWeight: FontWeight.bold))]),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Mat khau cu')),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Mat khau moi')),
          const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Xac nhan')),
          const Spacer(),
          HpPrimaryButton(label: 'Luu', onPressed: onBack),
        ],
      ),
    );
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)), const Text('Thong bao', style: TextStyle(fontWeight: FontWeight.bold))]),
        SwitchListTile(
          title: const Text('Push notifications'),
          value: app.notifSettings.pushEnabled,
          onChanged: (v) => app.setNotifSettings(app.notifSettings.copyWith(pushEnabled: v)),
        ),
        SwitchListTile(
          title: const Text('Am thanh'),
          value: app.notifSettings.soundEnabled,
          onChanged: (v) => app.setNotifSettings(app.notifSettings.copyWith(soundEnabled: v)),
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)), const Text('Lich su', style: TextStyle(fontWeight: FontWeight.bold))]),
        ...app.habitHistory.map((r) => Card(
              child: ListTile(
                title: Text(r.date),
                subtitle: Text(r.habits.map((h) => h.text).join(', ')),
                trailing: r.rating != null ? Row(mainAxisSize: MainAxisSize.min, children: List.generate(r.rating!, (_) => const Icon(Icons.star, size: 14, color: AppColors.coral))) : null,
              ),
            )),
      ],
    );
  }
}

class _Wallet extends StatelessWidget {
  const _Wallet({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)), const Text('Vi & thanh toan', style: TextStyle(fontWeight: FontWeight.bold))]),
        if (app.premiumInfo != null)
          Card(
            color: AppColors.primary.withValues(alpha: 0.08),
            child: ListTile(
              title: Text(app.premiumInfo!.productName),
              subtitle: Text('Het han: ${app.premiumInfo!.expiresAt.toLocal()}'),
            ),
          ),
        ...app.savedPaymentMethods.map((m) => Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text(m.label),
                subtitle: Text(m.maskedInfo),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
                  onPressed: () => app.removeSavedPaymentMethod(m.id),
                ),
              ),
            )),
        if (app.savedPaymentMethods.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Chua co phuong thuc thanh toan', style: TextStyle(color: AppColors.muted)))),
      ],
    );
  }
}
