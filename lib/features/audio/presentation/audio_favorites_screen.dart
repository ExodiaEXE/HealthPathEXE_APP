import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/utils/user_facing_message.dart';
import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/domain/usecases/audio/audio_usecases.dart';
import 'package:health/features/audio/audio_visuals.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:provider/provider.dart';

/// Danh sách yêu thích nhúng trong tab Âm thanh — giữ bottom nav.
class AudioFavoritesPanel extends StatefulWidget {
  const AudioFavoritesPanel({
    super.key,
    required this.onBack,
    required this.onPlayTrack,
    required this.bottomPadding,
    this.currentTrackId,
    this.playing = false,
  });

  final VoidCallback onBack;
  final Future<void> Function(AudioTrackRecord track) onPlayTrack;
  final double bottomPadding;
  final String? currentTrackId;
  final bool playing;

  @override
  State<AudioFavoritesPanel> createState() => _AudioFavoritesPanelState();
}

class _AudioFavoritesPanelState extends State<AudioFavoritesPanel> {
  List<AudioTrackRecord> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final fetch = context.read<FetchAudioFavoritesUseCase>();
    final res = await fetch();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _tracks = res.tracks ?? [];
      } else {
        _error = UserFacingMessage.sanitize(
          res.message,
          fallback: 'Không tải được danh sách yêu thích.',
        );
        _tracks = [];
      }
    });
  }

  Future<void> _toggleFavorite(AudioTrackRecord track) async {
    final app = context.read<AppStateProvider>();
    final ok = await app.toggleAudioFavorite(track.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _tracks = _tracks.where((t) => t.id != track.id).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 20, 8),
          child: Row(
            children: [
              HpTapScale(
                scale: 0.92,
                onTap: widget.onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                ),
              ),
              const Expanded(
                child: Text(
                  'Bài yêu thích',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        children: const [
          SizedBox(height: 120),
          Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 24, 24, widget.bottomPadding),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: TextButton(onPressed: _load, child: const Text('Thử lại')),
          ),
        ],
      );
    }

    if (_tracks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(32, 40, 32, widget.bottomPadding),
        children: const [
          Icon(Icons.favorite_border, size: 48, color: AppColors.muted),
          SizedBox(height: 16),
          Text(
            'Chưa có bài yêu thích',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Bấm tim ở danh sách nhạc để lưu bài bạn thích.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 8, 20, widget.bottomPadding),
      itemCount: _tracks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = _tracks[i];
        final isActive = t.id == widget.currentTrackId;
        final isPlaying = isActive && widget.playing;
        return _FavoriteTrackTile(
          track: t,
          isActive: isActive,
          isPlaying: isPlaying,
          onPlay: () => widget.onPlayTrack(t),
          onToggleFavorite: () => _toggleFavorite(t),
        );
      },
    );
  }
}

class _FavoriteTrackTile extends StatelessWidget {
  const _FavoriteTrackTile({
    required this.track,
    required this.isActive,
    required this.isPlaying,
    required this.onPlay,
    required this.onToggleFavorite,
  });

  final AudioTrackRecord track;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final color = AudioVisuals.colorFor(track.category);
    return HpTapScale(
      scale: 0.98,
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(color).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                AudioVisuals.emojiFor(track.category),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${track.displayArtist} · ${track.durationLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            HpTapScale(
              scale: 0.9,
              onTap: onToggleFavorite,
              child: const Icon(Icons.favorite, size: 18, color: AppColors.coral),
            ),
            const SizedBox(width: 8),
            Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
              color: isActive ? AppColors.primary : AppColors.muted,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
