enum AudioPlaybackQuality {
  normal,
  high,
  lossless;

  static AudioPlaybackQuality fromKey(String key) => switch (key) {
        'high' => AudioPlaybackQuality.high,
        'lossless' => AudioPlaybackQuality.lossless,
        _ => AudioPlaybackQuality.normal,
      };
}
