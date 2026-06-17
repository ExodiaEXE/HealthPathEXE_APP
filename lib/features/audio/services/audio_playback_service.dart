import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:health/features/audio/services/audio_playback_quality.dart';
import 'package:just_audio/just_audio.dart';

/// Phát nhạc streaming — ưu tiên buffer + cache local, tránh rè/giật trên mạng di động.
class AudioPlaybackService {
  AudioPlaybackService({AudioPlaybackQuality quality = AudioPlaybackQuality.high})
      : _quality = quality,
        _player = _createPlayer(quality) {
    _bindPlayerStreams();
    _bindStallGuard();
  }

  AudioPlaybackQuality _quality;
  AudioPlayer _player;
  String? _loadedUrl;
  bool _sessionReady = false;
  bool _handlingStall = false;

  StreamSubscription<Duration>? _playerPosSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _playerDurSub;
  StreamSubscription<ProcessingState>? _stallSub;

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

  Future<void> play() async {
    await _ensureSession(active: true);
    await _player.play();
  }

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

  /// Khi buffer cạn giữa chừng — tạm dừng, nạp thêm rồi phát lại (tránh rè ExoPlayer).
  void _bindStallGuard() {
    _stallSub?.cancel();
    _stallSub = _player.processingStateStream.listen((state) {
      if (_handlingStall) return;
      if (state != ProcessingState.buffering) return;
      if (!_player.playing) return;

      unawaited(_recoverFromStall());
    });
  }

  Future<void> _recoverFromStall() async {
    _handlingStall = true;
    try {
      await _player.pause();
      await _waitUntilBufferedAhead(
        _minBufferedFallback,
        timeout: const Duration(seconds: 20),
      );
      if (_player.processingState == ProcessingState.ready) {
        await _ensureSession(active: true);
        await _player.play();
      }
    } catch (_) {
      // Giữ pause — user có thể bấm play lại.
    } finally {
      _handlingStall = false;
    }
  }

