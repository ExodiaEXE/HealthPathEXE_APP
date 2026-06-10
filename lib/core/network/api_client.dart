import 'dart:convert';

import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client_io.dart'
    if (dart.library.html) 'package:health/core/network/api_client_stub.dart';
import 'package:http/http.dart' as http;

/// Kết quả thô từ API: status code + JSON body đã giải mã.
class ApiResult {
  const ApiResult({required this.statusCode, required this.json});

  final int statusCode;
  final Map<String, dynamic> json;

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Lỗi tầng mạng (không kết nối được / timeout / body không phải JSON).
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// HTTP client mỏng tới backend HealthPath (.NET). Base URL lấy từ
/// [EnvConfig.apiBaseUrl] (truyền qua --dart-define). Có thể tiêm
/// [http.Client] để unit test.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl, String? bearerToken})
      : _http = httpClient ?? createDefaultHttpClient(),
        _ownsClient = httpClient == null,
        _baseUrl = (baseUrl ?? EnvConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _bearerToken = bearerToken;

  final http.Client _http;
  final bool _ownsClient;
  final String _baseUrl;
  final String? _bearerToken;

  Duration timeout = const Duration(seconds: 20);

  /// `true` khi đã cấu hình base URL (tức app chạy ở chế độ gọi backend thật).
  bool get hasBaseUrl => _baseUrl.isNotEmpty;

  /// Client mới dùng chung HTTP pool nhưng gắn JWT — dùng cho API cần đăng nhập.
  ApiClient withBearer(String bearerToken) => ApiClient(
        httpClient: _http,
        baseUrl: _baseUrl,
        bearerToken: bearerToken,
      );

  Uri _uri(String path) =>
      Uri.parse('$_baseUrl/${path.replaceAll(RegExp(r'^/+'), '')}');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (_bearerToken != null && _bearerToken.isNotEmpty)
          'Authorization': 'Bearer $_bearerToken',
      };

  Future<ApiResult> postJson(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _http
          .post(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);
      return ApiResult(statusCode: resp.statusCode, json: _decode(resp.body));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Không kết nối được máy chủ. Vui lòng thử lại sau.');
    }
  }

  Future<ApiResult> getJson(String path) async {
    try {
      final resp =
          await _http.get(_uri(path), headers: _headers()).timeout(timeout);
      return ApiResult(statusCode: resp.statusCode, json: _decode(resp.body));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Không kết nối được máy chủ. Vui lòng thử lại sau.');
    }
  }

  Future<ApiResult> putJson(String path, Map<String, dynamic> body) async {
    try {
      final resp = await _http
          .put(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);
      return ApiResult(statusCode: resp.statusCode, json: _decode(resp.body));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Không kết nối được máy chủ. Vui lòng thử lại sau.');
    }
  }

  Future<ApiResult> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path));
      final bearer = _bearerToken;
      if (bearer != null && bearer.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $bearer';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
        ),
      );
      final streamed = await request.send().timeout(timeout);
      final resp = await http.Response.fromStream(streamed);
      return ApiResult(statusCode: resp.statusCode, json: _decode(resp.body));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Không kết nối được máy chủ. Vui lòng thử lại sau.');
    }
  }

  Future<ApiResult> deleteJson(String path) async {
    try {
      final resp =
          await _http.delete(_uri(path), headers: _headers()).timeout(timeout);
      return ApiResult(statusCode: resp.statusCode, json: _decode(resp.body));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Không kết nối được máy chủ. Vui lòng thử lại sau.');
    }
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      throw const ApiException('Phản hồi máy chủ không hợp lệ.');
    }
  }

  void close() {
    if (_ownsClient) _http.close();
  }
}
