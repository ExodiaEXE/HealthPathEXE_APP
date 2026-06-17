import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/features/audio/services/audio_playback_coordinator.dart';
import 'package:health/features/audio/services/audio_playback_delegate.dart';
import 'package:health/features/audio/services/native_pip_service.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:just_audio/just_audio.dart';

/// PiP khi rời app lúc đang phát — mini player qua Android native PiP.
class AudioPiPHost extends StatefulWidget {
  const AudioPiPHost({super.key, required this.child});

  final Widget child;

  @override
  State<AudioPiPHost> createState() => _AudioPiPHostState();
}

class _AudioPiPHostState extends State<AudioPiPHost>
    with WidgetsBindingObserver {
  bool _musicActive = false;
  bool _inNativePip = false;

  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<MediaItem?>? _mediaSub;
  StreamSubscription<bool>? _pipModeSub;
  VoidCallback? _trackSyncListener;

  @override
  void initState() {
    super.initState();
    NativePipService.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_syncInitialPipState());
    _bindPlayback();
    _pipModeSub = NativePipService.pipModeStream.listen(_onPipModeChanged);
  }

  void _onPipModeChanged(bool inPip) {
    if (!mounted) return;
    setState(() => _inNativePip = inPip);
  }

  Future<void> _syncInitialPipState() async {
    final inPip = await NativePipService.isInPipMode;
    if (inPip && mounted) {
      setState(() => _inNativePip = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _inNativePip = false);
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(_syncNativePipState());
    }
  }

  Future<void> _syncNativePipState() async {
    if (!_isMusicActive()) return;
    final inPip = await NativePipService.isInPipMode;
    if (inPip && mounted) {
      setState(() => _inNativePip = true);
    }
  }

  bool _isMusicActive() {
    if (_musicActive) return true;
    if (AudioPlaybackDelegate.currentTrackId?.call() != null) return true;
    final playback = AudioPlaybackCoordinator.playback;
    return playback.isPlaying ||
        playback.processingState == ProcessingState.loading ||
        playback.processingState == ProcessingState.buffering;
  }

  void _bindPlayback() {
    final handler = AudioPlaybackCoordinator.handler;
    if (handler == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindPlayback());
      return;
    }

    _playbackSub?.cancel();
    _mediaSub?.cancel();

    void syncActive() {
      final active = handler.mediaItem.value != null ||
          AudioPlaybackDelegate.currentTrackId?.call() != null ||
          AudioPlaybackCoordinator.playback.isPlaying;
      if (_musicActive != active) {
        _musicActive = active;
        unawaited(NativePipService.setEnabled(active));
      }
      if (mounted) setState(() {});
    }

    _playbackSub = handler.playbackState.listen((_) => syncActive());
    _mediaSub = handler.mediaItem.listen((_) => syncActive());
    _trackSyncListener = syncActive;
    AudioPlaybackDelegate.trackIdNotifier.addListener(syncActive);
    syncActive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_trackSyncListener != null) {
      AudioPlaybackDelegate.trackIdNotifier
          .removeListener(_trackSyncListener!);
    }
    _playbackSub?.cancel();
    _mediaSub?.cancel();
    _pipModeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inPip =
        _inNativePip || NativePipService.inPipMode;
    if (inPip && _isMusicActive()) {
      return _AudioPiPMiniView(
        onExpand: () {
          if (mounted) setState(() => _inNativePip = false);
        },
      );
    }
    return widget.child;
  }
}

class _AudioPiPMiniView extends StatelessWidget {
  const _AudioPiPMiniView({required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final handler = AudioPlaybackCoordinator.handler;
    final playback = AudioPlaybackCoordinator.playback;

    return Material(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return StreamBuilder<PlaybackState>(
            stream: handler?.playbackState,
            builder: (context, snapshot) {
              final state = snapshot.data ?? handler?.playbackState.value;
              final item = handler?.mediaItem.value;
              final playing = state?.playing ?? playback.isPlaying;
              final title = item?.title ?? 'Đang phát';
              final totalMs = item?.duration?.inMilliseconds ??
                  playback.duration?.inMilliseconds ??
                  0;
              final posMs = playback.position.inMilliseconds;
              final progress =
                  totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

              return Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: const Icon(Icons.open_in_full_rounded,
                              size: 16),
                          padding: EdgeInsets.zero,
                          onPressed: onExpand,
                          tooltip: 'Mở app',
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.15),
                                  AppColors.coral.withValues(alpha: 0.12),
                                ],
                              ),
                            ),
                            child: item?.artUri != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item!.artUri!.toString(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, e, s) => const Icon(
                                        Icons.music_note_rounded,
                                        size: 28,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.music_note_rounded,
                                    size: 28,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (totalMs > 0) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 2,
                          backgroundColor: AppColors.border,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _pipBtn(
                          icon: Icons.skip_previous_rounded,
                          size: 20,
                          onTap: () => unawaited(
                            AudioPlaybackCoordinator.handleSkipToPrevious(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _pipBtn(
                          icon: playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 22,
                          filled: true,
                          onTap: () => unawaited(
                            AudioPlaybackCoordinator.togglePlayPause(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _pipBtn(
                          icon: Icons.skip_next_rounded,
                          size: 20,
                          onTap: () => unawaited(
                            AudioPlaybackCoordinator.handleSkipToNext(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _pipBtn(
                          icon: Icons.close_rounded,
                          size: 20,
                          onTap: () => unawaited(
                            AudioPlaybackCoordinator.handleStop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _pipBtn({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
    bool filled = false,
  }) {
    if (filled) {
      return HpTapScale(
        scale: 0.9,
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      );
    }
    return HpTapScale(
      scale: 0.9,
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: size, color: AppColors.foreground),
      ),
    );
  }
}
