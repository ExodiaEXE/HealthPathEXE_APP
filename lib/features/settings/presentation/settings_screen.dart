import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (app.settingsView) {
        SettingsView.main => _MainSettings(key: const ValueKey('main')),
        SettingsView.editProfile => _EditProfile(key: const ValueKey('edit')),
        SettingsView.changePassword => _ChangePassword(key: const ValueKey('pw')),
        SettingsView.notifications => _Notifications(key: const ValueKey('notif')),
        SettingsView.history => _History(key: const ValueKey('history')),
        SettingsView.wallet => _Wallet(key: const ValueKey('wallet')),
      },
    );
  }
}

// ─────────────────── MAIN SETTINGS ───────────────────

class _MainSettings extends StatelessWidget {
  const _MainSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    final menuItems = [
      (icon: Icons.edit_outlined, label: 'Chỉnh sửa hồ sơ', color: const Color(0xFF3D7A2E), view: SettingsView.editProfile),
      (icon: Icons.lock_outline, label: 'Đổi mật khẩu', color: const Color(0xFF4A90C8), view: SettingsView.changePassword),
      (icon: Icons.account_balance_wallet_outlined, label: 'Ví & Thanh toán', color: const Color(0xFFD63384), view: SettingsView.wallet),
      (icon: Icons.notifications_outlined, label: 'Thông báo', color: const Color(0xFFE8A87C), view: SettingsView.notifications),
      (icon: Icons.history, label: 'Lịch sử thói quen', color: const Color(0xFF4A90C8), view: SettingsView.history),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Profile card
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: () {},
                child: Stack(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                      ),
                      child: app.avatarUrl != null
                          ? ClipOval(child: Image.network(app.avatarUrl!, fit: BoxFit.cover, width: 64, height: 64))
                          : const Icon(Icons.person, size: 32, color: Colors.white),
                    ),
                    Positioned(
                      right: -2, bottom: -2,
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          app.avatarUrl != null ? Icons.camera_alt : Icons.add_photo_alternate,
                          size: 12, color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(app.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.foreground)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    app.authProvider == AuthProviderType.google ? Icons.g_mobiledata
                        : app.authProvider == AuthProviderType.facebook ? Icons.facebook
                        : Icons.email_outlined,
                    size: 14, color: const Color(0xFF999999),
                  ),
                  const SizedBox(width: 4),
                  Text(app.userEmail, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: app.isPremium ? const Color(0xFFE8A87C).withValues(alpha: 0.15) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (app.isPremium) const Icon(Icons.workspace_premium, size: 12, color: Color(0xFFE8A87C)),
                        if (app.isPremium) const SizedBox(width: 4),
                        Text(
                          app.isPremium ? 'Premium' : 'Free',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: app.isPremium ? const Color(0xFFE8A87C) : const Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                  if (!app.isPremium) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => app.setPaymentStep(PaymentStep.plan),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF8CC084)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Nâng cấp', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!app.profile.isComplete)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () => app.setSettingsView(SettingsView.editProfile),
                    child: const Text(
                      'Hoàn thiện hồ sơ cá nhân',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFE57373), decoration: TextDecoration.underline),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Menu items
        ...List.generate(menuItems.length, (i) {
          final item = menuItems[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => app.setSettingsView(item.view),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, size: 16, color: item.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground))),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD4D4D4)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 8),

        // Security card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.shield_outlined, size: 20, color: AppColors.accent)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Dữ liệu nhật ký cảm xúc được bảo mật an toàn tuyệt đối', style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.mutedForeground))),
            ],
          ),
        ),

        // Safety card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE57373).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.warning_amber, size: 20, color: Color(0xFFE57373))),
              const SizedBox(width: 12),
              const Expanded(child: Text('Nếu bạn cảm thấy áp lực kéo dài, hãy tham khảo ý kiến chuyên gia y tế.', style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.mutedForeground))),
            ],
          ),
        ),

        // Logout
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => app.logout(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 16, color: Color(0xFFE57373)),
                  SizedBox(width: 8),
                  Text('Đăng xuất', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE57373))),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 12, color: Color(0xFFD4D4D4)),
            const SizedBox(width: 6),
            Flexible(child: Text('Công cụ đồng hành dự phòng, không thay thế liệu pháp y khoa chuyên nghiệp.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, height: 1.5, color: const Color(0xFFBBBBBB)))),
          ],
        ),
      ],
    );
  }
}

