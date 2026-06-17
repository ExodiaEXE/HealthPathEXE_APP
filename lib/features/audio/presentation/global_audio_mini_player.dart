import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/features/audio/audio_visuals.dart';
import 'package:health/features/audio/services/audio_playback_coordinator.dart';
import 'package:health/features/audio/services/audio_playback_delegate.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

/// Mini player cố định trên bottom nav — hiện mọi tab khi đang phát nhạc.
class GlobalAudioMiniPlayer extends StatefulWidget {
  const GlobalAudioMiniPlayer({super.key});

  static const height = 62.0;

  @override
  State<GlobalAudioMiniPlayer> createState() => _GlobalAudioMiniPlayerState();
}

class _GlobalAudioMiniPlayerState extends State<GlobalAudioMiniPlayer>
    with SingleTickerProviderStateMixin {
  String? _trackId;
  bool _playing = false;
  bool _loading = false;
  double _progress = 0;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _trackId = AudioPlaybackDelegate.trackIdNotifier.value ??
        AudioPlaybackDelegate.currentTrackId?.call() ??
        AudioPlaybackCoordinator.handler?.mediaItem.value?.id;
    if (_trackId != null &&
        AudioPlaybackDelegate.trackIdNotifier.value == null) {
      AudioPlaybackDelegate.notifyTrack(
        _trackId,
        playing: AudioPlaybackCoordinator.playback.isPlaying,
      );
    }
    _syncPlaybackState();
    AudioPlaybackDelegate.trackIdNotifier.addListener(_onTrackChanged);
    _bindPlaybackStreams();
  }

  void _bindPlaybackStreams() {
    final playback = AudioPlaybackCoordinator.playback;
    playback.positionStream.listen((pos) {
      if (!mounted || _trackId == null) return;
      final tracks = context.read<AppStateProvider>().audioTracks;
      final totalMs = _totalDurationMs(tracks);
      if (totalMs <= 0) return;
      setState(() {
        _progress =
            (pos.inMilliseconds / totalMs * 100).clamp(0.0, 100.0);
      });
    });
    playback.playerStateStream.listen((state) {
      if (!mounted) return;
      final loading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      setState(() {
        _playing = state.playing;
        _loading = loading;
      });
      if (state.playing && !loading) {
        if (!_rotateController.isAnimating) _rotateController.repeat();
      } else {
        _rotateController.stop();
      }
    });
  }

  void _onTrackChanged() {
    if (!mounted) return;
    final id = AudioPlaybackDelegate.trackIdNotifier.value;
    setState(() {
      _trackId = id;
      if (id == null) {
        _progress = 0;
        _playing = false;
        _loading = false;
      }
    });
    if (id == null) {
      _rotateController.stop();
    } else {
      _syncPlaybackState();
    }
  }

  void _syncPlaybackState() {
    final playback = AudioPlaybackCoordinator.playback;
    _playing = playback.isPlaying;
    _loading = playback.processingState == ProcessingState.loading ||
        playback.processingState == ProcessingState.buffering;
    if (!mounted) return;
    final tracks = context.read<AppStateProvider>().audioTracks;
    final totalMs = _totalDurationMs(tracks);
    if (totalMs > 0) {
      _progress = (playback.position.inMilliseconds / totalMs * 100)
          .clamp(0.0, 100.0);
    }
    if (_playing && !_loading) {
      if (!_rotateController.isAnimating) _rotateController.repeat();
    } else {
      _rotateController.stop();
    }
  }

  int _totalDurationMs(List<AudioTrackRecord> tracks) {
    final dur = AudioPlaybackCoordinator.playback.duration;
    if (dur != null && dur.inMilliseconds > 0) return dur.inMilliseconds;
    final track = _findTrack(_trackId, tracks);
    if (track != null && track.durationSeconds > 0) {
      return track.durationSeconds * 1000;
    }
    final mediaDur =
        AudioPlaybackCoordinator.handler?.mediaItem.value?.duration;
    if (mediaDur != null && mediaDur.inMilliseconds > 0) {
      return mediaDur.inMilliseconds;
    }
    return 0;
  }

  AudioTrackRecord? _findTrack(String? id, List<AudioTrackRecord> tracks) {
    if (id == null) return null;
    for (final t in tracks) {
      if (t.id.toLowerCase() == id.toLowerCase()) return t;
    }
    return null;
  }

  Future<void> _stop() async {
    final trackId = _trackId;
    final seconds = AudioPlaybackCoordinator.playback.position.inSeconds;
    if (trackId != null && seconds >= 1 && mounted) {
      final app = context.read<AppStateProvider>();
      unawaited(app.recordAudioListening(
        trackId: trackId,
        playedSeconds: seconds,
      ));
    }
    await AudioPlaybackCoordinator.handleStop();
  }

  void _openDetail(BuildContext context) {
    context.read<AppStateProvider>().navigateTo(ActiveTab.audio);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioPlaybackDelegate.requestOpenDetail();
    });
  }

  @override
  void dispose() {
    AudioPlaybackDelegate.trackIdNotifier.removeListener(_onTrackChanged);
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_trackId == null) return const SizedBox.shrink();

    final tracks = context.watch<AppStateProvider>().audioTracks;
    final track = _findTrack(_trackId, tracks);
    final mediaItem = AudioPlaybackCoordinator.handler?.mediaItem.value;
    final title = track?.title ?? mediaItem?.title ?? 'Đang phát';
    final category = track?.category ?? mediaItem?.album ?? 'audio';
    final timeStr = _formatTime(AudioPlaybackCoordinator.playback.position);

    return Material(
      color: Colors.white,
      child: Container(
        height: GlobalAudioMiniPlayer.height,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SizedBox(
                height: 3,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_progress / 100).clamp(0.0, 1.0),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openDetail(context),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _rotateController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _playing
                                    ? _rotateController.value * 2 * pi
                                    : 0,
                                child: child,
                              );
                            },
                            child: _artCircle(category),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _loading ? 'Đang tải...' : timeStr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _iconBtn(
                    icon: Icons.skip_previous_rounded,
                    onTap: () => unawaited(
                      AudioPlaybackCoordinator.handleSkipToPrevious(),
                    ),
                  ),
                  _playBtn(),
                  _iconBtn(
                    icon: Icons.skip_next_rounded,
                    onTap: () => unawaited(
                      AudioPlaybackCoordinator.handleSkipToNext(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 22, color: AppColors.muted),
                    tooltip: 'Dừng phát',
                    onPressed: () => unawaited(_stop()),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playBtn() {
    return HpTapScale(
      scale: 0.9,
      onTap: _loading
          ? null
          : () => unawaited(AudioPlaybackCoordinator.togglePlayPause()),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return HpTapScale(
      scale: 0.9,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 24, color: AppColors.muted),
      ),
    );
  }

  Widget _artCircle(String category) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.coral.withValues(alpha: 0.12),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        AudioVisuals.emojiFor(category),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  String _formatTime(Duration pos) {
    final m = pos.inMinutes;
    final s = pos.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
