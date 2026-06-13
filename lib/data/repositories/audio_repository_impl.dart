import 'package:health/core/config/env_config.dart';
import 'package:health/core/network/api_client.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl({ApiClient? api, TokenStore? storage})
      : _api = api,
        _storage = storage ?? SecureStorageService();

  final ApiClient? _api;
  final TokenStore _storage;

  @override
  bool get isOnline =>
      _api?.hasBaseUrl ?? EnvConfig.apiBaseUrl.isNotEmpty;

  Future<ApiClient?> _authedClient() async {
    if (!isOnline) return null;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty || token.startsWith('mock_')) {
      return null;
    }
    return _api!.withBearer(token);
  }

  @override
  Future<AudioOperationResult> fetchTracks({
    String? category,
    String? search,
    int pageSize = 50,
  }) async {
    final client = await _authedClient();
    if (client == null) {
      return AudioOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final all = <AudioTrackRecord>[];
      var page = 1;

      while (true) {
        final query = <String, String>{
          'page': '$page',
          'pageSize': '$pageSize',
          'sortBy': 'newest',
        };
        if (category != null && category.isNotEmpty && category != 'all') {
          query['category'] = category;
        }
        if (search != null && search.trim().isNotEmpty) {
          query['search'] = search.trim();
        }

        final qs = query.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&');
        final res = await client.getJson('/api/AudioTrack?$qs');

        if (res.json['success'] != true) {
          return AudioOperationResult.fail(
            res.json['message'] as String? ??
                'Không tải được danh sách nhạc.',
          );
        }

        final data = res.json['data'] as Map<String, dynamic>? ?? {};
        final items = data['items'] as List<dynamic>? ?? [];
        all.addAll(
          items.map(
            (e) => AudioTrackRecord.fromJson(e as Map<String, dynamic>),
          ),
        );

        if (data['hasNext'] != true) break;
        page++;
      }

      return AudioOperationResult(success: true, tracks: all);
    } on ApiException catch (e) {
      return AudioOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<AudioOperationResult> fetchCategories() async {
    final client = await _authedClient();
    if (client == null) {
      return AudioOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final res = await client.getJson('/api/AudioTrack/categories');
      if (res.json['success'] != true) {
        return AudioOperationResult.fail(
          res.json['message'] as String? ?? 'Không tải được danh mục nhạc.',
        );
      }

      final list = res.json['data'] as List<dynamic>? ?? [];
      final categories = list
          .map((e) => AudioCategoryRecord.fromJson(e as Map<String, dynamic>))
          .where((c) => c.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return AudioOperationResult(success: true, categories: categories);
    } on ApiException catch (e) {
      return AudioOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<AudioOperationResult> getStreamUrl(String trackId) async {
    final client = await _authedClient();
    if (client == null) {
      return AudioOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final id = trackId.toLowerCase();
      final res = await client.getJson('/api/AudioTrack/$id/stream-url');
      if (res.json['success'] != true) {
        return AudioOperationResult.fail(
          res.json['message'] as String? ?? 'Không lấy được link phát nhạc.',
        );
      }

      final data = res.json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return AudioOperationResult.fail('Phản hồi stream không hợp lệ.');
      }

      return AudioOperationResult(
        success: true,
        stream: AudioStreamResult.fromJson(data),
      );
    } on ApiException catch (e) {
      return AudioOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<AudioOperationResult> recordPlay({
    required String trackId,
    required int playedSeconds,
  }) async {
    final client = await _authedClient();
    if (client == null) {
      return AudioOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final res = await client.postJson('/api/AudioTrack/play', {
        'trackId': trackId,
        'playedSeconds': playedSeconds.clamp(1, 36000),
      });
      if (res.json['success'] != true) {
        return AudioOperationResult.fail(
          res.json['message'] as String? ?? 'Không ghi nhận lịch sử nghe.',
        );
      }
      return const AudioOperationResult(success: true);
    } on ApiException catch (e) {
      return AudioOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<AudioOperationResult> fetchFavorites({int pageSize = 50}) async {
    final client = await _authedClient();
    if (client == null) {
      return AudioOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final all = <AudioTrackRecord>[];
      var page = 1;

      while (true) {
        final res = await client.getJson(
          '/api/AudioTrack/favorites?page=$page&pageSize=$pageSize',
        );

        if (res.json['success'] != true) {
          return AudioOperationResult.fail(
            res.json['message'] as String? ??
                'Không tải được bài yêu thích.',
          );
        }

        final data = res.json['data'] as Map<String, dynamic>? ?? {};
        final items = data['items'] as List<dynamic>? ?? [];
        all.addAll(
          items.map(
            (e) => AudioTrackRecord.fromJson(e as Map<String, dynamic>),
          ),
        );

        if (data['hasNext'] != true) break;
        page++;
      }

      return AudioOperationResult(success: true, tracks: all);
    } on ApiException catch (e) {
      return AudioOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<AudioOperationResult> addFavorite(String trackId) async {
    final client = await _authedClient();
    if (client == null) {
      return AudioOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final id = trackId.toLowerCase();
      final res = await client.postJson('/api/AudioTrack/$id/favorite', {});
      if (res.json['success'] != true) {
        return AudioOperationResult.fail(
          res.json['message'] as String? ?? 'Không thêm yêu thích.',
        );
      }
      return const AudioOperationResult(success: true, isFavorited: true);
    } on ApiException catch (e) {
      return AudioOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<AudioOperationResult> removeFavorite(String trackId) async {
    final client = await _authedClient();
    if (client == null) {
      return AudioOperationResult.fail('Phiên đăng nhập không hợp lệ.');
    }

    try {
      final id = trackId.toLowerCase();
      final res = await client.deleteJson('/api/AudioTrack/$id/favorite');
      if (res.json['success'] != true) {
        return AudioOperationResult.fail(
          res.json['message'] as String? ?? 'Không bỏ yêu thích.',
        );
      }
      return const AudioOperationResult(success: true, isFavorited: false);
    } on ApiException catch (e) {
      return AudioOperationResult.fail(e.message);
    } finally {
      client.close();
    }
  }
}
