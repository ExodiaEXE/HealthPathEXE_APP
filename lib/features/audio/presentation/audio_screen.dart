import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/data/mock_data.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:health/shared/widgets/hp_tap_scale.dart';
import 'package:provider/provider.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen>
    with TickerProviderStateMixin {
  String _category = 'all';
  int _currentIdx = 0;
  bool _playing = false;
  double _progress = 0;
  bool _showDetail = false;
  double _volume = 0.7;
  double _speed = 1.0;
  String _quality = 'normal';
  bool _muted = false;
  Timer? _timer;
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _barController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _timer?.cancel();
    if (_playing) {
      _rotateController.repeat();
      _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        setState(() {
          _progress += 0.5;
          if (_progress >= 100) {
            _progress = 0;
            _playing = false;
            _timer?.cancel();
            _rotateController.stop();
          }
        });
      });
    } else {
      _rotateController.stop();
    }
  }

  void _playTrack(int idx) {
    _timer?.cancel();
    setState(() {
      _currentIdx = idx;
      _progress = 0;
      _playing = false;
    });
    _togglePlay();
  }

  void _prevTrack() {
    final newIdx =
        (_currentIdx - 1 + MockData.allTracks.length) % MockData.allTracks.length;
    _playTrack(newIdx);
  }

  void _nextTrack() {
    final newIdx = (_currentIdx + 1) % MockData.allTracks.length;
    _playTrack(newIdx);
  }

  List<AudioTrack> get _filtered {
    if (_category == 'all') return MockData.allTracks;
    return MockData.allTracks
        .where((t) => t.categories.contains(_category))
        .toList();
  }

  String get _currentTimeStr {
    final track = MockData.allTracks[_currentIdx];
    final parts = track.duration.split(':');
    final totalSec = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final currentSec = (totalSec * _progress / 100).round();
    final m = currentSec ~/ 60;
    final s = currentSec % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final track = MockData.allTracks[_currentIdx];
    final recommended = MockData.allTracks
        .where((t) =>
            app.energyLevel != null &&
            t.recommendFor.contains(app.energyLevel))
        .take(5)
        .toList();

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  _buildHeader(app),
                  if (recommended.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildRecommendationBanner(recommended, app),
                  ],
                  const SizedBox(height: 16),
                  _buildCategoryChips(),
                  const SizedBox(height: 12),
                  _buildTrackCountLabel(),
                  const SizedBox(height: 8),
                  ..._filtered.map((t) {
                    final idx =
                        MockData.allTracks.indexWhere((x) => x.id == t.id);
                    return _buildTrackItem(t, idx);
                  }),
                ],
              ),
            ),
          ],
        ),
        if (_playing || _progress > 0) _buildMiniPlayer(track),
        if (_showDetail) _buildDetailView(track),
      ],
    );
  }

  Widget _buildHeader(AppStateProvider app) {
    return Row(
      children: [
        if (app.previousTab != null)
          GestureDetector(
            onTap: () => app.goBack(),
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
        if (app.previousTab != null) const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
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
      ],
    );
  }

  Widget _buildRecommendationBanner(
      List<AudioTrack> recommended, AppStateProvider app) {
    final energyLabel = app.energyLevel == EnergyLevel.low
        ? 'Mệt'
        : app.energyLevel == EnergyLevel.medium
            ? 'Ổn'
            : 'Tràn đầy';
    final moodLabel = app.selectedMood != null
        ? MockData.moods[app.selectedMood!].label
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Gợi ý cho bạn ($energyLabel${moodLabel.isNotEmpty ? ' + $moodLabel' : ''})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            separatorBuilder: (context, idx) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = recommended[i];
              final globalIdx =
                  MockData.allTracks.indexWhere((x) => x.id == t.id);
              final isActive = globalIdx == _currentIdx && _playing;
              return HpTapScale(
                scale: 0.95,
                onTap: () => _playTrack(globalIdx),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(10),
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
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(t.color).withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(t.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.duration,
                        style:
                            const TextStyle(fontSize: 8, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MockData.audioCategories.map((c) {
        final sel = _category == c.$1;
        return HpTapScale(
          scale: 0.95,
          onTap: () => setState(() => _category = c.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(50),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              '${c.$3} ${c.$2}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrackCountLabel() {
    return Text(
      'TẤT CẢ (${_filtered.length})',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.muted,
      ),
    );
  }

  Widget _buildTrackItem(AudioTrack t, int idx) {
    final isActive = idx == _currentIdx;
    final isPlaying = isActive && _playing;
    final isRecommended = context.read<AppStateProvider>().energyLevel != null &&
        t.recommendFor.contains(context.read<AppStateProvider>().energyLevel);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HpTapScale(
        scale: 0.98,
        onTap: () {
          if (isActive) {
            _togglePlay();
          } else {
            _playTrack(idx);
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(t.color).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(t.emoji, style: const TextStyle(fontSize: 20)),
              ),
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
                        Text(
                          t.artist,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.duration,
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
              if (isPlaying)
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

  Widget _buildMiniPlayer(AudioTrack track) {
    return Positioned(
      bottom: 72,
      left: 12,
      right: 12,
      child: GestureDetector(
        onTap: () => setState(() => _showDetail = true),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  color: const Color(0xFFF0F0F0),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(track.color).withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(track.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _currentTimeStr,
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
                      onTap: _prevTrack,
                      child: const Icon(Icons.skip_previous,
                          size: 22, color: AppColors.muted),
                    ),
                    const SizedBox(width: 8),
                    HpTapScale(
                      scale: 0.9,
                      onTap: _togglePlay,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    HpTapScale(
                      scale: 0.9,
                      onTap: _nextTrack,
                      child: const Icon(Icons.skip_next,
                          size: 22, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView(AudioTrack track) {
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
                _buildDetailHeader(),
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
                          track.artist,
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

  Widget _buildDetailHeader() {
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
          HpTapScale(
            scale: 0.9,
            onTap: () => setState(() => _muted = !_muted),
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
    );
  }

  Widget _buildAlbumArt(AudioTrack track) {
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
              Color(track.color).withValues(alpha: 0.3),
              Color(track.color).withValues(alpha: 0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(track.color).withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(track.emoji, style: const TextStyle(fontSize: 70)),
      ),
    );
  }

  Widget _buildProgressSlider(AudioTrack track) {
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
            onChanged: (v) => setState(() => _progress = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTimeStr,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              Text(
                track.duration,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.muted),
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
          onTap: _prevTrack,
          child:
              const Icon(Icons.skip_previous, size: 32, color: AppColors.muted),
        ),
        const SizedBox(width: 24),
        HpTapScale(
          scale: 0.9,
          onTap: _togglePlay,
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
              _playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 24),
        HpTapScale(
          scale: 0.9,
          onTap: _nextTrack,
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
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 2,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: _volume,
              onChanged: (v) => setState(() => _volume = v),
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: HpTapScale(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download, size: 16, color: AppColors.muted),
                      SizedBox(width: 6),
                      Text(
                        'Tải xuống',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HpTapScale(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 16, color: AppColors.muted),
                      SizedBox(width: 6),
                      Text(
                        'Chia sẻ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityCard(AppStateProvider app) {
    final options = ['Thường', 'Cao', 'Lossless'];
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
          Row(
            children: options.map((opt) {
              final isActive = _quality ==
                  opt.toLowerCase().replaceAll('thường', 'normal').replaceAll('cao', 'high').replaceAll('lossless', 'lossless');
              final isPremiumLocked = opt != 'Thường' && !app.isPremium;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: opt != options.last ? 6 : 0),
                  child: HpTapScale(
                    onTap: () {
                      if (isPremiumLocked) {
                        app.setPaymentStep(PaymentStep.plan);
                      } else {
                        setState(() => _quality = opt.toLowerCase()
                            .replaceAll('thường', 'normal')
                            .replaceAll('cao', 'high'));
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
                    onTap: () => setState(() => _speed = s),
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
