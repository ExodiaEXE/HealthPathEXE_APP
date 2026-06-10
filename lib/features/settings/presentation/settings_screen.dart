import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/utils/social_account_links.dart';
import 'package:health/domain/usecases/auth/change_password_usecase.dart';
import 'package:health/domain/usecases/auth/user_profile_usecases.dart';
import 'package:health/domain/entities/subscription_entities.dart';
import 'package:health/features/subscription/services/play_billing_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:health/features/settings/presentation/notification_views.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:health/shared/widgets/google_brand_icon.dart';
import 'package:health/shared/widgets/profile_text_field.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AppStateProvider, SettingsView>(
      selector: (_, app) => app.settingsView,
      builder: (context, view, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (view) {
            SettingsView.main => _MainSettings(key: const ValueKey('main')),
            SettingsView.editProfile =>
              _EditProfile(key: const ValueKey('edit')),
            SettingsView.changePassword =>
              _ChangePassword(key: const ValueKey('pw')),
            SettingsView.notifications =>
              const NotificationSettingsView(key: ValueKey('notif')),
            SettingsView.notificationInbox =>
              const NotificationInboxView(key: ValueKey('notif-inbox')),
            SettingsView.history => _History(key: const ValueKey('history')),
            SettingsView.wallet => _Wallet(key: const ValueKey('wallet')),
          },
        );
      },
    );
  }
}

// ─────────────────── ACCOUNT CONTACT ───────────────────

class _AccountContactRow extends StatelessWidget {
  const _AccountContactRow({required this.app});

  final AppStateProvider app;

  Future<void> _openFacebookProfile(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      AppSnackBar.show(context, 'Không mở được trang Facebook');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = app.authProvider;

    if (provider == AuthProviderType.facebook) {
      final fbUri = SocialAccountLinks.facebookProfileUri(app.userEmail);
      if (fbUri != null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.facebook, size: 14, color: Color(0xFF1877F2)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _openFacebookProfile(context, fbUri),
              child: Text(
                SocialAccountLinks.facebookLinkLabel(app.userEmail),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1877F2),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (provider == AuthProviderType.google)
          const GoogleBrandIcon(size: 14)
        else
          const Icon(Icons.email_outlined, size: 14, color: Color(0xFF999999)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            app.userEmail,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ),
      ],
    );
  }
}

