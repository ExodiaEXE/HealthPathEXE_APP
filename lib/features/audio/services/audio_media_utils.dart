import 'package:audio_service/audio_service.dart';
import 'package:health/domain/entities/audio_entities.dart';

MediaItem mediaItemFromTrack(AudioTrackRecord track) {
  Uri? artUri;
  final cover = track.coverUrl?.trim();
  if (cover != null && cover.isNotEmpty) {
    artUri = Uri.tryParse(cover);
  }

  return MediaItem(
    id: track.id,
    title: track.title,
    artist: track.displayArtist,
    album: track.category.isNotEmpty ? track.category : 'HealthPath Audio',
    duration: track.durationSeconds > 0
        ? Duration(seconds: track.durationSeconds)
        : null,
    artUri: artUri,
  );
}
