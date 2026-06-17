import 'package:audio_service/audio_service.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/features/audio/services/audio_playback_delegate.dart';
import 'package:health/features/audio/services/audio_playback_service.dart';
import 'package:health/features/audio/services/health_audio_handler.dart';

/// Singleton phát nhạc + media session — dùng chung UI, notification, PiP.
abstract final class AudioPlaybackCoordinator {
  static AudioPlaybackService? _playback;
  static HealthAudioHandler? _handler;
  static bool _initialized = false;

  static AudioPlaybackService get playback {
    _playback ??= AudioPlaybackService();
    return _playback!;
  }

  static HealthAudioHandler? get handler => _handler;

  static bool get isMediaSessionReady => _handler != null;

  static bool get hasActiveSession =>
      _handler?.mediaItem.value != null;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    _playback ??= AudioPlaybackService();
    _handler = await AudioService.init(
      builder: () => HealthAudioHandler(_playback!),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'vn.healthpath.audio.playback',
        androidNotificationChannelName: 'Phát nhạc',
        androidNotificationChannelDescription:
            'Điều khiển nhạc HealthPath từ notification và màn hình khóa',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        notificationColor: AppColors.primary,
        fastForwardInterval: const Duration(seconds: 10),
        rewindInterval: const Duration(seconds: 10),
      ),
    );
    _wireHandlerCallbacks();
    _initialized = true;
  }

  static void _wireHandlerCallbacks() {
    final h = _handler;
    if (h == null) return;
    h.onSkipToNext = handleSkipToNext;
    h.onSkipToPrevious = handleSkipToPrevious;
    h.onStopRequested = handleStop;
  }

  static List<AudioTrackRecord> _trackList() =>
      List<AudioTrackRecord>.from(AudioPlaybackDelegate.tracks?.call() ?? []);

  static String? _currentId() => AudioPlaybackDelegate.currentTrackId?.call();

  static Future<void> handleSkipToNext() async {
    final tracks = _trackList();
    if (tracks.isEmpty) return;
    final current = _currentId();
    var idx = tracks.indexWhere((t) => t.id.toLowerCase() == current?.toLowerCase());
    if (idx < 0) idx = 0;
    final next = tracks[(idx + 1) % tracks.length];
    await _play(next);
  }

  static Future<void> handleSkipToPrevious() async {
    final tracks = _trackList();
    if (tracks.isEmpty) return;
    final current = _currentId();
    var idx = tracks.indexWhere((t) => t.id.toLowerCase() == current?.toLowerCase());
    if (idx < 0) idx = 0;
    final prev = tracks[(idx - 1 + tracks.length) % tracks.length];
    await _play(prev);
  }

  static Future<void> handleStop() async {
    await playback.stop();
    _handler?.clearMediaItem();
    AudioPlaybackDelegate.notifyTrack(null, playing: false);
    AudioPlaybackDelegate.stopPlayback?.call();
  }

  static Future<void> _play(AudioTrackRecord track) async {
    final play = AudioPlaybackDelegate.playTrack;
    if (play == null) return;
    await play(track);
  }

  static Future<void> togglePlayPause() async {
    final h = _handler;
    if (h == null) return;
    if (playback.isPlaying) {
      await h.pause();
    } else {
      await h.play();
    }
  }

  static void updateNowPlaying(MediaItem item) {
    final dur = playback.duration;
    final enriched = dur != null && dur > Duration.zero
        ? item.copyWith(duration: dur)
        : item;
    _handler?.publishNowPlaying(enriched);
    AudioPlaybackDelegate.notifyTrack(enriched.id, playing: playback.isPlaying);
  }

  static void clearNowPlaying() {
    _handler?.clearMediaItem();
    AudioPlaybackDelegate.trackIdNotifier.value = null;
  }
}