class _FacebookProfileLinkCard extends StatelessWidget {
  const _FacebookProfileLinkCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final uri = SocialAccountLinks.facebookProfileUri(email)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECFA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tài khoản Facebook',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  SocialAccountLinks.facebookLinkLabel(email),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
            child: const Text('Mở'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── MAIN SETTINGS ───────────────────

class _MainSettings extends StatefulWidget {
  const _MainSettings({super.key});

  @override
  State<_MainSettings> createState() => _MainSettingsState();
}

class _MainSettingsState extends State<_MainSettings> {
  bool _avatarUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    if (_avatarUploading) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _avatarUploading = true);
    final app = context.read<AppStateProvider>();
    final upload = context.read<UploadAvatarUseCase>();
    try {
      final bytes = await picked.readAsBytes();
      final result = await upload(
        bytes: bytes,
        filename: picked.name,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      if (result.success && result.avatarUrl != null) {
        app.setAvatarUrl(result.avatarUrl);
        AppSnackBar.show(context, result.message ?? 'Đã cập nhật ảnh đại diện');
      } else {
        AppSnackBar.show(
          context,
          result.message ?? 'Không tải được ảnh đại diện',
        );
      }
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().refreshUnreadNotificationCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    final menuItems = [
      (icon: Icons.edit_outlined, label: 'Chỉnh sửa hồ sơ', color: const Color(0xFF3D7A2E), view: SettingsView.editProfile, enabled: true),
      (icon: Icons.lock_outline, label: 'Đổi mật khẩu', color: const Color(0xFF4A90C8), view: SettingsView.changePassword, enabled: !app.isSocialAuth),
      (icon: Icons.workspace_premium_outlined, label: 'Gói đăng ký', color: const Color(0xFFD63384), view: SettingsView.wallet, enabled: true),
      (icon: Icons.notifications_outlined, label: 'Thông báo', color: const Color(0xFFE8A87C), view: SettingsView.notifications, enabled: true),
      (icon: Icons.history, label: 'Lịch sử thói quen', color: const Color(0xFF4A90C8), view: SettingsView.history, enabled: true),
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
                onTap: _avatarUploading ? null : _pickAndUploadAvatar,
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
                      child: _avatarUploading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : app.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    app.avatarUrl!,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                  ),
                                )
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
              _AccountContactRow(app: app),
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
                          app.isPremium ? 'Cao cấp' : 'Miễn phí',
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
          final enabled = item.enabled;
          final iconColor = enabled ? item.color : const Color(0xFFBDBDBD);
          final textColor = enabled ? AppColors.foreground : const Color(0xFFBDBDBD);
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
                    color: enabled ? Colors.white : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: enabled ? AppColors.border : const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, size: 16, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                            if (!enabled && item.view == SettingsView.changePassword)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  app.authProvider == AuthProviderType.google
                                      ? 'Đăng nhập bằng Google'
                                      : 'Đăng nhập bằng Facebook',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (item.view == SettingsView.notifications &&
                          app.unreadNotificationCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            app.unreadNotificationCount > 99
                                ? '99+'
                                : '${app.unreadNotificationCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(Icons.chevron_right, size: 16, color: enabled ? const Color(0xFFD4D4D4) : const Color(0xFFE0E0E0)),
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

class _EditProfileState extends State<_EditProfile>
    with AutomaticKeepAliveClientMixin {
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppStateProvider>();
    final p = app.profile;
    _controllers = {
      'lastName': TextEditingController(text: p.lastName),
      'firstName': TextEditingController(text: p.firstName),
      'email': TextEditingController(text: app.userEmail),
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

  Future<void> _save() async {
    if (_saving) return;
    final lastName = _controllers['lastName']!.text.trim();
    final firstName = _controllers['firstName']!.text.trim();
    if (lastName.isEmpty || firstName.isEmpty) {
      AppSnackBar.show(context, 'Vui lòng nhập họ và tên');
      return;
    }

    setState(() => _saving = true);
    final app = context.read<AppStateProvider>();
    final update = context.read<UpdateUserProfileUseCase>();
    final fullName = '$lastName $firstName'.trim();
    final phone = _controllers['phone']!.text.trim();

    try {
      final result = await update(fullName: fullName, phone: phone);
      if (!mounted) return;
      if (!result.success) {
        AppSnackBar.show(
          context,
          result.message ?? 'Không lưu được hồ sơ',
        );
        return;
      }
      app.setProfile(UserProfile(
        lastName: lastName,
        firstName: firstName,
        email: app.userEmail,
        phone: phone,
        dob: _controllers['dob']!.text.trim(),
      ));
      if (result.avatarUrl != null) {
        app.setAvatarUrl(result.avatarUrl);
      }
      AppSnackBar.show(context, result.message ?? 'Đã lưu thay đổi');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final app = context.read<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Chỉnh sửa hồ sơ', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),
        ProfileTextField(
          key: const ValueKey('profile-lastName'),
          controller: _controllers['lastName']!,
          label: 'Họ',
          icon: Icons.person_outline,
          placeholder: 'Nguyễn',
        ),
        const SizedBox(height: 12),
        ProfileTextField(
          key: const ValueKey('profile-firstName'),
          controller: _controllers['firstName']!,
          label: 'Tên',
          icon: Icons.person_outline,
          placeholder: 'Văn A',
          helper: 'Tên hiển thị — không phải username đăng nhập',
        ),
        const SizedBox(height: 12),
        if (app.authProvider == AuthProviderType.facebook &&
            SocialAccountLinks.facebookProfileUri(app.userEmail) != null)
          _FacebookProfileLinkCard(email: app.userEmail)
        else
          ProfileTextField(
            key: const ValueKey('profile-email'),
            controller: _controllers['email']!,
            label: 'Thư điện tử',
            icon: Icons.email_outlined,
            placeholder: 'nguoi.dung@email.com',
            helper: 'Email tài khoản — không đổi tại đây',
            readOnly: true,
            keyboardType: TextInputType.emailAddress,
          ),
        const SizedBox(height: 12),
        ProfileTextField(
          key: const ValueKey('profile-phone'),
          controller: _controllers['phone']!,
          label: 'Số điện thoại',
          icon: Icons.phone_outlined,
          placeholder: '0901 234 567',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        ProfileTextField(
          key: const ValueKey('profile-dob'),
          controller: _controllers['dob']!,
          label: 'Ngày sinh',
          icon: Icons.calendar_today_outlined,
          placeholder: '01/01/1990',
        ),
        const SizedBox(height: 20),
        _greenButton(
          _saving ? 'Đang lưu...' : 'Lưu thay đổi',
          _saving ? () {} : _save,
        ),
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
  bool _loading = false;
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

  String _socialPasswordNote(AuthProviderType provider) {
    switch (provider) {
      case AuthProviderType.google:
        return 'Bạn đang đăng nhập bằng Google. Mật khẩu được quản lý bởi Google — không thể đổi tại đây.';
      case AuthProviderType.facebook:
        return 'Bạn đang đăng nhập bằng Facebook. Mật khẩu được quản lý bởi Facebook — không thể đổi tại đây.';
      case AuthProviderType.email:
        return '';
    }
  }

  Future<void> _save() async {
    setState(() {
      _error = '';
      _loading = false;
    });
    if (_oldPw.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu cũ');
      return;
    }
    if (!_allPass) {
      setState(() => _error = 'Mật khẩu mới chưa đủ điều kiện');
      return;
    }
    if (!_passwordsMatch) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _loading = true);
    final change = context.read<ChangePasswordUseCase>();
    final res = await change(
      currentPassword: _oldPw.text,
      newPassword: _newPw.text,
    );
    if (!mounted) return;

    setState(() => _loading = false);
    if (res.success) {
      final app = context.read<AppStateProvider>();
      final creds = app.savedCredentials;
      if (creds != null) {
        app.setSavedCredentials((email: creds.email, password: _newPw.text));
      }
      _oldPw.clear();
      _newPw.clear();
      _confirmPw.clear();
      AppSnackBar.show(
        context,
        res.message ?? 'Đổi mật khẩu thành công!',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() => _error = res.message ?? 'Đổi mật khẩu thất bại.');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final isSocial = app.isSocialAuth;
    final fieldsEnabled = !isSocial;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Đổi mật khẩu', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),
        if (isSocial)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                app.authProvider == AuthProviderType.google
                    ? const GoogleBrandIcon(size: 18)
                    : const Icon(Icons.facebook, size: 18, color: Color(0xFF1877F2)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _socialPasswordNote(app.authProvider),
                    style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
        _pwField('Mật khẩu cũ', _oldPw, _showOld, () => setState(() => _showOld = !_showOld), 'Nhập mật khẩu hiện tại', enabled: fieldsEnabled),
        const SizedBox(height: 12),
        _pwField('Mật khẩu mới', _newPw, _showNew, () => setState(() => _showNew = !_showNew), 'Nhập mật khẩu mới', enabled: fieldsEnabled),
        if (_newPw.text.isNotEmpty && fieldsEnabled) ...[
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
          enabled: fieldsEnabled,
          errorBorder: fieldsEnabled && _confirmPw.text.isNotEmpty && !_passwordsMatch),
        if (fieldsEnabled && _confirmPw.text.isNotEmpty && !_passwordsMatch)
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
        const SizedBox(height: 20),
        _greenButton(
          _loading ? 'Đang xử lý...' : 'Đổi mật khẩu',
          _loading || isSocial ? null : _save,
          enabled: fieldsEnabled && !_loading && _allPass && _passwordsMatch && _oldPw.text.isNotEmpty,
        ),
      ],
    );
  }

  Widget _pwField(
    String label,
    TextEditingController ctrl,
    bool visible,
    VoidCallback toggle,
    String hint, {
    bool enabled = true,
    bool errorBorder = false,
  }) {
    final labelColor = enabled ? const Color(0xFF666666) : const Color(0xFFBDBDBD);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.lock_outline, size: 12, color: labelColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: labelColor)),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: enabled,
          readOnly: !enabled,
          obscureText: !visible,
          onChanged: enabled ? (_) => setState(() {}) : null,
          style: TextStyle(fontSize: 14, color: enabled ? AppColors.foreground : AppColors.muted),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: enabled ? const Color(0xFFBBBBBB) : const Color(0xFFD4D4D4)),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorBorder ? const Color(0xFFE57373) : (enabled ? AppColors.border : const Color(0xFFEEEEEE)))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorBorder ? const Color(0xFFE57373) : (enabled ? AppColors.border : const Color(0xFFEEEEEE)))),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorBorder ? const Color(0xFFE57373) : AppColors.primary, width: 2)),
            suffixIcon: IconButton(
              icon: Icon(visible ? Icons.visibility_off : Icons.visibility, size: 16, color: enabled ? const Color(0xFFBBBBBB) : const Color(0xFFD4D4D4)),
              onPressed: enabled ? toggle : null,
            ),
          ),
        ),
      ],
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
                    Expanded(
                      child: Text(
                        h.text,
                        style: TextStyle(
                          fontSize: 12,
                          color: h.done ? AppColors.primary : const Color(0xFF666666),
                          decoration: h.done ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ]),
                )),
                if (record.energyLevel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Năng lượng: ${_energyLabel(record.energyLevel!)}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF999999)),
                  ),
                ],
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
                        record.rating == 5 ? 'Tuyệt vời' : record.rating! >= 3 ? 'Ổn' : 'Cần cố gắng',
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

  String _energyLabel(EnergyLevel level) {
    switch (level) {
      case EnergyLevel.low:
        return 'Thấp';
      case EnergyLevel.medium:
        return 'Trung bình';
      case EnergyLevel.high:
        return 'Cao';
    }
  }
}

