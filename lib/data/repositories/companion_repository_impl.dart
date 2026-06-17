import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/domain/repositories/companion_repository.dart';

class CompanionRepositoryImpl implements CompanionRepository {
  CompanionRepositoryImpl({ApiClient? api, TokenStore? storage})
      : _api = api,
        _storage = storage ?? SecureStorageService();

  final ApiClient? _api;
  final TokenStore _storage;

  @override
  bool get isOnline => _api?.hasBaseUrl ?? EnvConfig.apiBaseUrl.isNotEmpty;

  Future<ApiClient?> _client() async {
    if (!isOnline) return null;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return null;
    }
    return _api!.withBearer(token);
  }

  CompanionOperationResult _fail(ApiResult res, String fallback) {
    return CompanionOperationResult.fail(
      res.json['message'] as String? ?? fallback,
    );
  }

  @override
  Future<CompanionOperationResult> fetchState() async {
    final client = await _client();
    if (client == null) {
      return const CompanionOperationResult(
        success: true,
        state: CompanionState.initial,
      );
    }
    try {
      final res = await client.getJson('/api/Companion/state');
      if (res.json['success'] != true) {
        return _fail(res, 'Không tải được bạn đồng hành.');
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      return CompanionOperationResult(
        success: true,
        state: CompanionState.fromJson(data),
      );
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> feed() async {
    final client = await _client();
    if (client == null) {
      return CompanionOperationResult.fail('Cần đăng nhập backend.');
    }
    try {
      final res = await client.postJson('/api/Companion/feed', {});
      if (res.json['success'] != true) {
        return _fail(res, 'Không cho ăn được.');
      }
      return _parseAction(res.json);
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> pet() async {
    final client = await _client();
    if (client == null) {
      return CompanionOperationResult.fail('Cần đăng nhập backend.');
    }
    try {
      final res = await client.postJson('/api/Companion/pet', {});
      if (res.json['success'] != true) {
        return _fail(res, 'Không tương tác được.');
      }
      return _parseAction(res.json);
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> fetchMissions(String category) async {
    final client = await _client();
    if (client == null) {
      return CompanionOperationResult.fail('Cần đăng nhập backend.');
    }
    try {
      final res =
          await client.getJson('/api/Companion/missions?category=$category');
      if (res.json['success'] != true) {
        return _fail(res, 'Không tải được nhiệm vụ.');
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      return CompanionOperationResult(
        success: true,
        missions: CompanionMissionsBundle.fromJson(data),
      );
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> fetchCatalog(String? category) async {
    final client = await _client();
    if (client == null) {
      return CompanionOperationResult.fail('Cần đăng nhập backend.');
    }
    try {
      final q = category != null ? '?category=$category' : '';
      final res = await client.getJson('/api/Companion/catalog$q');
      if (res.json['success'] != true) {
        return _fail(res, 'Không tải được cửa hàng.');
      }
      final items = res.json['data'] as List<dynamic>? ?? [];
      return CompanionOperationResult(
        success: true,
        catalog: items
            .map((e) => CompanionCatalogItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> purchase(String sku) async {
    final client = await _client();
    if (client == null) {
      return CompanionOperationResult.fail('Cần đăng nhập backend.');
    }
    try {
      final res =
          await client.postJson('/api/Companion/purchase', {'sku': sku});
      if (res.json['success'] != true) {
        return _fail(res, 'Không mua được.');
      }
      return CompanionOperationResult(
        success: true,
        message: res.json['message'] as String?,
      );
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> equip(String sku) async {
    final client = await _client();
    if (client == null) {
      return CompanionOperationResult.fail('Cần đăng nhập backend.');
    }
    try {
      final res = await client.postJson('/api/Companion/equip', {'sku': sku});
      if (res.json['success'] != true) {
        return _fail(res, 'Không trang trí được.');
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      return CompanionOperationResult(
        success: true,
        message: res.json['message'] as String?,
        state: CompanionState.fromJson(data),
      );
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> setRoomTheme(String theme) async {
    final client = await _client();
    if (client == null) {
      return CompanionOperationResult.fail('Cần đăng nhập backend.');
    }
    try {
      final res = await client.putJson('/api/Companion/room-theme', {
        'theme': theme,
      });
      if (res.json['success'] != true) {
        return _fail(res, 'Không đổi phòng được.');
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      return CompanionOperationResult(
        success: true,
        state: CompanionState.fromJson(data),
      );
    } on ApiException catch (e) {
      return CompanionOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<CompanionOperationResult> fetchAssets() async {
    final client = await _client();
    if (client == null) {
      return const CompanionOperationResult(
        success: true,
        assets: CompanionAssets.fallback,
      );
    }
    try {
      final res = await client.getJson('/api/Companion/assets');
      if (res.json['success'] != true) {
        return const CompanionOperationResult(
          success: true,
          assets: CompanionAssets.fallback,
        );
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      final assets = CompanionAssets.fromJson(data);
      return CompanionOperationResult(
        success: true,
        assets: assets.mascotGlbUrl.trim().isEmpty ? CompanionAssets.fallback : assets,
      );
    } on ApiException {
      return const CompanionOperationResult(
        success: true,
        assets: CompanionAssets.fallback,
      );
    } finally {
      client.close();
    }
  }

  CompanionOperationResult _parseAction(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return CompanionOperationResult(
      success: true,
      message: data['message'] as String? ?? json['message'] as String?,
      action: CompanionActionResult.fromJson(data),
      state: CompanionState.fromJson(
        data['state'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