  static AndroidLoadControl _androidLoadControl(AudioPlaybackQuality quality) {
    return switch (quality) {
      AudioPlaybackQuality.normal => const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 45),
          maxBufferDuration: Duration(minutes: 6),
          bufferForPlaybackDuration: Duration(seconds: 12),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 16),
          prioritizeTimeOverSizeThresholds: false,
          backBufferDuration: Duration(seconds: 20),
        ),
      AudioPlaybackQuality.high => const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 60),
          maxBufferDuration: Duration(minutes: 10),
          bufferForPlaybackDuration: Duration(seconds: 16),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 20),
          prioritizeTimeOverSizeThresholds: false,
          backBufferDuration: Duration(seconds: 40),
        ),
      AudioPlaybackQuality.lossless => const AndroidLoadControl(
          minBufferDuration: Duration(seconds: 90),
          maxBufferDuration: Duration(minutes: 12),
          bufferForPlaybackDuration: Duration(seconds: 24),
          bufferForPlaybackAfterRebufferDuration: Duration(seconds: 30),
          prioritizeTimeOverSizeThresholds: false,
          backBufferDuration: Duration(seconds: 60),
        ),
    };
  }

  static DarwinLoadControl _darwinLoadControl(AudioPlaybackQuality quality) {
    return switch (quality) {
      AudioPlaybackQuality.normal => const DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: Duration(seconds: 45),
          canUseNetworkResourcesForLiveStreamingWhilePaused: true,
        ),
      AudioPlaybackQuality.high => const DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: Duration(seconds: 90),
          canUseNetworkResourcesForLiveStreamingWhilePaused: true,
        ),
      AudioPlaybackQuality.lossless => const DarwinLoadControl(
          automaticallyWaitsToMinimizeStalling: true,
          preferredForwardBufferDuration: Duration(seconds: 120),
          canUseNetworkResourcesForLiveStreamingWhilePaused: true,
        ),
    };
  }

  Duration get _minBufferedBeforePlay => switch (_quality) {
        AudioPlaybackQuality.normal => const Duration(seconds: 12),
        AudioPlaybackQuality.high => const Duration(seconds: 16),
        AudioPlaybackQuality.lossless => const Duration(seconds: 24),
      };

  Duration get _minBufferedFallback => switch (_quality) {
        AudioPlaybackQuality.normal => const Duration(seconds: 6),
        AudioPlaybackQuality.high => const Duration(seconds: 8),
        AudioPlaybackQuality.lossless => const Duration(seconds: 10),
      };

  Duration get loadTimeout => switch (_quality) {
        AudioPlaybackQuality.normal => const Duration(seconds: 45),
        AudioPlaybackQuality.high => const Duration(seconds: 60),
        AudioPlaybackQuality.lossless => const Duration(seconds: 90),
      };

  AudioSource _sourceForUrl(String url) {
    final uri = Uri.parse(url);
    // Cache xuống disk trước khi/decode — giảm underrun trên CDN/R2.
    // ignore: experimental_member_use
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
    _stallSub?.cancel();
    _quality = quality;
    _player = _createPlayer(quality);
    _bindPlayerStreams();
    _bindStallGuard();
    _loadedUrl = null;

    if (url != null) {
      await loadAndPlay(url, resumePosition: pos, autoPlay: wasPlaying);
    }
  }

  Future<void> _ensureSession({bool active = false}) async {
    final session = await AudioSession.instance;
    if (!_sessionReady) {
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );
      _sessionReady = true;
    }
    if (active) {
      await session.setActive(true);
    }
  }

  Future<void> loadAndPlay(
    String url, {
    Duration resumePosition = Duration.zero,
    bool autoPlay = true,
  }) async {
    await _ensureSession(active: autoPlay);

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _loadSource(
          url,
          resumePosition: resumePosition,
          autoPlay: false,
        );
        await _waitUntilReady();
        await _waitUntilBufferedAhead(
          _minBufferedBeforePlay,
          timeout: loadTimeout,
        );
        if (autoPlay) {
          await _player.play();
        }
        return;
      } on TimeoutException catch (e) {
        lastError = e;
        await _resetPlayerSource();
        if (attempt == 1) rethrow;
      } catch (e) {
        lastError = e;
        await _resetPlayerSource();
        if (attempt == 1) rethrow;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
  }

  Future<void> _loadSource(
    String url, {
    Duration resumePosition = Duration.zero,
    bool autoPlay = true,
  }) async {
    final reload = _loadedUrl != url;
    if (reload) {
      if (_player.playing) {
        await _player.pause();
      }
      await _player.setAudioSource(
        _sourceForUrl(url),
        initialPosition: resumePosition,
        preload: true,
      );
      _loadedUrl = url;
    } else if (resumePosition > Duration.zero) {
      await _player.seek(resumePosition);
    }

    if (autoPlay && !reload) {
      await _player.play();
    }
  }

  Future<void> _resetPlayerSource() async {
    try {
      await _player.stop();
    } catch (_) {}
    _loadedUrl = null;
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

  Future<void> _waitUntilBufferedAhead(
    Duration minimumAhead, {
    Duration? timeout,
  }) async {
    if (minimumAhead <= Duration.zero) return;
    if (_bufferedAhead() >= minimumAhead) return;

    final waitTimeout = timeout ?? loadTimeout;
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
    timeoutTimer = Timer(waitTimeout, () {
      if (completer.isCompleted) return;

      if (_bufferedAhead() >= _minBufferedFallback) {
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
      await _ensureSession(active: true);
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
    try {
      await _player.stop();
    } catch (_) {
      try {
        await _player.pause();
        await _player.seek(Duration.zero);
      } catch (_) {}
    }
    _loadedUrl = null;
  }

  Future<void> dispose() async {
    await _stallSub?.cancel();
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
