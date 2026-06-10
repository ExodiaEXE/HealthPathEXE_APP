import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/data/repositories/auth_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeTokenStore implements TokenStore {
  String? access;
  bool cleared = false;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<void> writeTokens({required String access, String? refresh}) async {
    this.access = access;
  }

  @override
  Future<void> clearTokens() async {
    cleared = true;
    access = null;
  }
}

String _ok({String token = 'jwt.token.value', String name = 'Nguyễn An', String email = 'an@gmail.com'}) =>
    jsonEncode({
      'success': true,
      'message': 'Đăng nhập thành công!',
      'data': {
        'token': token,
        'user': {'id': 'abc', 'name': name, 'email': email, 'isPremium': false},
      },
    });

String _fail(String message) =>
    jsonEncode({'success': false, 'message': message, 'data': null});

http.Response _resp(String body, int status) => http.Response(
      body,
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

AuthRepositoryImpl _repo(MockClient client, _FakeTokenStore store) =>
    AuthRepositoryImpl(
      api: ApiClient(httpClient: client, baseUrl: 'http://test.local'),
      storage: store,
    );

void main() {
  group('AuthRepositoryImpl (online)', () {
    test('login success returns token + user and persists token', () async {
      final store = _FakeTokenStore();
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return _resp(_ok(), 200);
      });

      final res = await _repo(client, store)
          .login(email: 'an@gmail.com', password: 'Secret@123');

      expect(res.success, isTrue);
      expect(res.token, 'jwt.token.value');
      expect(res.userEmail, 'an@gmail.com');
      expect(store.access, 'jwt.token.value');
      expect(captured.url.path, '/api/Auth/login');
      expect(jsonDecode(captured.body)['email'], 'an@gmail.com');
    });

    test('login failure surfaces backend message and stores nothing', () async {
      final store = _FakeTokenStore();
      final client =
          MockClient((req) async => _resp(_fail('Sai email hoặc mật khẩu!'), 401));

      final res = await _repo(client, store)
          .login(email: 'x@gmail.com', password: 'bad');

      expect(res.success, isFalse);
      expect(res.message, 'Sai email hoặc mật khẩu!');
      expect(store.access, isNull);
    });

    test('socialLogin posts provider+token and persists JWT', () async {
      final store = _FakeTokenStore();
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return _resp(_ok(email: 'social@gmail.com'), 200);
      });

      final res = await _repo(client, store).socialLogin(
        provider: 'google',
        providerToken: 'g-1|social@gmail.com|Google User',
      );

      expect(res.success, isTrue);
      expect(res.userEmail, 'social@gmail.com');
      expect(store.access, 'jwt.token.value');
      expect(captured.url.path, '/api/Auth/social-login');
      final body = jsonDecode(captured.body);
      expect(body['provider'], 'google');
      expect(body['token'], 'g-1|social@gmail.com|Google User');
    });

    test('register success returns success', () async {
      final store = _FakeTokenStore();
      final client = MockClient((req) async =>
          _resp(jsonEncode({'success': true, 'message': 'Đăng ký thành công!', 'data': {}}), 200));

      final res = await _repo(client, store).register(
        fullName: 'An',
        email: 'new@gmail.com',
        password: 'Secret@123',
      );

      expect(res.success, isTrue);
    });

    test('verifyRegisterOtp posts email+otpCode', () async {
      final store = _FakeTokenStore();
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return _resp(
          jsonEncode({
            'success': true,
            'message': 'Xác thực và kích hoạt tài khoản thành công!',
            'data': {},
          }),
          200,
        );
      });

      final res = await _repo(client, store).verifyRegisterOtp(
        email: 'new@gmail.com',
        otpCode: '123456',
      );

      expect(res.success, isTrue);
      expect(captured.url.path, '/api/Auth/verify-register-otp');
      final body = jsonDecode(captured.body);
      expect(body['email'], 'new@gmail.com');
      expect(body['otpCode'], '123456');
    });

    test('forgotPassword posts email', () async {
      final store = _FakeTokenStore();
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return _resp(
          jsonEncode({'success': true, 'message': 'Đã gửi mã!', 'data': {}}),
          200,
        );
      });

      final res =
          await _repo(client, store).forgotPassword(email: 'user@gmail.com');

      expect(res.success, isTrue);
      expect(captured.url.path, '/api/Auth/forgot-password');
      expect(jsonDecode(captured.body)['email'], 'user@gmail.com');
    });

    test('resetPasswordWithOtp posts email, otp and new password', () async {
      final store = _FakeTokenStore();
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return _resp(
          jsonEncode({
            'success': true,
            'message': 'Đặt lại mật khẩu thành công!',
            'data': {},
          }),
          200,
        );
      });

      final res = await _repo(client, store).resetPasswordWithOtp(
        email: 'user@gmail.com',
        otpCode: '654321',
        newPassword: 'NewPass@1',
      );

      expect(res.success, isTrue);
      expect(captured.url.path, '/api/Auth/reset-password-with-otp');
      final body = jsonDecode(captured.body);
      expect(body['email'], 'user@gmail.com');
      expect(body['otpCode'], '654321');
      expect(body['newPassword'], 'NewPass@1');
    });

    test('changePassword posts bearer token and passwords', () async {
      final store = _FakeTokenStore()..access = 'jwt.token.value';
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return _resp(
          jsonEncode({
            'success': true,
            'message': 'Đổi mật khẩu thành công!',
            'data': {},
          }),
          200,
        );
      });

      final res = await _repo(client, store).changePassword(
        currentPassword: 'OldPass@1',
        newPassword: 'NewPass@2',
      );

      expect(res.success, isTrue);
      expect(captured.url.path, '/api/Auth/change-password');
      expect(captured.headers['authorization'], 'Bearer jwt.token.value');
      final body = jsonDecode(captured.body);
      expect(body['currentPassword'], 'OldPass@1');
      expect(body['newPassword'], 'NewPass@2');
    });

    test('network error becomes ApiException', () async {
      final store = _FakeTokenStore();
      final client = MockClient((req) async => throw Exception('socket down'));

      expect(
        () => _repo(client, store).login(email: 'a@b.com', password: 'x'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('AuthRepositoryImpl (offline fallback)', () {
    test('login works without network when no base URL configured', () async {
      final store = _FakeTokenStore();
      final client = MockClient((req) async {
        fail('should not hit network in offline mode');
      });
      final repo = AuthRepositoryImpl(
        api: ApiClient(httpClient: client, baseUrl: ''),
        storage: store,
      );

      final res = await repo.login(email: 'demo@x.com', password: 'whatever');

      expect(res.success, isTrue);
      expect(store.access, isNotNull);
    });
  });
}
