import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/core/utils/user_facing_message.dart';
import 'package:health/domain/entities/audio_entities.dart';
import 'package:health/domain/usecases/wellness/wellness_content_usecase.dart';
import 'package:health/features/audio/audio_url_utils.dart';
import 'package:health/features/audio/audio_visuals.dart';
import 'package:health/features/audio/presentation/audio_favorites_screen.dart';
import 'package:health/features/audio/presentation/audio_playback_bridge.dart';
import 'package:health/features/audio/services/audio_media_utils.dart';
import 'package:health/features/audio/services/audio_playback_coordinator.dart';
import 'package:health/features/audio/services/audio_playback_delegate.dart';
import 'package:health/features/audio/services/audio_playback_quality.dart';
import 'package:health/features/audio/services/audio_playback_service.dart';
import 'package:health/features/audio/services/native_pip_service.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/app_snackbar.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:health/shared/widgets/hp_text_field.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen>
    with TickerProviderStateMixin {
  /// Khóa Ổn định / Cao cho user chưa premium.
  static const _qualityRequiresPremium = true;

  WellnessContentUseCase get _wellness =>
      context.read<AppStateProvider>().wellness;

  AudioPlaybackService get _playback => AudioPlaybackCoordinator.playback;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _currentTrackId;
  bool _playing = false;
  double _progress = 0;
  bool _showDetail = false;
  double _volume = 0.85;
  bool _showFavorites = false;
  double _speed = 1.0;
  String _quality = 'normal';
  bool _muted = false;
  bool _preparingPlayback = false;
  int _lastRecordedSeconds = 0;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  late AnimationController _barController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _posSub = _playback.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        final totalMs = _totalDurationMs();
        if (totalMs > 0) {
          _progress = (pos.inMilliseconds / totalMs * 100).clamp(0.0, 100.0);
        }
      });
    });

    _durSub = _playback.durationStream.listen((_) {
      if (mounted) setState(() {});
    });

    _stateSub = _playback.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        unawaited(_onTrackCompleted());
      }
      setState(() => _playing = state.playing);
      if (state.playing) {
        if (!_rotateController.isAnimating) {
          _rotateController.repeat();
        }
      } else {
        _rotateController.stop();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppStateProvider>();
      _syncQualityForPremium(app.isPremium);
      if (app.audioTracks.isEmpty && !app.audioLoading) {
        unawaited(app.loadAudioCatalog());
      }
      syncAudioBridgeSettings(
        context,
        quality: _quality,
        volume: _muted ? 0 : _volume,
        speed: _speed,
        currentTrackId: _currentTrackId,
      );
      _restoreUiFromActivePlayback();
    });

    AudioPlaybackDelegate.trackIdNotifier.addListener(_onExternalTrackChange);
    AudioPlaybackDelegate.openDetailView = _openDetailFromDelegate;
    context.read<AppStateProvider>().addListener(_onAppPremiumChanged);
  }

  void _onAppPremiumChanged() {
    if (!mounted) return;
    _syncQualityForPremium(context.read<AppStateProvider>().isPremium);
  }

  void _openDetailFromDelegate() {
    if (!mounted) return;
    final id = AudioPlaybackDelegate.trackIdNotifier.value;
    setState(() {
      if (id != null) _currentTrackId = id;
      _showDetail = true;
      _showFavorites = false;
    });
  }

  void _syncQualityForPremium(bool isPremium) {
    if (!_qualityRequiresPremium) return;
    if (isPremium) {
      if (_quality == 'normal') {
        setState(() => _quality = 'high');
        unawaited(_playback.setQuality(AudioPlaybackQuality.high));
        _syncBridgeSettings();
      }
      return;
    }
    if (_quality == 'normal') return;
    setState(() => _quality = 'normal');
    unawaited(_playback.setQuality(AudioPlaybackQuality.normal));
    _syncBridgeSettings();
  }

  void _syncBridgeSettings() {
    syncAudioBridgeSettings(
      context,
      quality: _quality,
      volume: _muted ? 0 : _volume,
      speed: _speed,
      currentTrackId: _currentTrackId,
    );
  }

  void _onExternalTrackChange() {
    final id = AudioPlaybackDelegate.trackIdNotifier.value;
    if (!mounted) return;
    if (id == null) {
      _applyStoppedUi();
      return;
    }
    if (id == _currentTrackId) return;
    setState(() {
      _currentTrackId = id;
      _playing = _playback.isPlaying;
    });
    if (_playback.isPlaying) {
      if (!_rotateController.isAnimating) _rotateController.repeat();
    } else {
      _rotateController.stop();
    }
  }

  void _restoreUiFromActivePlayback() {
    final handler = AudioPlaybackCoordinator.handler;
    final item = handler?.mediaItem.value;
    if (item == null) return;
    final trackId = item.id.toLowerCase();
    if (_tracks.any((t) => t.id.toLowerCase() == trackId)) {
      setState(() {
        _currentTrackId = trackId;
        _playing = _playback.isPlaying;
      });
      AudioPlaybackDelegate.notifyTrack(
        trackId,
        playing: _playback.isPlaying,
      );
      if (_playback.isPlaying) {
        _rotateController.repeat();
      }
    }
  }

  List<AudioTrackRecord> _filterTracks(List<AudioTrackRecord> tracks) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return tracks;
    return tracks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.displayArtist.toLowerCase().contains(q) ||
          AudioVisuals.labelFor(t.category).toLowerCase().contains(q);
    }).toList();
  }

  void _openFavorites() => setState(() => _showFavorites = true);

  void _applyStoppedUi() {
    if (!mounted) return;
    setState(() {
      _currentTrackId = null;
      _progress = 0;
      _playing = false;
      _showDetail = false;
      _preparingPlayback = false;
      _lastRecordedSeconds = 0;
    });
    _rotateController.stop();
  }

  int _totalDurationMs() {
    final dur = _playback.duration;
    if (dur != null && dur.inMilliseconds > 0) {
      return dur.inMilliseconds;
    }
    final track = _currentTrack;
    if (track != null && track.durationSeconds > 0) {
      return track.durationSeconds * 1000;
    }
    return 0;
  }

  Future<void> _syncPlaybackUi() async {
    if (!mounted) return;
    setState(() {
      _playing = _playback.isPlaying;
      final totalMs = _totalDurationMs();
      if (totalMs > 0) {
        _progress =
            (_playback.position.inMilliseconds / totalMs * 100).clamp(0.0, 100.0);
      }
    });
    if (_playback.isPlaying) {
      if (!_rotateController.isAnimating) {
        _rotateController.repeat();
      }
    } else {
      _rotateController.stop();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    AudioPlaybackDelegate.trackIdNotifier.removeListener(_onExternalTrackChange);
    context.read<AppStateProvider>().removeListener(_onAppPremiumChanged);
    if (AudioPlaybackDelegate.openDetailView == _openDetailFromDelegate) {
      AudioPlaybackDelegate.openDetailView = null;
    }
    _barController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  List<AudioTrackRecord> get _tracks =>
      context.read<AppStateProvider>().audioTracks;

  AudioTrackRecord? get _currentTrack {
    final id = _currentTrackId;
    if (id == null) return null;
    for (final t in _tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _recordProgressIfNeeded() async {
    final track = _currentTrack;
    if (track == null) return;
    final seconds = _playback.position.inSeconds;
    if (seconds <= _lastRecordedSeconds) return;
    _lastRecordedSeconds = seconds;
    final app = context.read<AppStateProvider>();
    await app.recordAudioListening(
      trackId: track.id,
      playedSeconds: seconds.clamp(1, track.durationSeconds),
    );
  }

  Future<void> _onTrackCompleted() async {
    final track = _currentTrack;
    if (track != null) {
      final app = context.read<AppStateProvider>();
      final seconds =
          _playback.duration?.inSeconds ?? track.durationSeconds;
      await app.recordAudioListening(
        trackId: track.id,
        playedSeconds: seconds.clamp(1, track.durationSeconds),
      );
    }
    _lastRecordedSeconds = 0;
    await _nextTrack();
  }

  Future<void> _togglePlay() async {
    final track = _currentTrack;
    if (track == null) return;

    if (_playback.isPlaying) {
      await _playback.pause();
      await _recordProgressIfNeeded();
      return;
    }

    if (_playback.duration != null) {
      await _playback.togglePlayPause();
      return;
    }

    await _playTrack(track);
  }

  Future<void> _changeQuality(String normalized) async {
    if (_quality == normalized) return;
    setState(() {
      _quality = normalized;
      _preparingPlayback = true;
      _playing = false;
    });
    _rotateController.stop();
    _syncBridgeSettings();
    try {
      await _playback
          .setQuality(AudioPlaybackQuality.fromKey(normalized))
          .timeout(_playback.loadTimeout);
      await _syncPlaybackUi();
    } on TimeoutException {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Chưa tải đủ dữ liệu. Thử lại hoặc chọn chế độ Thường.',
          fallback: 'Chưa tải đủ dữ liệu. Thử lại hoặc chọn chế độ Thường.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _preparingPlayback = false);
      }
    }
  }

  Future<void> _playTrack(AudioTrackRecord track) async {
    final app = context.read<AppStateProvider>();

    if (track.isPremium && !app.isPremium) {
      app.setPaymentStep(PaymentStep.plan);
      return;
    }

    setState(() {
      _currentTrackId = track.id;
      _progress = 0;
      _lastRecordedSeconds = 0;
      _preparingPlayback = true;
    });
    AudioPlaybackDelegate.notifyTrack(track.id, playing: false);
    _syncBridgeSettings();

    try {
      final streamRes = await app
          .resolveAudioStream(track.id)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => AudioOperationResult.fail(
              'Kết nối chậm. Vui lòng thử lại sau.',
            ),
          );
      final uiReady = mounted;

      if (!streamRes.success ||
          streamRes.stream == null ||
          streamRes.stream!.streamUrl.isEmpty) {
        if (uiReady) {
          AppSnackBar.show(
            context,
            streamRes.message ?? 'Không phát được bài này.',
            fallback: 'Không phát được bài này. Thử lại sau.',
          );
          setState(() => _currentTrackId = null);
          AudioPlaybackDelegate.notifyTrack(null, playing: false);
        }
        return;
      }

      final playbackUrl =
          resolvePlaybackUrl(streamRes.stream!.streamUrl);
      if (playbackUrl.isEmpty) {
        if (uiReady) {
          AppSnackBar.show(context, 'Link phát nhạc không hợp lệ.');
          setState(() => _currentTrackId = null);
          AudioPlaybackDelegate.notifyTrack(null, playing: false);
        }
        return;
      }

      final quality = AudioPlaybackQuality.fromKey(_quality);
      if (_playback.quality != quality) {
        await _playback.setQuality(quality);
      }
      await _playback.setVolume(_muted ? 0 : _volume);
      await _playback.setSpeed(_speed);
      await _playback
          .loadAndPlay(playbackUrl)
          .timeout(_playback.loadTimeout);
      AudioPlaybackCoordinator.updateNowPlaying(mediaItemFromTrack(track));
      _syncBridgeSettings();
      await NativePipService.setEnabled(true);
      if (uiReady) {
        await _syncPlaybackUi();
      }
    } on TimeoutException {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Phát nhạc quá lâu. Kiểm tra kết nối mạng.',
          fallback: 'Phát nhạc quá lâu. Kiểm tra kết nối mạng.',
        );
        setState(() => _currentTrackId = null);
        AudioPlaybackDelegate.notifyTrack(null, playing: false);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Không phát được nhạc.',
          fallback: 'Không phát được nhạc. Thử lại sau.',
        );
        setState(() => _currentTrackId = null);
        AudioPlaybackDelegate.notifyTrack(null, playing: false);
      }
    } finally {
      if (mounted) {
        setState(() => _preparingPlayback = false);
      }
    }
  }

  Future<void> _prevTrack() async {
    final tracks = _tracks;
    if (tracks.isEmpty) return;
    final currentIdx = tracks.indexWhere((t) => t.id == _currentTrackId);
    final newIdx = (currentIdx - 1 + tracks.length) % tracks.length;
    await _playTrack(tracks[newIdx]);
  }

  Future<void> _nextTrack() async {
    final tracks = _tracks;
    if (tracks.isEmpty) return;
    final currentIdx = tracks.indexWhere((t) => t.id == _currentTrackId);
    final newIdx = (currentIdx + 1) % tracks.length;
    await _playTrack(tracks[newIdx]);
  }

  String _currentTimeStr(AudioTrackRecord track) {
    final pos = _playback.position;
    final currentSec = pos.inSeconds;
    final m = currentSec ~/ 60;
    final s = currentSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _totalTimeStr(AudioTrackRecord track) {
    final totalMs = _totalDurationMs();
    if (totalMs > 0) {
      final totalSec = totalMs ~/ 1000;
      final m = totalSec ~/ 60;
      final s = totalSec % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return track.durationLabel;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final tracks = app.audioTracks;
    final current = _currentTrack ??
        (tracks.isNotEmpty ? tracks.first : null);

    final recommended = tracks
        .where((t) =>
            AudioVisuals.isRecommendedForEnergy(t.category, app.energyLevel))
        .take(5)
        .toList();
    final displayTracks = _filterTracks(tracks);
    const listBottomPadding = 20.0;

    if (app.audioLoading && tracks.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: _showFavorites
                  ? AudioFavoritesPanel(
                      onBack: () => setState(() => _showFavorites = false),
                      onPlayTrack: _playTrack,
                      currentTrackId: _currentTrackId,
                      playing: _playing,
                      bottomPadding: listBottomPadding,
                    )
                  : RefreshIndicator(
                      onRefresh: () => app.loadAudioCatalog(
                        category: app.audioCategoryFilter,
                      ),
                      child: ListView(
                        padding:
                            EdgeInsets.fromLTRB(20, 12, 20, listBottomPadding),
                        children: [
                          _buildHeader(app),
                          if (app.audioError != null) ...[
                            const SizedBox(height: 12),
                            _buildErrorBanner(app.audioError!),
                          ],
                          if (recommended.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildRecommendationBanner(recommended, app),
                          ],
                          const SizedBox(height: 14),
                          _buildSearchField(),
                          const SizedBox(height: 12),
                          _buildCategoryChips(app),
                          const SizedBox(height: 14),
                          _buildTrackCountLabel(
                            displayTracks.length,
                            total: tracks.length,
                            searching: _searchQuery.trim().isNotEmpty,
                          ),
                          const SizedBox(height: 8),
                          if (tracks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'Chưa có bài hát trong danh mục này.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                            )
                          else if (displayTracks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'Không tìm thấy bài phù hợp.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                            )
                          else
                            ...displayTracks.map(_buildTrackItem),
                        ],
                      ),
                    ),
            ),
          ],
        ),
        if (_showDetail && current != null) _buildDetailView(current),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    final text = UserFacingMessage.sanitize(
      message,
      fallback: 'Không tải được thư viện âm thanh.',
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildHeader(AppStateProvider app) {
    final favoriteCount =
        app.audioTracks.where((t) => t.isFavorited).length;
    return Row(
      children: [
        if (app.previousTab != null)
          GestureDetector(
            onTap: () => app.goBack(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_left, size: 20),
            ),
          ),
        if (app.previousTab != null) const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎧 Thư giãn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Chọn âm thanh phù hợp với bạn',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        HpTapScale(
          scale: 0.92,
          onTap: _openFavorites,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.favorite_rounded,
                    size: 18, color: AppColors.coral),
              ),
              if (favoriteCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$favoriteCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: HpTextField(
        controller: _searchController,
        hint: 'Tìm bài hát, nghệ sĩ...',
        prefixIcon: Icons.search_rounded,
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildRecommendationBanner(
    List<AudioTrackRecord> recommended,
    AppStateProvider app,
  ) {
    final energyLabel = app.energyLevel == EnergyLevel.low
        ? 'Mệt'
        : app.energyLevel == EnergyLevel.medium
            ? 'Ổn'
            : 'Tràn đầy';
    final moodLabel = app.selectedMood != null
        ? _wellness.moods[app.selectedMood!].label
        : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gợi ý cho bạn · $energyLabel${moodLabel.isNotEmpty ? ' · $moodLabel' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommended.length,
              separatorBuilder: (context, idx) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final t = recommended[i];
                final isActive = t.id == _currentTrackId;
                final color = AudioVisuals.colorFor(t.category);
                return HpTapScale(
                  scale: 0.96,
                  onTap: () => _playTrack(t),
                  child: Container(
                    width: 108,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.45)
                            : Colors.white,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(color).withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildArtCircle(t, size: 42, emojiSize: 20),
                        const SizedBox(height: 8),
                        Text(
                          t.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.durationLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(AppStateProvider app) {
    final chips = <({String id, String label, String emoji})>[
      (id: 'all', label: 'Tất cả', emoji: '🎶'),
      ...app.audioCategories.map(
        (c) => (
          id: c.name,
          label: AudioVisuals.labelFor(c.name),
          emoji: AudioVisuals.emojiFor(c.name),
        ),
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = chips[i];
          final sel = app.audioCategoryFilter == c.id;
          return HpTapScale(
            scale: 0.95,
            onTap: () => app.loadAudioCatalog(category: c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: sel
                      ? AppColors.primary
                      : AppColors.border.withValues(alpha: 0.9),
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${c.emoji} ${c.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : const Color(0xFF555555),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackCountLabel(
    int count, {
    required int total,
    required bool searching,
  }) {
    final label = searching
        ? 'KẾT QUẢ ($count/$total)'
        : 'TẤT CẢ ($count)';
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.muted,
      ),
    );
  }

  Widget _buildArtCircle(AudioTrackRecord t,
      {double size = 44, double emojiSize = 20}) {
    final color = AudioVisuals.colorFor(t.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color).withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        AudioVisuals.emojiFor(t.category),
        style: TextStyle(fontSize: emojiSize),
      ),
    );
  }

  Widget _buildTrackItem(AudioTrackRecord t) {
    final isActive = t.id == _currentTrackId;
    final isPlaying = isActive && _playing;
    final app = context.read<AppStateProvider>();
    final isRecommended =
        AudioVisuals.isRecommendedForEnergy(t.category, app.energyLevel);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HpTapScale(
        scale: 0.98,
        onTap: () {
          if (isActive) {
            unawaited(_togglePlay());
          } else {
            unawaited(_playTrack(t));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(20),
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.white,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              _buildArtCircle(t),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (t.isPremium) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.workspace_premium,
                              size: 12, color: AppColors.coral),
                        ],
                        if (isRecommended) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.auto_awesome,
                              size: 12, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.displayArtist,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.durationLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              HpTapScale(
                scale: 0.9,
                onTap: () => app.toggleAudioFavorite(t.id),
                child: Icon(
                  t.isFavorited ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: t.isFavorited ? AppColors.coral : AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              if (_preparingPlayback && isActive)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isPlaying)
                _buildAnimatedBars()
              else
                const Icon(Icons.play_arrow, color: Color(0xFFAAAAAA), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBars() {
    return AnimatedBuilder(
      animation: _barController,
      builder: (context, child) {
        final val = _barController.value;
        final heights = [
          (4.0 + 10.0 * sin(val * pi)).clamp(2.0, 16.0),
          (4.0 + 12.0 * sin(val * pi + 1.2)).clamp(2.0, 18.0),
          (4.0 + 8.0 * sin(val * pi + 2.4)).clamp(2.0, 14.0),
          (4.0 + 12.0 * sin(val * pi + 0.8)).clamp(2.0, 18.0),
          (4.0 + 10.0 * sin(val * pi + 3.0)).clamp(2.0, 16.0),
        ];
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: heights.map((h) {
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetailView(AudioTrackRecord track) {
    return Positioned.fill(
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            setState(() => _showDetail = false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                _buildDetailHeader(track),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildAlbumArt(track),
                        const SizedBox(height: 24),
                        Text(
                          track.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.displayArtist,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildProgressSlider(track),
                        const SizedBox(height: 20),
                        _buildControls(),
                        const SizedBox(height: 24),
                        _buildVolumeSlider(),
                        const SizedBox(height: 28),
                        _buildFeaturesSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(AudioTrackRecord track) {
    final app = context.read<AppStateProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HpTapScale(
            scale: 0.9,
            onTap: () => setState(() => _showDetail = false),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, size: 20),
            ),
          ),
          const Text(
            'ĐANG PHÁT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          Row(
            children: [
              HpTapScale(
                scale: 0.9,
                onTap: () => app.toggleAudioFavorite(track.id),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    track.isFavorited ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: track.isFavorited ? AppColors.coral : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              HpTapScale(
                scale: 0.9,
                onTap: () async {
                  setState(() => _muted = !_muted);
                  await _playback.setVolume(_muted ? 0 : _volume);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(AudioTrackRecord track) {
    final color = AudioVisuals.colorFor(track.category);
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _playing ? _rotateController.value * 2 * pi : 0,
          child: child,
        );
      },
      child: Container(
        width: 176,
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(color).withValues(alpha: 0.3),
              Color(color).withValues(alpha: 0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(color).withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          AudioVisuals.emojiFor(track.category),
          style: const TextStyle(fontSize: 70),
        ),
      ),
    );
  }

  Widget _buildProgressSlider(AudioTrackRecord track) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: const Color(0xFFEEEEEE),
            thumbColor: AppColors.primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: _progress.clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: (v) async {
              setState(() => _progress = v);
              final dur = _playback.duration;
              if (dur != null) {
                await _playback.seek(
                  Duration(
                    milliseconds: (dur.inMilliseconds * v / 100).round(),
                  ),
                );
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTimeStr(track),
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              Text(
                _totalTimeStr(track),
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HpTapScale(
          scale: 0.9,
          onTap: () => unawaited(_prevTrack()),
          child:
              const Icon(Icons.skip_previous, size: 32, color: AppColors.muted),
        ),
        const SizedBox(width: 24),
        HpTapScale(
          scale: 0.9,
          onTap: () => unawaited(_togglePlay()),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _preparingPlayback
                  ? Icons.hourglass_top_rounded
                  : (_playing ? Icons.pause : Icons.play_arrow),
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 24),
        HpTapScale(
          scale: 0.9,
          onTap: () => unawaited(_nextTrack()),
          child: const Icon(Icons.skip_next, size: 32, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildVolumeSlider() {
    return Row(
      children: [
        const Icon(Icons.volume_down, size: 18, color: AppColors.muted),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: const Color(0xFFEEEEEE),
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 2,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: _volume,
              onChanged: (v) async {
                setState(() => _volume = v);
                if (!_muted) await _playback.setVolume(v);
              },
            ),
          ),
        ),
        const Icon(Icons.volume_up, size: 18, color: AppColors.muted),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final app = context.read<AppStateProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TÍNH NĂNG',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        _buildQualityCard(app),
        const SizedBox(height: 10),
        _buildSpeedCard(),
      ],
    );
  }

  Widget _buildQualityCard(AppStateProvider app) {
    const options = [
      ('Thường', 'normal'),
      ('Ổn định', 'high'),
      ('Cao', 'lossless'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.graphic_eq, size: 14, color: AppColors.muted),
              SizedBox(width: 6),
              Text(
                'Chất lượng âm thanh',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _quality == 'high'
                ? 'Tải thêm dữ liệu trước khi phát — phát ổn định, giảm tiếng rè.'
                : _quality == 'lossless'
                    ? 'Buffer tối đa — chất lượng phát cao nhất có thể.'
                    : 'Phát nhanh — tiết kiệm dữ liệu.',
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: options.map((entry) {
              final opt = entry.$1;
              final normalized = entry.$2;
              final isActive = _quality == normalized;
              final isPremiumLocked =
                  _qualityRequiresPremium && opt != 'Thường' && !app.isPremium;
              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: entry != options.last ? 6 : 0),
                  child: HpTapScale(
                    onTap: () {
                      if (isPremiumLocked) {
                        app.setPaymentStep(PaymentStep.plan);
                      } else {
                        unawaited(_changeQuality(normalized));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: isActive
                            ? Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPremiumLocked)
                            const Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: Icon(Icons.workspace_premium,
                                  size: 10, color: AppColors.coral),
                            ),
                          Flexible(
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, size: 14, color: AppColors.muted),
              SizedBox(width: 6),
              Text(
                'Tốc độ phát',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: speeds.map((s) {
                final isActive = _speed == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: HpTapScale(
                    onTap: () async {
                      setState(() => _speed = s);
                      await _playback.setSpeed(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: isActive
                            ? Border.all(
                                color:
                                    AppColors.accent.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Text(
                        '${s}x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isActive ? AppColors.accent : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
