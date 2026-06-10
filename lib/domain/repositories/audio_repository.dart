import 'package:health/domain/entities/audio_entities.dart';

abstract class AudioRepository {
  bool get isOnline;

  Future<AudioOperationResult> fetchTracks({
    String? category,
    String? search,
    int pageSize = 50,
  });

  Future<AudioOperationResult> fetchCategories();

  Future<AudioOperationResult> getStreamUrl(String trackId);

  Future<AudioOperationResult> recordPlay({
    required String trackId,
    required int playedSeconds,
  });

  Future<AudioOperationResult> addFavorite(String trackId);

  Future<AudioOperationResult> removeFavorite(String trackId);

  Future<AudioOperationResult> fetchFavorites({int pageSize = 50});
}
