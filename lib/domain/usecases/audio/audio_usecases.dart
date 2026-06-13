import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/domain/repositories/audio_repository.dart';

class FetchAudioTracksUseCase {
  const FetchAudioTracksUseCase(this._repository);
  final AudioRepository _repository;

  bool get isOnline => _repository.isOnline;

  Future<AudioOperationResult> call({String? category, String? search}) =>
      _repository.fetchTracks(category: category, search: search);
}

class FetchAudioCategoriesUseCase {
  const FetchAudioCategoriesUseCase(this._repository);
  final AudioRepository _repository;

  bool get isOnline => _repository.isOnline;

  Future<AudioOperationResult> call() => _repository.fetchCategories();
}

class GetAudioStreamUrlUseCase {
  const GetAudioStreamUrlUseCase(this._repository);
  final AudioRepository _repository;

  Future<AudioOperationResult> call(String trackId) =>
      _repository.getStreamUrl(trackId);
}

class RecordAudioPlayUseCase {
  const RecordAudioPlayUseCase(this._repository);
  final AudioRepository _repository;

  Future<AudioOperationResult> call({
    required String trackId,
    required int playedSeconds,
  }) =>
      _repository.recordPlay(trackId: trackId, playedSeconds: playedSeconds);
}

class FetchAudioFavoritesUseCase {
  const FetchAudioFavoritesUseCase(this._repository);
  final AudioRepository _repository;

  bool get isOnline => _repository.isOnline;

  Future<AudioOperationResult> call({int pageSize = 50}) =>
      _repository.fetchFavorites(pageSize: pageSize);
}

class ToggleAudioFavoriteUseCase {
  const ToggleAudioFavoriteUseCase(this._repository);
  final AudioRepository _repository;

  Future<AudioOperationResult> call({
    required String trackId,
    required bool isFavorited,
  }) =>
      isFavorited
          ? _repository.removeFavorite(trackId)
          : _repository.addFavorite(trackId);
}
