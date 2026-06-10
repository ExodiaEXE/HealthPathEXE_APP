import 'package:flutter/foundation.dart';
import 'package:health/domain/entities/audio_entities.dart';

/// Cầu nối giữa UI (AudioScreen) và media session / PiP / notification.
abstract final class AudioPlaybackDelegate {
  static List<AudioTrackRecord> Function()? tracks;
  static String? Function()? currentTrackId;
  static Future<void> Function(AudioTrackRecord track)? playTrack;
  static void Function()? stopPlayback;
  static void Function(String? trackId, {required bool playing})? syncUi;
  static void Function()? openDetailView;

  static final ValueNotifier<String?> trackIdNotifier = ValueNotifier(null);

  static void notifyTrack(String? trackId, {bool? playing}) {
    trackIdNotifier.value = trackId;
    syncUi?.call(trackId, playing: playing ?? false);
  }

  static void requestOpenDetail() => openDetailView?.call();

  static void clear() {
    tracks = null;
    currentTrackId = null;
    playTrack = null;
    stopPlayback = null;
    syncUi = null;
    openDetailView = null;
  }
}