// ─────────────────── EDIT PROFILE ───────────────────

class _EditProfile extends StatefulWidget {
  const _EditProfile({super.key});

  @override
  State<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<_EditProfile> {
  late final Map<String, TextEditingController> _controllers;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppStateProvider>().profile;
    _controllers = {
      'lastName': TextEditingController(text: p.lastName),
      'firstName': TextEditingController(text: p.firstName),
      'email': TextEditingController(text: p.email),
      'phone': TextEditingController(text: p.phone),
      'dob': TextEditingController(text: p.dob),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final app = context.read<AppStateProvider>();
    app.setProfile(UserProfile(
      lastName: _controllers['lastName']!.text,
      firstName: _controllers['firstName']!.text,
      email: _controllers['email']!.text,
      phone: _controllers['phone']!.text,
      dob: _controllers['dob']!.text,
    ));
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppStateProvider>();
    final fields = [
      (key: 'lastName', label: 'Họ', icon: Icons.person_outline, placeholder: 'Nguyen'),
      (key: 'firstName', label: 'Tên', icon: Icons.person_outline, placeholder: 'Van A'),
      (key: 'email', label: 'Email', icon: Icons.email_outlined, placeholder: 'user@email.com'),
      (key: 'phone', label: 'Số điện thoại', icon: Icons.phone_outlined, placeholder: '0901 234 567'),
      (key: 'dob', label: 'Ngày sinh', icon: Icons.calendar_today_outlined, placeholder: 'YYYY-MM-DD'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Chỉnh sửa hồ sơ', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),
        ...fields.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(f.icon, size: 12, color: const Color(0xFF666666)),
                const SizedBox(width: 6),
                Text(f.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
              ]),
              const SizedBox(height: 6),
              TextField(
                controller: _controllers[f.key],
                style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                decoration: InputDecoration(
                  hintText: f.placeholder,
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
            ],
          ),
        )),
        if (_saved)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã lưu thay đổi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _greenButton('Lưu thay đổi', _save),
      ],
    );
  }
}

// ─────────────────── CHANGE PASSWORD ───────────────────

class _ChangePassword extends StatefulWidget {
  const _ChangePassword({super.key});

