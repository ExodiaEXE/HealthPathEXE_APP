import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/data/mock_data.dart';
import 'package:health/shared/models/app_models.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  String _category = 'all';
  int _currentIdx = 0;
  bool _playing = false;
  double _progress = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _timer?.cancel();
    if (_playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        setState(() {
          _progress += 0.5;
          if (_progress >= 100) {
            _progress = 0;
            _playing = false;
            _timer?.cancel();
          }
        });
      });
    }
  }

  List<AudioTrack> get _filtered {
    if (_category == 'all') return MockData.allTracks;
    return MockData.allTracks.where((t) => t.categories.contains(_category)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final track = MockData.allTracks[_currentIdx];
    final recommended = MockData.allTracks
        .where((t) => app.energyLevel != null && t.recommendFor.contains(app.energyLevel))
        .take(5)
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            children: [
              const Text('🎧 Thu gian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Text('Chon am thanh phu hop voi ban', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              if (recommended.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Goi y cho ban', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommended.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final t = recommended[i];
                      return _trackChip(t, () {
                        setState(() {
                          _currentIdx = MockData.allTracks.indexWhere((x) => x.id == t.id);
                          _progress = 0;
                          _playing = true;
                        });
                        _togglePlay();
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: MockData.audioCategories.map((c) {
                    final sel = _category == c.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: sel,
                        label: Text('${c.$3} ${c.$2}', style: const TextStyle(fontSize: 11)),
                        onSelected: (_) => setState(() => _category = c.$1),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              ..._filtered.map((t) {
                final idx = MockData.allTracks.indexWhere((x) => x.id == t.id);
                final active = idx == _currentIdx && _playing;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(t.color).withValues(alpha: 0.15),
                      child: Text(t.emoji),
                    ),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('${t.artist} · ${t.duration}', style: const TextStyle(fontSize: 11)),
                    trailing: Icon(active ? Icons.pause_circle : Icons.play_circle, color: AppColors.primary),
                    onTap: () {
                      setState(() {
                        _currentIdx = idx;
                        _progress = 0;
                        _playing = true;
                      });
                      _togglePlay();
                    },
                  ),
                );
              }),
              if (!app.isPremium)
                ListTile(
                  onTap: () => app.setPaymentStep(PaymentStep.plan),
                  leading: const Icon(Icons.workspace_premium, color: AppColors.coral),
                  title: const Text('Nang cap de nghe chat luong cao', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        _miniPlayer(track),
      ],
    );
  }

  Widget _trackChip(AudioTrack t, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 22)),
            Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9)),
            Text(t.duration, style: const TextStyle(fontSize: 8, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _miniPlayer(AudioTrack track) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress / 100, color: AppColors.primary, backgroundColor: const Color(0xFFF0F0F0)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(track.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(track.artist, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
              ),
              IconButton(icon: Icon(_playing ? Icons.pause : Icons.play_arrow), color: AppColors.primary, onPressed: _togglePlay),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => setState(() => _currentIdx = (_currentIdx + 1) % MockData.allTracks.length),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
