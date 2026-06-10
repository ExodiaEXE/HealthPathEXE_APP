import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/utils/user_facing_message.dart';
import 'package:health/core/theme/app_typography.dart';
import 'package:health/domain/repositories/auth_repository.dart';
import 'package:health/domain/usecases/auth/forgot_password_usecase.dart';
import 'package:health/domain/usecases/auth/login_usecase.dart';
import 'package:health/domain/usecases/auth/register_usecase.dart';
import 'package:health/domain/usecases/auth/resend_verification_otp_usecase.dart';
import 'package:health/domain/usecases/auth/reset_password_usecase.dart';
import 'package:health/domain/usecases/auth/social_login_usecase.dart';
import 'package:health/domain/usecases/auth/verify_register_otp_usecase.dart';
import 'package:health/features/auth/data/social_auth_service.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_animated_auth_background.dart';
import 'package:health/shared/widgets/hp_button.dart';
import 'package:health/shared/widgets/hp_glass_card.dart';
import 'package:health/shared/widgets/hp_page_transition.dart';
import 'package:health/shared/widgets/google_brand_icon.dart';
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
  Timer? _resendTimer;
  bool _showSocialDialog = false;
  AuthProviderType? _pendingSocial;
  String? _error;
  String? _successMessage;
  bool _verifyFromLogin = false;

  SocialAuthService get _social => context.read<SocialAuthService>();

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _name.dispose();
    _forgotEmail.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _regResendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _regResendCooldown--;
        if (_regResendCooldown <= 0) timer.cancel();
      });
    });
  }

  bool _isPasswordValid(String pw) {
    return pw.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(pw) &&
        RegExp(r'[a-z]').hasMatch(pw) &&
        RegExp(r'\d').hasMatch(pw) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pw);
  }

  void _clearMessages() => setState(() {
        _error = null;
        _successMessage = null;
      });

  /// Bọc một thao tác auth: bật loading, bắt lỗi mạng, hiển thị thông báo.
  Future<void> _runAuth(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = UserFacingMessage.sanitize(
              e.message,
              fallback: 'Có lỗi xảy ra, thử lại sau.',
            ));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Có lỗi xảy ra, thử lại sau.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLogin(AppStateProvider app) async {
    final auth = context.read<AuthRepository>();
    final login = context.read<LoginUseCase>();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() => _successMessage = null);
    await _runAuth(() async {
      final res = auth.isOnline
          ? await login(email: email, password: password)
          : await login(
              email: email.isEmpty ? 'user@healthpath.vn' : email,
              password: password,
            );
      if (!mounted) return;
      if (res.success) {
        await app.completeAuth(
          email: res.userEmail ?? email,
          name: res.userName,
          token: res.token,
          isPremium: res.isPremium,
          provider: AuthProviderType.email,
        );
      } else if (res.errorCode == 'EMAIL_NOT_VERIFIED') {
        await _startEmailVerification(fromLogin: true);
      } else {
        setState(() => _error = res.message ?? 'Đăng nhập thất bại.');
      }
    });
  }

  Future<void> _startEmailVerification({required bool fromLogin}) async {
    final resend = context.read<ResendVerificationOtpUseCase>();
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập email.');
      return;
    }
    await _runAuth(() async {
      final res = await resend(email: email);
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _verifyFromLogin = fromLogin;
          _view = _AuthView.registerOtp;
          _regOtp = '';
          _error = null;
          _successMessage =
              res.message ?? 'Đã gửi mã xác thực tới email của bạn.';
        });
        _startResendCooldown();
      } else {
        setState(() => _error = res.message ?? 'Không gửi được mã xác thực.');
      }
    });
  }

  Future<void> _handleResendVerificationOtp() async {
    if (_regResendCooldown > 0) return;
    await _startEmailVerification(fromLogin: _verifyFromLogin);
  }

  Future<void> _handleRegisterContinue() async {
    final register = context.read<RegisterUseCase>();
    await _runAuth(() async {
      final res = await register(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (res.success) {
        setState(() => _view = _AuthView.registerOtp);
        _startResendCooldown();
      } else {
        setState(() => _error = res.message ?? 'Đăng ký thất bại.');
      }
    });
  }

  Future<void> _handleRegisterConfirm(AppStateProvider app) async {
    final verify = context.read<VerifyRegisterOtpUseCase>();
    final fromLogin = _verifyFromLogin;
    await _runAuth(() async {
      final res = await verify(
        email: _email.text.trim(),
        otpCode: _regOtp,
      );
      if (!mounted) return;
      if (res.success) {
        if (fromLogin) {
          setState(() {
            _verifyFromLogin = false;
            _regOtp = '';
            _error = null;
            _successMessage = res.message ?? 'Xác thực thành công! Đang đăng nhập...';
          });
          final login = context.read<LoginUseCase>();
          final loginRes = await login(
            email: _email.text.trim(),
            password: _password.text,
          );
          if (!mounted) return;
          if (loginRes.success) {
            await app.completeAuth(
              email: loginRes.userEmail ?? _email.text.trim(),
              name: loginRes.userName,
              token: loginRes.token,
              isPremium: loginRes.isPremium,
              provider: AuthProviderType.email,
            );
          } else {
            setState(() {
              _view = _AuthView.login;
              _error = loginRes.message ?? 'Xác thực xong nhưng đăng nhập thất bại.';
            });
          }
        } else {
          setState(() {
            _view = _AuthView.login;
            _regOtp = '';
            _successMessage =
                res.message ?? 'Đăng ký thành công! Vui lòng đăng nhập.';
            _error = null;
          });
          app.setAuthState(AuthState.login);
        }
      } else {
        setState(() => _error = res.message ?? 'Mã OTP không chính xác.');
      }
    });
  }

  Future<void> _handleForgotSendOtp() async {
    final forgot = context.read<ForgotPasswordUseCase>();
    final email = _forgotEmail.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập email.');
      return;
    }
    await _runAuth(() async {
      final res = await forgot(email: email);
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _view = _AuthView.forgotOtp;
          _error = null;
        });
      } else {
        setState(() => _error = res.message ?? 'Không gửi được mã xác thực.');
      }
    });
  }

  Future<void> _handleForgotReset() async {
    final reset = context.read<ResetPasswordUseCase>();
    await _runAuth(() async {
      final res = await reset(
        email: _forgotEmail.text.trim(),
        otpCode: _forgotOtp,
        newPassword: _newPw.text,
      );
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _view = _AuthView.forgotDone;
          _successMessage =
              res.message ?? 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập.';
          _error = null;
        });
      } else {
        setState(() => _error = res.message ?? 'Đặt lại mật khẩu thất bại.');
      }
    });
  }

  void _goToLogin({String? successMessage}) {
    setState(() {
      _view = _AuthView.login;
      _forgotOtp = '';
      _newPw.clear();
      _confirmPw.clear();
      _error = null;
      if (successMessage != null) _successMessage = successMessage;
    });
  }

  Future<void> _handleSocial(AppStateProvider app, AuthProviderType provider) async {
    final socialLogin = context.read<SocialLoginUseCase>();
    await _runAuth(() async {
      final cred = await _social.signIn(provider);
      if (cred == null) {
        if (mounted) setState(() => _error = 'Không lấy được tài khoản.');
        return;
      }
      final res = await socialLogin(
        provider: cred.provider,
        providerToken: cred.token,
      );
      if (!mounted) return;
      if (res.success) {
        await app.completeAuth(
          email: res.userEmail ?? '${cred.provider}@healthpath.vn',
          name: res.userName,
          token: res.token,
          isPremium: res.isPremium,
          provider: provider,
        );
      } else {
        setState(() => _error = res.message ?? 'Liên kết thất bại.');
      }
    });
  }

  Widget _errorBanner() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE57373).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: Color(0xFFD45A5A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                UserFacingMessage.sanitize(
                  _error,
                  fallback: 'Có lỗi xảy ra, thử lại sau.',
                ),
                style: const TextStyle(fontSize: 11, color: Color(0xFFD45A5A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _successBanner() {
    if (_successMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _successMessage!,
                style: const TextStyle(fontSize: 11, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      body: Stack(
        children: [
          const HpAnimatedAuthBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final lift = constraints.maxHeight * 0.06;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -lift),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                                builder: (context, v, child) =>
                                    Transform.translate(
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
                                          BoxShadow(
                                              color: AppColors.cardShadow,
                                              blurRadius: 16),
                                        ],
                                      ),
                                      child: const Icon(Icons.favorite,
                                          color: AppColors.primary, size: 32),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('HealthPath',
                                        style: AppTypography.display),
                                    const Text(
                                        'Hành trình sức khỏe của riêng bạn',
                                        style: AppTypography.bodySm),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildCard(context, app),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
        const SizedBox(height: 12),
        _successBanner(),
        _errorBanner(),
        Row(
          children: [
            Expanded(
              child: HpTapScale(
                onTap: () => _openSocial(AuthProviderType.google),
                child: _socialButton(
                  'Đăng nhập Google',
                  const GoogleBrandIcon(size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HpTapScale(
                onTap: () => _openSocial(AuthProviderType.facebook),
                child: _socialButton('Đăng nhập Facebook', const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 18)),
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
              _clearMessages();
              setState(() => _view = _AuthView.forgotEmail);
            },
            child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ),
        HpPrimaryButton(
          label: 'Đăng nhập',
          loading: _loading,
          onPressed: () => _handleLogin(app),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              app.setAuthState(AuthState.register);
              _clearMessages();
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
        _errorBanner(),
        HpTextField(controller: _name, hint: 'Tên tài khoản', prefixIcon: Icons.person_outline),
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
          onPressed: valid ? () => _handleRegisterContinue() : null,
        ),
        TextButton(
          onPressed: () {
            app.setAuthState(AuthState.login);
            _clearMessages();
            setState(() => _view = _AuthView.login);
          },
          child: const Text('Đã có tài khoản? Đăng nhập'),
        ),
      ],
    );
  }

  Widget _registerOtpForm(AppStateProvider app) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              _clearMessages();
              final backToLogin = _verifyFromLogin;
              setState(() {
                _verifyFromLogin = false;
                _view = backToLogin ? _AuthView.login : _AuthView.register;
              });
            },
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
        ),
        const Icon(Icons.verified_user, size: 48, color: AppColors.accent),
        const Text('Xác thực email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          _verifyFromLogin
              ? 'Tài khoản chưa xác thực. Nhập mã 6 số đã gửi tới ${_email.text.trim()}'
              : 'Nhập mã 6 số đã gửi tới ${_email.text.trim()}',
          textAlign: TextAlign.center,
          style: AppTypography.micro.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        _successBanner(),
        _errorBanner(),
        OtpInput(onChanged: (v) => setState(() => _regOtp = v)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _regResendCooldown > 0 ? null : _handleResendVerificationOtp,
          child: Text(
            _regResendCooldown > 0 ? 'Gửi lại sau ${_regResendCooldown}s' : 'Gửi lại mã',
            style: TextStyle(fontSize: 12, color: _regResendCooldown > 0 ? AppColors.muted : AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        HpPrimaryButton(
          label: _verifyFromLogin ? 'Xác nhận & đăng nhập' : 'Xác nhận & hoàn tất đăng ký',
          loading: _loading,
          onPressed:
              _regOtp.length == 6 ? () => _handleRegisterConfirm(app) : null,
        ),
      ],
    );
  }

  Widget _forgotEmailForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconButton(
            onPressed: () => _goToLogin(),
            icon: const Icon(Icons.arrow_back),
          ),
          const Text('Quên mật khẩu', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _errorBanner(),
          HpTextField(controller: _forgotEmail, hint: 'Email đăng ký', prefixIcon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          HpPrimaryButton(
            label: 'Gửi mã xác thực',
            loading: _loading,
            onPressed: _handleForgotSendOtp,
          ),
        ],
      );

  Widget _forgotOtpForm() => Column(
        children: [
          IconButton(
            onPressed: () {
              _clearMessages();
              setState(() => _view = _AuthView.forgotEmail);
            },
            icon: const Icon(Icons.arrow_back),
          ),
          const Text('Nhập mã OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Mã đã gửi tới ${_forgotEmail.text.trim()}',
            style: AppTypography.micro.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          _errorBanner(),
          OtpInput(onChanged: (v) => setState(() => _forgotOtp = v)),
          const SizedBox(height: 12),
          HpPrimaryButton(
            label: 'Tiếp tục',
            loading: _loading,
            onPressed: _forgotOtp.length == 6
                ? () {
                    _clearMessages();
                    setState(() => _view = _AuthView.forgotNewPw);
                  }
                : null,
          ),
        ],
      );

  Widget _forgotNewPwForm() {
    final ok = _isPasswordValid(_newPw.text) && _newPw.text == _confirmPw.text;
    return Column(
      children: [
        IconButton(
          onPressed: () {
            _clearMessages();
            setState(() => _view = _AuthView.forgotOtp);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        const Text('Mật khẩu mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _errorBanner(),
        HpTextField(controller: _newPw, hint: 'Mật khẩu mới', prefixIcon: Icons.lock_outline, obscureText: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 8),
        HpTextField(controller: _confirmPw, hint: 'Xác nhận', prefixIcon: Icons.lock_outline, obscureText: true, onChanged: (_) => setState(() {})),
        if (_newPw.text.isNotEmpty) _passwordRules(_newPw.text),
        const SizedBox(height: 12),
        HpPrimaryButton(
          label: 'Đặt lại mật khẩu',
          loading: _loading,
          onPressed: ok ? _handleForgotReset : null,
        ),
      ],
    );
  }

  Widget _forgotDoneForm() => Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 56),
          const Text('Đặt lại thành công', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            _successMessage ?? 'Bạn có thể đăng nhập bằng mật khẩu mới.',
            textAlign: TextAlign.center,
            style: AppTypography.micro.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          HpPrimaryButton(
            label: 'Quay về đăng nhập',
            onPressed: () => _goToLogin(successMessage: _successMessage),
          ),
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
                  const Text('Liên kết tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tài khoản ${_pendingSocial == AuthProviderType.google ? 'Google' : 'Facebook'} sẽ được liên kết.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: HpPrimaryButton(
                          label: 'Đồng ý',
                          onPressed: () {
                            final provider =
                                _pendingSocial ?? AuthProviderType.google;
                            setState(() => _showSocialDialog = false);
                            _handleSocial(app, provider);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => _showSocialDialog = false), child: const Text('Hủy'))),
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