  @override
  State<_ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<_ChangePassword> {
  final _oldPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();
  bool _showOld = false, _showNew = false, _showConfirm = false;
  bool _saved = false;
  String _error = '';

  static final _rules = [
    (id: 'len', label: 'Ít nhất 8 ký tự', test: (String p) => p.length >= 8),
    (id: 'upper', label: 'Có chữ hoa (A-Z)', test: (String p) => RegExp(r'[A-Z]').hasMatch(p)),
    (id: 'lower', label: 'Có chữ thường (a-z)', test: (String p) => RegExp(r'[a-z]').hasMatch(p)),
    (id: 'num', label: 'Có chữ số (0-9)', test: (String p) => RegExp(r'[0-9]').hasMatch(p)),
    (id: 'special', label: 'Có ký tự đặc biệt (!@#\$...)', test: (String p) => RegExp(r'[^A-Za-z0-9]').hasMatch(p)),
  ];

  @override
  void dispose() {
    _oldPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  bool get _allPass => _rules.every((r) => r.test(_newPw.text));
  bool get _passwordsMatch => _newPw.text == _confirmPw.text && _confirmPw.text.isNotEmpty;

  void _save() {
    setState(() => _error = '');
    if (_oldPw.text.isEmpty) { setState(() => _error = 'Vui lòng nhập mật khẩu cũ'); return; }
    if (!_allPass) { setState(() => _error = 'Mật khẩu mới chưa đủ điều kiện'); return; }
    if (!_passwordsMatch) { setState(() => _error = 'Mật khẩu xác nhận không khớp'); return; }
    _oldPw.clear(); _newPw.clear(); _confirmPw.clear();
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Đổi mật khẩu', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),
        _pwField('Mật khẩu cũ', _oldPw, _showOld, () => setState(() => _showOld = !_showOld), 'Nhập mật khẩu hiện tại'),
        const SizedBox(height: 12),
        _pwField('Mật khẩu mới', _newPw, _showNew, () => setState(() => _showNew = !_showNew), 'Nhập mật khẩu mới'),
        if (_newPw.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YÊU CẦU MẬT KHẨU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF666666), letterSpacing: 1)),
                const SizedBox(height: 8),
                ..._rules.map((r) {
                  final pass = r.test(_newPw.text);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pass ? AppColors.primary : const Color(0xFFEEEEEE),
                        ),
                        child: pass ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(r.label, style: TextStyle(fontSize: 11, fontWeight: pass ? FontWeight.w500 : FontWeight.normal, color: pass ? AppColors.primary : const Color(0xFF999999))),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _pwField('Xác nhận mật khẩu', _confirmPw, _showConfirm, () => setState(() => _showConfirm = !_showConfirm), 'Nhập lại mật khẩu mới',
          errorBorder: _confirmPw.text.isNotEmpty && !_passwordsMatch),
        if (_confirmPw.text.isNotEmpty && !_passwordsMatch)
          const Padding(padding: EdgeInsets.only(top: 4), child: Text('Mật khẩu xác nhận không khớp', style: TextStyle(fontSize: 11, color: Color(0xFFE57373)))),
        if (_error.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE57373).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.warning_amber, size: 16, color: Color(0xFFE57373)),
              const SizedBox(width: 8),
              Expanded(child: Text(_error, style: const TextStyle(fontSize: 12, color: Color(0xFFE57373)))),
            ]),
          ),
        if (_saved)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã đổi mật khẩu thành công', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _greenButton('Đổi mật khẩu', _save, enabled: _allPass && _passwordsMatch && _oldPw.text.isNotEmpty),
      ],
    );
  }

  Widget _pwField(String label, TextEditingController ctrl, bool visible, VoidCallback toggle, String hint, {bool errorBorder = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.lock_outline, size: 12, color: Color(0xFF666666)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: !visible,
          onChanged: (v) => setState(() {}),
          style: const TextStyle(fontSize: 14, color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorBorder ? const Color(0xFFE57373) : AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorBorder ? const Color(0xFFE57373) : AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorBorder ? const Color(0xFFE57373) : AppColors.primary, width: 2)),
            suffixIcon: IconButton(
              icon: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 16, color: const Color(0xFFBBBBBB)),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── NOTIFICATIONS ───────────────────

class _Notifications extends StatelessWidget {
  const _Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Thông báo', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),
        _toggleCard(
          icon: Icons.notifications_active, iconColor: AppColors.accent,
          title: 'Cho phép gửi thông báo', subtitle: 'Nhận nhắc nhở thói quen hàng ngày',
          value: app.notifSettings.pushEnabled,
          onToggle: () => app.setNotifSettings(app.notifSettings.copyWith(pushEnabled: !app.notifSettings.pushEnabled)),
        ),
        const SizedBox(height: 12),
        _toggleCard(
          icon: Icons.volume_up, iconColor: const Color(0xFFE8A87C),
          title: 'Âm thanh chuông báo', subtitle: 'Phát âm khi có thông báo mới',
          value: app.notifSettings.soundEnabled,
          onToggle: () => app.setNotifSettings(app.notifSettings.copyWith(soundEnabled: !app.notifSettings.soundEnabled)),
        ),
      ],
    );
  }

  Widget _toggleCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool value, required VoidCallback onToggle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: value ? AppColors.primary : const Color(0xFFD4D4D4),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24, height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 4)]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── HISTORY ───────────────────