// ─────────────────── SUBSCRIPTION / WALLET ───────────────────

class _Wallet extends StatefulWidget {
  const _Wallet({super.key});

  @override
  State<_Wallet> createState() => _WalletState();
}

class _WalletState extends State<_Wallet> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final app = context.read<AppStateProvider>();
    await app.syncSubscriptionFromServer();
    await app.loadSubscriptionTransactions();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _restore() async {
    await context.read<PlayBillingService>().restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 2));
    await _refresh();
    if (!mounted) return;
    final app = context.read<AppStateProvider>();
    AppSnackBar.show(
      context,
      app.isPremium ? 'Đã khôi phục gói đăng ký.' : 'Không tìm thấy gói trên tài khoản Google.',
    );
  }

  Future<void> _openManageSubscriptions() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=com.example.health',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _buildBackHeader('Gói đăng ký', () => app.setSettingsView(SettingsView.main)),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          const Text(
            'GÓI HIỆN TẠI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedForeground,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          if (app.isPremium && app.premiumInfo != null)
            _premiumCard(app.premiumInfo!)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_outlined, size: 32, color: Color(0xFFD4D4D4)),
                  const SizedBox(height: 8),
                  const Text('Bạn đang dùng gói Miễn phí', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _greenButton('Nâng cấp Cao cấp', () => app.setPaymentStep(PaymentStep.plan)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restore,
                  child: const Text('Khôi phục gói', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _openManageSubscriptions,
                  child: const Text('Quản lý trên Play', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          if (app.subscriptionTransactions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'LỊCH SỬ GIAO DỊCH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.mutedForeground,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            ...app.subscriptionTransactions.map(_transactionTile),
          ],
        ],
      ],
    );
  }

  Widget _transactionTile(SubscriptionTransactionRecord tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.planName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  _fmtDt(tx.purchasedAt),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            tx.status,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
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
          if (info.amountVnd > 0)
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
