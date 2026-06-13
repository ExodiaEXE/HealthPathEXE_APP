import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:health/features/audio/services/audio_playback_service.dart';
import 'package:just_audio/just_audio.dart';

typedef AudioHandlerCallback = Future<void> Function();

/// Media session + notification — điều khiển từ khóa màn hình / notification.
class HealthAudioHandler extends BaseAudioHandler with SeekHandler {
  HealthAudioHandler(this._playback) {
    _subscriptions.add(
      _playback.playerStateStream.listen((_) {
        _syncPlaybackState();
        if (mediaItem.value != null) {
          _startPositionTick();
        }
      }),
    );
    _subscriptions.add(
      _playback.positionStream.listen((_) => _syncPlaybackState()),
    );
    _subscriptions.add(
      _playback.durationStream.listen((_) {
        _refreshMediaDuration();
        _syncPlaybackState();
      }),
    );
    _syncPlaybackState();
  }

  final AudioPlaybackService _playback;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _positionTick;

  AudioHandlerCallback? onSkipToNext;
  AudioHandlerCallback? onSkipToPrevious;
  AudioHandlerCallback? onStopRequested;

  void publishNowPlaying(MediaItem item) {
    mediaItem.add(item);
    queue.add([item]);
    _refreshMediaDuration();
    _syncPlaybackState();
    _startPositionTick();
  }

  void clearMediaItem() {
    mediaItem.add(null);
    queue.add([]);
    _stopPositionTick();
    _syncPlaybackState();
  }

  void _refreshMediaDuration() {
    final item = mediaItem.value;
    final dur = _playback.duration;
    if (item == null || dur == null || dur <= Duration.zero) return;
    if (item.duration != dur) {
      mediaItem.add(item.copyWith(duration: dur));
    }
  }

  void _startPositionTick() {
    if (_positionTick != null) return;
    _positionTick = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshMediaDuration();
      _syncPlaybackState();
    });
  }

  void _stopPositionTick() {
    _positionTick?.cancel();
    _positionTick = null;
  }

  @override
  Future<void> play() async {
    await _playback.play();
    _syncPlaybackState();
  }

  @override
  Future<void> pause() async {
    await _playback.pause();
    _syncPlaybackState();
  }

  @override
  Future<void> stop() async {
    await onStopRequested?.call();
    await super.stop();
    _syncPlaybackState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _playback.seek(position);
    _syncPlaybackState();
  }

  @override
  Future<void> skipToNext() async {
    await onSkipToNext?.call();
    _syncPlaybackState();
  }

  @override
  Future<void> skipToPrevious() async {
    await onSkipToPrevious?.call();
    _syncPlaybackState();
  }

  void _syncPlaybackState() {
    final playing = _playback.isPlaying;
    final processing = _playback.processingState;
    final pos = _playback.position;
    final buffered = _playback.bufferedPosition;
    final hasMedia = mediaItem.value != null;
    _refreshMediaDuration();

    final sessionState = hasMedia
        ? switch (processing) {
            ProcessingState.loading => AudioProcessingState.loading,
            ProcessingState.buffering => AudioProcessingState.buffering,
            ProcessingState.completed => AudioProcessingState.completed,
            ProcessingState.idle => AudioProcessingState.ready,
            ProcessingState.ready => AudioProcessingState.ready,
          }
        : AudioProcessingState.idle;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 3],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.stop,
        },
        processingState: sessionState,
        playing: playing,
        updatePosition: pos,
        bufferedPosition: buffered,
        speed: playbackState.value.speed == 0 ? 1.0 : playbackState.value.speed,
      ),
    );
  }

  Future<void> disposeHandler() async {
    _stopPositionTick();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }
}