class _History extends StatelessWidget {
  const _History({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final sorted = List<HabitRecord>.from(app.habitHistory)..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Lịch sử thói quen', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Column(
              children: [
                const Icon(Icons.history, size: 40, color: Color(0xFFD4D4D4)),
                const SizedBox(height: 12),
                const Text('Chưa có lịch sử nào', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
              ],
            ),
          ),
        ...sorted.map((record) {
          final isToday = record.date == todayStr;
          final isPast = record.date.compareTo(todayStr) < 0;
          final completed = record.habits.where((h) => h.done).length;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isToday ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(_formatDate(record.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Text('HÔM NAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ],
                  const Spacer(),
                  Text('$completed/${record.habits.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
                const SizedBox(height: 10),
                ...record.habits.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: h.done ? AppColors.primary : const Color(0xFFEEEEEE)),
                      child: h.done ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(h.text, style: TextStyle(fontSize: 12, color: h.done ? AppColors.primary : const Color(0xFF666666), decoration: h.done ? TextDecoration.lineThrough : null))),
                  ]),
                )),
                if (isPast) ...[
                  Container(height: 1, color: const Color(0xFFF0F0F0), margin: const EdgeInsets.symmetric(vertical: 8)),
                  Row(children: [
                    const Text('Đánh giá:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF999999))),
                    const SizedBox(width: 8),
                    ...List.generate(5, (s) {
                      final starNum = s + 1;
                      final filled = record.rating != null && starNum <= record.rating!;
                      return GestureDetector(
                        onTap: () => app.updateHistoryRating(record.date, starNum),
                        child: Icon(filled ? Icons.star : Icons.star_border, size: 16, color: filled ? const Color(0xFFE8A87C) : const Color(0xFFD4D4D4)),
                      );
                    }),
                    if (record.rating != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        record.rating == 5 ? 'Tuyệt vời' : record.rating! >= 3 ? 'On' : 'Cần cố gắng',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFE8A87C)),
                      ),
                    ],
                  ]),
                ],
                if (isToday) ...[
                  Container(height: 1, color: const Color(0xFFF0F0F0), margin: const EdgeInsets.symmetric(vertical: 8)),
                  const Text('Đánh giá sẽ khả dụng khi ngày kết thúc', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF999999))),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    const dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${dayNames[d.weekday % 7]}, ${d.day}/${d.month}/${d.year}';
  }
}

// ─────────────────── WALLET ───────────────────

class _Wallet extends StatefulWidget {
  const _Wallet({super.key});

  @override
  State<_Wallet> createState() => _WalletState();
}

class _WalletState extends State<_Wallet> {
  String? _addingType;
  String? _confirmDelete;

  final _momoPhone = TextEditingController();
  final _momoName = TextEditingController();
  bool _momoOtpStep = false;
  final _momoOtp = TextEditingController();
  bool _momoLoading = false;

  final _bankAcc = TextEditingController();
  final _bankName = TextEditingController();
  final _bankHolder = TextEditingController();

  final _visaCard = TextEditingController();
  final _visaHolder = TextEditingController();
  final _visaExpiry = TextEditingController();
  final _visaCvv = TextEditingController();

  static const _meta = {
    'momo': (label: 'Ví MoMo', color: Color(0xFFD63384), icon: '📱'),
    'bank': (label: 'Ngân hàng / Napas', color: Color(0xFF4A90C8), icon: '🏦'),
    'visa': (label: 'Visa / Mastercard', color: Color(0xFF1A1F71), icon: '💳'),
  };

  @override
  void dispose() {
    _momoPhone.dispose(); _momoName.dispose(); _momoOtp.dispose();
    _bankAcc.dispose(); _bankName.dispose(); _bankHolder.dispose();
    _visaCard.dispose(); _visaHolder.dispose(); _visaExpiry.dispose(); _visaCvv.dispose();
    super.dispose();
  }

