import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/features/audio/audio_url_utils.dart';
import 'package:health/features/audio/services/audio_media_utils.dart';
import 'package:health/features/audio/services/audio_playback_coordinator.dart';
import 'package:health/features/audio/services/audio_playback_delegate.dart';
import 'package:health/features/audio/services/audio_playback_quality.dart';
import 'package:health/features/audio/services/native_pip_service.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

/// Luôn gắn delegate phát nhạc — notification/PiP hoạt động kể cả không mở tab Âm thanh.
class AudioPlaybackBridge extends StatefulWidget {
  const AudioPlaybackBridge({super.key, required this.child});

  final Widget child;

  @override
  State<AudioPlaybackBridge> createState() => _AudioPlaybackBridgeState();
}

class _AudioPlaybackBridgeState extends State<AudioPlaybackBridge> {
  String? _currentTrackId;
  String _quality = 'normal';
  double _volume = 0.85;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _registerDelegate();
  }

  void _registerDelegate() {
    AudioPlaybackDelegate.playTrack = _playTrack;
    AudioPlaybackDelegate.stopPlayback = _onStoppedExternally;
    AudioPlaybackDelegate.tracks = () {
      try {
        return context.read<AppStateProvider>().audioTracks;
      } catch (_) {
        return const <AudioTrackRecord>[];
      }
    };
    AudioPlaybackDelegate.currentTrackId = () => _currentTrackId;
    AudioPlaybackDelegate.syncUi = (trackId, {required playing}) {
      _currentTrackId = trackId;
    };
  }

  void _onStoppedExternally() {
    _currentTrackId = null;
    unawaited(NativePipService.setEnabled(false));
  }

  Future<void> _playTrack(AudioTrackRecord track) async {
    final app = context.read<AppStateProvider>();

    if (track.isPremium && !app.isPremium) {
      return;
    }

    _currentTrackId = track.id;
    AudioPlaybackDelegate.notifyTrack(track.id, playing: false);

    try {
      final streamRes = await app.resolveAudioStream(track.id).timeout(
            const Duration(seconds: 12),
            onTimeout: () => AudioOperationResult.fail(
              'Kết nối chậm. Vui lòng thử lại sau.',
            ),
          );

      if (!streamRes.success ||
          streamRes.stream == null ||
          streamRes.stream!.streamUrl.isEmpty) {
        return;
      }

      final playbackUrl = resolvePlaybackUrl(streamRes.stream!.streamUrl);
      if (playbackUrl.isEmpty) return;

      final playback = AudioPlaybackCoordinator.playback;
      await playback.stop();

      final quality = AudioPlaybackQuality.fromKey(_quality);
      if (playback.quality != quality) {
        await playback.setQuality(quality);
      }
      await playback.setVolume(_volume);
      await playback.setSpeed(_speed);
      await playback.loadAndPlay(playbackUrl).timeout(playback.loadTimeout);

      AudioPlaybackCoordinator.updateNowPlaying(mediaItemFromTrack(track));
      await NativePipService.setEnabled(true);
      AudioPlaybackDelegate.notifyTrack(track.id, playing: playback.isPlaying);
    } catch (_) {
      _currentTrackId = null;
      AudioPlaybackDelegate.notifyTrack(null, playing: false);
    }
  }

  void syncSettings({
    String? quality,
    double? volume,
    double? speed,
    String? currentTrackId,
  }) {
    if (quality != null) _quality = quality;
    if (volume != null) _volume = volume;
    if (speed != null) _speed = speed;
    if (currentTrackId != null) _currentTrackId = currentTrackId;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Cập nhật cài đặt phát từ [AudioScreen] sang bridge.
void syncAudioBridgeSettings(
  BuildContext context, {
  String? quality,
  double? volume,
  double? speed,
  String? currentTrackId,
}) {
  final bridge = context.findAncestorStateOfType<_AudioPlaybackBridgeState>();
  bridge?.syncSettings(
    quality: quality,
    volume: volume,
    speed: speed,
    currentTrackId: currentTrackId,
  );
}
