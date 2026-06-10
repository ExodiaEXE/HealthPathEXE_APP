import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:health/features/audio/services/audio_playback_quality.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlaybackService {
  AudioPlaybackService({AudioPlaybackQuality quality = AudioPlaybackQuality.normal})
      : _quality = quality,
        _player = _createPlayer(quality) {
    _bindPlayerStreams();
  }

  AudioPlaybackQuality _quality;
  AudioPlayer _player;
  String? _loadedUrl;
  bool _sessionReady = false;

  StreamSubscription<Duration>? _playerPosSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _playerDurSub;

  final _positionRelay = StreamController<Duration>.broadcast();
  final _stateRelay = StreamController<PlayerState>.broadcast();
  final _durationRelay = StreamController<Duration?>.broadcast();

  AudioPlaybackQuality get quality => _quality;

  Stream<Duration> get positionStream => _positionRelay.stream;
  Stream<Duration?> get durationStream => _durationRelay.stream;
  Stream<PlayerState> get playerStateStream => _stateRelay.stream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  Duration get bufferedPosition => _player.bufferedPosition;
  ProcessingState get processingState => _player.processingState;

  Future<void> play() => _player.play();

  static AudioPlayer _createPlayer(AudioPlaybackQuality quality) {
    return AudioPlayer(
      audioLoadConfiguration: AudioLoadConfiguration(
        androidLoadControl: _androidLoadControl(quality),
        darwinLoadControl: _darwinLoadControl(quality),
      ),
    );
  }

  void _bindPlayerStreams() {
    _playerPosSub?.cancel();
    _playerStateSub?.cancel();
    _playerDurSub?.cancel();

    _playerPosSub = _player.positionStream.listen(_positionRelay.add);
    _playerStateSub = _player.playerStateStream.listen(_stateRelay.add);
    _playerDurSub = _player.durationStream.listen(_durationRelay.add);

    if (!_positionRelay.isClosed) {
      _positionRelay.add(_player.position);
    }
    if (!_stateRelay.isClosed) {
      _stateRelay.add(_player.playerState);
    }
    if (!_durationRelay.isClosed) {
      _durationRelay.add(_player.duration);
    }
  }

  static AndroidLoadControl _androidLoadControl(AudioPlaybackQuality quality) {
    return switch (quality) {
      AudioPlaybackQuality.normal => const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 15),
          maxBufferDuration: Duration(minutes: 1),
          bufferForPlaybackDuration: Duration(seconds: 2),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 4),
          prioritizeTimeOverSizeThresholds: true,
        ),
      AudioPlaybackQuality.high => const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 30),
          maxBufferDuration: Duration(minutes: 3),
          bufferForPlaybackDuration: Duration(seconds: 6),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 8),
          prioritizeTimeOverSizeThresholds: true,
        ),
      AudioPlaybackQuality.lossless => const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 45),
          maxBufferDuration: Duration(minutes: 5),
          bufferForPlaybackDuration: Duration(seconds: 10),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 12),
          prioritizeTimeOverSizeThresholds: true,
          backBufferDuration: Duration(seconds: 20),
        ),
    };
  }

  static DarwinLoadControl _darwinLoadControl(AudioPlaybackQuality quality) {
    return switch (quality) {
      AudioPlaybackQuality.normal => const DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: Duration(seconds: 6),
        ),
      AudioPlaybackQuality.high => const DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: Duration(seconds: 20),
        ),
      AudioPlaybackQuality.lossless => const DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: Duration(seconds: 45),
          canUseNetworkResourcesForLiveStreamingWhilePaused: true,
        ),
    };
  }

  Duration get _minBufferedBeforePlay => switch (_quality) {
        AudioPlaybackQuality.normal => const Duration(seconds: 2),
        AudioPlaybackQuality.high => const Duration(seconds: 6),
        AudioPlaybackQuality.lossless => const Duration(seconds: 10),
      };

  Duration get _minBufferedFallback => switch (_quality) {
        AudioPlaybackQuality.normal => Duration.zero,
        AudioPlaybackQuality.high => const Duration(seconds: 3),
        AudioPlaybackQuality.lossless => const Duration(seconds: 5),
      };

  Duration get loadTimeout => switch (_quality) {
        AudioPlaybackQuality.normal => const Duration(seconds: 25),
        AudioPlaybackQuality.high => const Duration(seconds: 45),
        AudioPlaybackQuality.lossless => const Duration(seconds: 60),
      };

  AudioSource _sourceForUrl(String url) {
    final uri = Uri.parse(url);
    if (_quality == AudioPlaybackQuality.normal) {
      return AudioSource.uri(uri);
    }
    // Cache file local trước khi phát — giảm rè / giật trên Ổn định & Cao.
    // ignore: experimental_member_use — just_audio chưa có API cache ổn định thay thế.
    return LockCachingAudioSource(uri);
  }

  Future<void> setQuality(AudioPlaybackQuality quality) async {
    if (_quality == quality) return;

    final url = _loadedUrl;
    final pos = _player.position;
    final wasPlaying = _player.playing;

    if (_player.playing) {
      await _player.pause();
    }

    await _player.dispose();
    _quality = quality;
    _player = _createPlayer(quality);
    _bindPlayerStreams();
    _loadedUrl = null;

    if (url != null) {
      await loadAndPlay(url, resumePosition: pos, autoPlay: wasPlaying);
    }
  }

  Future<void> _ensureSession() async {
    if (_sessionReady) return;
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ),
    );
    _sessionReady = true;
  }

  Future<void> loadAndPlay(
    String url, {
    Duration resumePosition = Duration.zero,
    bool autoPlay = true,
  }) async {
    await _ensureSession();

    final reload = _loadedUrl != url;
    if (reload) {
      await _player.stop();
      await _player.setAudioSource(
        _sourceForUrl(url),
        initialPosition: resumePosition,
        preload: true,
      );
      _loadedUrl = url;
    } else if (resumePosition > Duration.zero) {
      await _player.seek(resumePosition);
    }

    await _waitUntilReady();
    await _waitUntilBufferedAhead(_minBufferedBeforePlay);

    if (autoPlay) {
      await _player.play();
    }
  }

  Future<void> _waitUntilReady() async {
    if (_player.processingState == ProcessingState.ready) return;
    await _player.processingStateStream
        .firstWhere(
          (state) =>
              state == ProcessingState.ready ||
              state == ProcessingState.completed,
        )
        .timeout(loadTimeout);
  }

  Duration _bufferedAhead() {
    final ahead = _player.bufferedPosition - _player.position;
    return ahead.isNegative ? Duration.zero : ahead;
  }

  Future<void> _waitUntilBufferedAhead(Duration minimumAhead) async {
    if (minimumAhead <= Duration.zero) return;
    if (_bufferedAhead() >= minimumAhead) return;

    final completer = Completer<void>();
    late final StreamSubscription<Duration> posSub;
    late final StreamSubscription<Duration> bufSub;
    late final Timer timeoutTimer;

    void check() {
      if (completer.isCompleted) return;
      if (_bufferedAhead() >= minimumAhead) {
        completer.complete();
      }
    }

    posSub = _player.positionStream.listen((_) => check());
    bufSub = _player.bufferedPositionStream.listen((_) => check());
    timeoutTimer = Timer(loadTimeout, () {
      if (completer.isCompleted) return;

      final fallback = _minBufferedFallback;
      if (fallback <= Duration.zero || _bufferedAhead() >= fallback) {
        completer.complete();
        return;
      }

      completer.completeError(
        TimeoutException('Chưa buffer đủ trước khi phát'),
      );
    });

    try {
      await completer.future;
    } finally {
      await posSub.cancel();
      await bufSub.cancel();
      timeoutTimer.cancel();
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0));

  Future<void> setSpeed(double speed) =>
      _player.setSpeed(speed.clamp(0.5, 2.0));

  Future<void> stop() async {
    await _player.stop();
    _loadedUrl = null;
  }

  Future<void> dispose() async {
    await _playerPosSub?.cancel();
    await _playerStateSub?.cancel();
    await _playerDurSub?.cancel();
    await _positionRelay.close();
    await _stateRelay.close();
    await _durationRelay.close();
    await _player.dispose();
    _loadedUrl = null;
  }
}