  void _resetForm() {
    _addingType = null;
    _momoPhone.clear(); _momoName.clear(); _momoOtpStep = false; _momoOtp.clear(); _momoLoading = false;
    _bankAcc.clear(); _bankName.clear(); _bankHolder.clear();
    _visaCard.clear(); _visaHolder.clear(); _visaExpiry.clear(); _visaCvv.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Ví & Thanh toán', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),

        // Products section
        const Text('SẢN PHẨM ĐÃ MUA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedForeground, letterSpacing: 1)),
        const SizedBox(height: 10),
        if (app.isPremium && app.premiumInfo != null) _premiumCard(app.premiumInfo!)
        else Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2, strokeAlign: BorderSide.strokeAlignInside),
          ),
          child: const Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFFD4D4D4)),
              SizedBox(height: 8),
              Text('Chưa có sản phẩm nào', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment methods section
        const Text('TÀI KHOẢN THANH TOÁN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedForeground, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...app.savedPaymentMethods.map((pm) => _savedMethodCard(pm, app)),
        if (_addingType != null) _addForm(app),
        if (_addingType == null) ...['momo', 'bank', 'visa'].map((t) {
          final m = _meta[t]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _addingType = t),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4D4D4), style: BorderStyle.solid),
                  color: const Color(0xFFFAFAFA),
                ),
                child: Row(children: [
                  Text(m.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Thêm ${m.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground))),
                  const Icon(Icons.add, size: 14, color: Color(0xFFBBBBBB)),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _premiumCard(PremiumInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.workspace_premium, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.foreground)),
                Text('Mã: ${info.productId}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            )),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: info.benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.check, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(b, style: const TextStyle(fontSize: 12, color: AppColors.foreground)),
                ]),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Hóa đơn', '${_formatAmount(info.amountVnd)} VND'),
          _infoRow('Thanh toán qua', info.paidWith),
          _infoRow('Ngày thanh toán', _fmtDt(info.paidAt)),
          _infoRow('Hết hạn', _fmtDt(info.expiresAt), valueColor: const Color(0xFFE8A87C)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.foreground)),
      ]),
    );
  }

  Widget _savedMethodCard(SavedPaymentMethod pm, AppStateProvider app) {
    final m = _meta[pm.type.name];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (m?.color ?? AppColors.accent).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(m?.icon ?? '💳', style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m?.label ?? pm.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)),
            Text('${pm.maskedInfo}${pm.detail != null ? ' - ${pm.detail}' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        )),
        if (_confirmDelete == pm.id)
          Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: () { app.removeSavedPaymentMethod(pm.id); setState(() => _confirmDelete = null); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE57373), borderRadius: BorderRadius.circular(8)),
                child: const Text('Xóa', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _confirmDelete = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                child: const Text('Hủy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
              ),
            ),
          ])
        else
          GestureDetector(
            onTap: () => setState(() => _confirmDelete = pm.id),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFF999999)),
            ),
          ),
      ]),
    );
  }

  Widget _addForm(AppStateProvider app) {
    if (_addingType == 'momo') return _momoForm(app);
    if (_addingType == 'bank') return _bankForm(app);
    if (_addingType == 'visa') return _visaForm(app);
    return const SizedBox.shrink();
  }

  Widget _momoForm(AppStateProvider app) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD63384).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD63384).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('📱 ', style: TextStyle(fontSize: 18)), Text('Liên kết Ví MoMo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          if (!_momoOtpStep) ...[
            _formInput(_momoPhone, 'Số điện thoại (VD: 0912345678)', focusColor: const Color(0xFFD63384)),
            const SizedBox(height: 8),
            _formInput(_momoName, 'Tên chủ tài khoản MoMo', focusColor: const Color(0xFFD63384)),
            const SizedBox(height: 12),
            _formButtons(
              primary: 'Gửi mã OTP', primaryColor: const Color(0xFFD63384),
              onPrimary: _momoPhone.text.trim().isEmpty || _momoName.text.trim().isEmpty || _momoLoading ? null : () {
                setState(() => _momoLoading = true);
                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (mounted) setState(() { _momoLoading = false; _momoOtpStep = true; });
                });
              },
              onCancel: _resetForm,
            ),
          ] else ...[
            Text('Mã OTP đã được gửi đến ${_momoPhone.text}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 8),
            _formInput(_momoOtp, 'Nhập mã OTP (6 số)', focusColor: const Color(0xFFD63384), center: true),
            const SizedBox(height: 12),
            _formButtons(
              primary: 'Xác nhận liên kết', primaryColor: const Color(0xFFD63384),
              onPrimary: _momoOtp.text.length < 4 ? null : () {
                final masked = _momoPhone.text.length > 4
                    ? '${_momoPhone.text.substring(0, 3)}***${_momoPhone.text.substring(_momoPhone.text.length - 3)}'
                    : _momoPhone.text;
                app.addSavedPaymentMethod(SavedPaymentMethod(
                  id: 'pm-${DateTime.now().millisecondsSinceEpoch}',
                  type: PaymentMethodType.momo, label: 'Ví MoMo',
                  maskedInfo: masked, detail: _momoName.text,
                ));
                _resetForm();
              },
              onCancel: _resetForm,
            ),
          ],
        ],
      ),
    );
  }

  Widget _bankForm(AppStateProvider app) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90C8).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A90C8).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('🏦 ', style: TextStyle(fontSize: 18)), Text('Thêm tài khoản ngân hàng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          _formInput(_bankAcc, 'Số tài khoản (VD: 1234567890)', focusColor: const Color(0xFF4A90C8)),
          const SizedBox(height: 8),
          _formInput(_bankName, 'Tên ngân hàng (VD: Vietcombank)', focusColor: const Color(0xFF4A90C8)),
          const SizedBox(height: 8),
          _formInput(_bankHolder, 'Tên chủ tài khoản', focusColor: const Color(0xFF4A90C8)),
          const SizedBox(height: 12),
          _formButtons(
            primary: 'Lưu tài khoản', primaryColor: const Color(0xFF4A90C8),
            onPrimary: _bankAcc.text.trim().isEmpty || _bankName.text.trim().isEmpty || _bankHolder.text.trim().isEmpty ? null : () {
              final masked = _bankAcc.text.length > 4 ? '****${_bankAcc.text.substring(_bankAcc.text.length - 4)}' : _bankAcc.text;
              app.addSavedPaymentMethod(SavedPaymentMethod(
                id: 'pm-${DateTime.now().millisecondsSinceEpoch}',
                type: PaymentMethodType.bank, label: 'Ngân hàng / Napas',
                maskedInfo: masked, detail: '${_bankName.text} - ${_bankHolder.text}',
              ));
              _resetForm();
            },
            onCancel: _resetForm,
          ),
        ],
      ),
    );
  }

  Widget _visaForm(AppStateProvider app) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F71).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1F71).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('💳 ', style: TextStyle(fontSize: 18)), Text('Thêm thẻ Visa / Mastercard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          _formInput(_visaCard, 'Số thẻ (16 số)', focusColor: const Color(0xFF1A1F71)),
          const SizedBox(height: 8),
          _formInput(_visaHolder, 'Tên chủ thẻ (in trên thẻ)', focusColor: const Color(0xFF1A1F71)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _formInput(_visaExpiry, 'MM/YY', focusColor: const Color(0xFF1A1F71))),
            const SizedBox(width: 8),
            SizedBox(width: 96, child: _formInput(_visaCvv, 'CVV', focusColor: const Color(0xFF1A1F71), obscure: true)),
          ]),
          const SizedBox(height: 12),
          _formButtons(
            primary: 'Lưu thẻ', primaryColor: const Color(0xFF1A1F71),
            onPrimary: _visaCard.text.trim().isEmpty || _visaHolder.text.trim().isEmpty || _visaExpiry.text.trim().isEmpty || _visaCvv.text.trim().isEmpty ? null : () {
              final masked = _visaCard.text.length > 4 ? '****${_visaCard.text.substring(_visaCard.text.length - 4)}' : _visaCard.text;
              app.addSavedPaymentMethod(SavedPaymentMethod(
                id: 'pm-${DateTime.now().millisecondsSinceEpoch}',
                type: PaymentMethodType.visa, label: 'Visa / Mastercard',
                maskedInfo: masked, detail: _visaHolder.text,
              ));
              _resetForm();
            },
            onCancel: _resetForm,
          ),
        ],
      ),
    );
  }

  Widget _formInput(TextEditingController ctrl, String hint, {Color focusColor = AppColors.primary, bool center = false, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      textAlign: center ? TextAlign.center : TextAlign.start,
      onChanged: (v) => setState(() {}),
      style: const TextStyle(fontSize: 14, color: AppColors.foreground),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: focusColor, width: 2)),
      ),
    );
  }

  Widget _formButtons({required String primary, required Color primaryColor, VoidCallback? onPrimary, required VoidCallback onCancel}) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: onPrimary,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: onPrimary != null ? primaryColor : primaryColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(primary, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: Text('Hủy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)))),
          ),
        ),
      ),
    ]);
  }

  String _formatAmount(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  String _fmtDt(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ─────────────────── SHARED HELPERS ───────────────────

Widget _buildBackHeader(String title, VoidCallback onBack) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Row(children: [
      GestureDetector(
        onTap: onBack,
        child: Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
          child: const Icon(Icons.chevron_left, size: 16, color: Color(0xFF666666)),
        ),
      ),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.foreground)),
    ]),
  );
}

Widget _greenButton(String label, VoidCallback? onTap, {bool enabled = true}) {
  final active = enabled && onTap != null;
  return GestureDetector(
    onTap: active ? onTap : null,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: active ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
    ),
  );
}
