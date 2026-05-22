import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_animated_auth_background.dart';
import 'package:health/shared/widgets/hp_button.dart';
import 'package:health/shared/widgets/hp_glass_card.dart';
import 'package:health/shared/widgets/hp_page_transition.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:health/shared/widgets/hp_text_field.dart';
import 'package:health/shared/widgets/otp_input.dart';
import 'package:provider/provider.dart';

enum _AuthView {
  login,
  register,
  registerOtp,
  forgotEmail,
  forgotOtp,
  forgotNewPw,
  forgotDone,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthView _view = _AuthView.login;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _name = TextEditingController();
  final _forgotEmail = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();
  bool _loading = false;
  String _regOtp = '';
  String _forgotOtp = '';
  int _regResendCooldown = 0;
  bool _showSocialDialog = false;
  AuthProviderType? _pendingSocial;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _name.dispose();
    _forgotEmail.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  bool _isPasswordValid(String pw) {
    return pw.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(pw) &&
        RegExp(r'[a-z]').hasMatch(pw) &&
        RegExp(r'\d').hasMatch(pw) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pw);
  }

  Future<void> _delay(Future<void> Function() action) async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await action();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      body: Stack(
        children: [
          const HpAnimatedAuthBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    builder: (context, v, child) => Transform.translate(
                      offset: Offset(0, 20 * (1 - v)),
                      child: Opacity(opacity: v, child: child),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: AppColors.cardShadow, blurRadius: 16),
                            ],
                          ),
                          child: const Icon(Icons.favorite, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 12),
                        const Text('HealthPath', style: AppTypography.display),
                        const Text('Hành trình sức khỏe của riêng bạn', style: AppTypography.bodySm),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCard(context, app),
                ],
              ),
            ),
          ),
          if (_showSocialDialog) _socialDialog(context, app),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppStateProvider app) {
    return HpGlassCard(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => HpAuthSlideTransition(
          animation: animation,
          enterFromLeft: _view == _AuthView.login || _view == _AuthView.forgotEmail,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_view),
          child: switch (_view) {
            _AuthView.login => _loginForm(app),
            _AuthView.register => _registerForm(app),
            _AuthView.registerOtp => _registerOtpForm(app),
            _AuthView.forgotEmail => _forgotEmailForm(),
            _AuthView.forgotOtp => _forgotOtpForm(),
            _AuthView.forgotNewPw => _forgotNewPwForm(),
            _AuthView.forgotDone => _forgotDoneForm(),
          },
        ),
      ),
    );
  }

  Widget _socialButton(String label, Widget icon) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(label, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.foreground)),
        ],
      ),
    );
  }

  Widget _orDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('hoặc', style: AppTypography.micro.copyWith(color: const Color(0xFFAAAAAA))),
            ),
            const Expanded(child: Divider(color: AppColors.border, height: 1)),
          ],
        ),
      );

  Widget _loginForm(AppStateProvider app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Đăng nhập', textAlign: TextAlign.center, style: AppTypography.title),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HpTapScale(
                onTap: () => _openSocial(AuthProviderType.google),
                child: _socialButton('Google', const Icon(Icons.g_mobiledata, size: 20)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HpTapScale(
                onTap: () => _openSocial(AuthProviderType.facebook),
                child: _socialButton('Facebook', const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 18)),
              ),
            ),
          ],
        ),
        _orDivider(),
        HpTextField(controller: _email, hint: 'Email', prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        HpTextField(controller: _password, hint: 'Mật khẩu', prefixIcon: Icons.lock_outline, obscureText: true),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              _forgotEmail.text = _email.text;
              setState(() => _view = _AuthView.forgotEmail);
            },
            child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ),
        HpPrimaryButton(
          label: 'Đăng nhập',
          loading: _loading,
          onPressed: () => _delay(() async {
            await app.completeAuth(email: _email.text.isEmpty ? 'user@healthpath.vn' : _email.text);
          }),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              app.setAuthState(AuthState.register);
              setState(() => _view = _AuthView.register);
            },
            child: const Text.rich(TextSpan(text: 'Chưa có tài khoản? ', children: [TextSpan(text: 'Đăng ký', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))])),
          ),
        ),
      ],
    );
  }

  Widget _registerForm(AppStateProvider app) {
    final valid = _name.text.trim().isNotEmpty &&
        _email.text.trim().isNotEmpty &&
        _isPasswordValid(_password.text) &&
        _password.text == _confirmPassword.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Đăng ký', textAlign: TextAlign.center, style: AppTypography.title),
        const SizedBox(height: 16),
        HpTextField(controller: _name, hint: 'Họ và tên', prefixIcon: Icons.person_outline),
        const SizedBox(height: 10),
        HpTextField(controller: _email, hint: 'Email', prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        HpTextField(controller: _password, hint: 'Mật khẩu', prefixIcon: Icons.lock_outline, obscureText: true, onChanged: (_) => setState(() {})),
        if (_password.text.isNotEmpty) _passwordRules(_password.text),
        const SizedBox(height: 10),
        HpTextField(controller: _confirmPassword, hint: 'Xác nhận mật khẩu', prefixIcon: Icons.lock_outline, obscureText: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        HpPrimaryButton(
          label: 'Tiếp tục',
          loading: _loading,
          onPressed: valid
              ? () => _delay(() async {
                    setState(() {
                      _view = _AuthView.registerOtp;
                      _regResendCooldown = 60;
                    });
                  })
              : null,
        ),
        TextButton(onPressed: () { app.setAuthState(AuthState.login); setState(() => _view = _AuthView.login); }, child: const Text('Da co tai khoan? Dang nhap')),
      ],
    );
  }

  Widget _registerOtpForm(AppStateProvider app) {
    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => _view = _AuthView.register), icon: const Icon(Icons.arrow_back, size: 18))),
        const Icon(Icons.verified_user, size: 48, color: AppColors.accent),
        const Text('Xác thực email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        OtpInput(onChanged: (v) => _regOtp = v),
        const SizedBox(height: 16),
        HpPrimaryButton(
          label: 'Xác nhận & đăng ký',
          loading: _loading,
          onPressed: _regOtp.length == 6
              ? () => _delay(() async {
                    await app.completeAuth(email: _email.text, name: _name.text);
                    app.setSavedCredentials((email: _email.text, password: _password.text));
                    app.setShowSaveCredentials(true);
                  })
              : null,
        ),
      ],
    );
  }

  Widget _forgotEmailForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(onPressed: () => setState(() => _view = _AuthView.login), icon: const Icon(Icons.arrow_back)),
          const Text('Quên mật khẩu', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          HpTextField(controller: _forgotEmail, hint: 'Email đăng ký', prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          HpPrimaryButton(
            label: 'Gui ma xac thuc',
            loading: _loading,
            onPressed: () => _delay(() async {
              setState(() => _view = _AuthView.forgotOtp);
            }),
          ),
        ],
      );

  Widget _forgotOtpForm() => Column(
        children: [
          IconButton(onPressed: () => setState(() => _view = _AuthView.forgotEmail), icon: const Icon(Icons.arrow_back)),
          OtpInput(onChanged: (v) => _forgotOtp = v),
          const SizedBox(height: 12),
          HpPrimaryButton(
            label: 'Xác nhận',
            loading: _loading,
            onPressed: _forgotOtp.length == 6
                ? () => _delay(() async {
                      setState(() => _view = _AuthView.forgotNewPw);
                    })
                : null,
          ),
        ],
      );

  Widget _forgotNewPwForm() {
    final ok = _isPasswordValid(_newPw.text) && _newPw.text == _confirmPw.text;
    return Column(
      children: [
        HpTextField(controller: _newPw, hint: 'Mật khẩu mới', prefixIcon: Icons.lock_outline, obscureText: true),
        const SizedBox(height: 8),
        HpTextField(controller: _confirmPw, hint: 'Xác nhận', prefixIcon: Icons.lock_outline, obscureText: true),
        const SizedBox(height: 12),
        HpPrimaryButton(
          label: 'Đặt lại mật khẩu',
          loading: _loading,
          onPressed: ok
              ? () => _delay(() async {
                    setState(() => _view = _AuthView.forgotDone);
                  })
              : null,
        ),
      ],
    );
  }

  Widget _forgotDoneForm() => Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 56),
          const Text('Đặt lại thành công', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          HpPrimaryButton(label: 'Quay về đăng nhập', onPressed: () => setState(() => _view = _AuthView.login)),
        ],
      );

  Widget _passwordRules(String pw) {
    final rules = [
      ('Tối thiểu 8 ký tự', pw.length >= 8),
      ('Có chữ in hoa', RegExp(r'[A-Z]').hasMatch(pw)),
      ('Có chữ in thường', RegExp(r'[a-z]').hasMatch(pw)),
      ('Có số', RegExp(r'\d').hasMatch(pw)),
      ('Có ký tự đặc biệt', RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pw)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules
          .map((r) => Text('${r.$2 ? '✓' : '•'} ${r.$1}', style: TextStyle(fontSize: 10, color: r.$2 ? AppColors.primary : AppColors.muted)))
          .toList(),
    );
  }

  void _openSocial(AuthProviderType p) {
    setState(() {
      _pendingSocial = p;
      _showSocialDialog = true;
    });
  }

  Widget _socialDialog(BuildContext context, AppStateProvider app) {
    return GestureDetector(
      onTap: () => setState(() => _showSocialDialog = false),
      child: ColoredBox(
        color: Colors.black38,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lien ket tai khoan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tai khoan ${_pendingSocial == AuthProviderType.google ? 'Google' : 'Facebook'} se duoc lien ket.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: HpPrimaryButton(
                          label: 'Dong y',
                          onPressed: () async {
                            setState(() => _showSocialDialog = false);
                            final email = _pendingSocial == AuthProviderType.google ? 'user@gmail.com' : 'user@facebook.com';
                            await app.completeAuth(
                              email: email,
                              name: '${_pendingSocial == AuthProviderType.google ? 'Google' : 'Facebook'} User',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => _showSocialDialog = false), child: const Text('Huy'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
