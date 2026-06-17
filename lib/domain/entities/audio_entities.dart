class AudioTrackRecord {
  const AudioTrackRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryId,
    required this.durationSeconds,
    required this.isPremium,
    required this.playCount,
    required this.isFavorited,
    this.artist,
    this.studio,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String? artist;
  final String? studio;
  final String category;
  final String categoryId;
  final int durationSeconds;
  final String? coverUrl;
  final bool isPremium;
  final int playCount;
  final bool isFavorited;

  factory AudioTrackRecord.fromJson(Map<String, dynamic> json) =>
      AudioTrackRecord(
        id: (json['id'] as String? ?? '').toLowerCase(),
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String?,
        studio: json['studio'] as String?,
        category: json['category'] as String? ?? '',
        categoryId: (json['categoryId'] as String? ?? '').toLowerCase(),
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        coverUrl: json['coverUrl'] as String?,
        isPremium: json['isPremium'] == true,
        playCount: (json['playCount'] as num?)?.toInt() ?? 0,
        isFavorited: json['isFavorited'] == true,
      );

  String get displayArtist => artist?.trim().isNotEmpty == true
      ? artist!.trim()
      : (studio?.trim().isNotEmpty == true ? studio!.trim() : 'HealthPath Audio');

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get durationLabel => formatDuration(durationSeconds);

  AudioTrackRecord copyWith({bool? isFavorited, int? playCount}) =>
      AudioTrackRecord(
        id: id,
        title: title,
        category: category,
        categoryId: categoryId,
        durationSeconds: durationSeconds,
        isPremium: isPremium,
        playCount: playCount ?? this.playCount,
        isFavorited: isFavorited ?? this.isFavorited,
        artist: artist,
        studio: studio,
        coverUrl: coverUrl,
      );
}

class AudioCategoryRecord {
  const AudioCategoryRecord({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    this.description,
    this.iconUrl,
  });

  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final int sortOrder;

  factory AudioCategoryRecord.fromJson(Map<String, dynamic> json) =>
      AudioCategoryRecord(
        id: (json['id'] as String? ?? '').toLowerCase(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        iconUrl: json['iconUrl'] as String?,
        isActive: json['isActive'] != false,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

class AudioStreamResult {
  const AudioStreamResult({
    required this.streamUrl,
    required this.expiresAt,
  });

  final String streamUrl;
  final DateTime expiresAt;

  factory AudioStreamResult.fromJson(Map<String, dynamic> json) =>
      AudioStreamResult(
        streamUrl: json['streamUrl'] as String? ?? '',
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(hours: 1)),
      );

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AudioOperationResult {
  const AudioOperationResult({
    required this.success,
    this.message,
    this.tracks,
    this.categories,
    this.stream,
    this.isFavorited,
  });

  final bool success;
  final String? message;
  final List<AudioTrackRecord>? tracks;
  final List<AudioCategoryRecord>? categories;
  final AudioStreamResult? stream;
  final bool? isFavorited;

  factory AudioOperationResult.fail(String message) =>
      AudioOperationResult(success: false, message: message);
}
