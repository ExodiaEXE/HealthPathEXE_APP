class CompanionState {
  const CompanionState({
    required this.level,
    required this.xp,
    required this.xpForNextLevel,
    required this.coins,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.roomTheme,
    required this.equippedItemSkus,
    required this.canFeed,
    required this.canPet,
    this.feedBlockedReason,
    this.petBlockedReason,
    this.feedCooldownSeconds = 0,
    this.petCooldownSeconds = 0,
    this.mascotMood = 'idle',
  });

  final int level;
  final int xp;
  final int xpForNextLevel;
  final int coins;
  final int hunger;
  final int happiness;
  final int energy;
  final String roomTheme;
  final List<String> equippedItemSkus;
  final bool canFeed;
  final bool canPet;
  final String? feedBlockedReason;
  final String? petBlockedReason;
  final int feedCooldownSeconds;
  final int petCooldownSeconds;
  final String mascotMood;

  factory CompanionState.fromJson(Map<String, dynamic> json) {
    return CompanionState(
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      xpForNextLevel: json['xpForNextLevel'] as int? ?? 100,
      coins: json['coins'] as int? ?? 0,
      hunger: json['hunger'] as int? ?? 70,
      happiness: json['happiness'] as int? ?? 80,
      energy: json['energy'] as int? ?? 90,
      roomTheme: json['roomTheme'] as String? ?? 'room_1',
      equippedItemSkus: (json['equippedItemSkus'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      canFeed: json['canFeed'] == true,
      canPet: json['canPet'] == true,
      feedBlockedReason: json['feedBlockedReason'] as String?,
      petBlockedReason: json['petBlockedReason'] as String?,
      feedCooldownSeconds: json['feedCooldownSeconds'] as int? ?? 0,
      petCooldownSeconds: json['petCooldownSeconds'] as int? ?? 0,
      mascotMood: json['mascotMood'] as String? ?? 'idle',
    );
  }

  static const initial = CompanionState(
    level: 1,
    xp: 0,
    xpForNextLevel: 100,
    coins: 100,
    hunger: 70,
    happiness: 80,
    energy: 90,
    roomTheme: 'room_1',
    equippedItemSkus: [],
    canFeed: true,
    canPet: true,
  );
}

class CompanionActionResult {
  const CompanionActionResult({
    required this.state,
    required this.message,
    this.coinsEarned = 0,
    this.xpEarned = 0,
  });

  final CompanionState state;
  final String message;
  final int coinsEarned;
  final int xpEarned;

  factory CompanionActionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CompanionActionResult(
      state: CompanionState.fromJson(
        data['state'] as Map<String, dynamic>? ?? {},
      ),
      message: data['message'] as String? ?? '',
      coinsEarned: data['coinsEarned'] as int? ?? 0,
      xpEarned: data['xpEarned'] as int? ?? 0,
    );
  }
}

class CompanionMission {
  const CompanionMission({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.category,
    required this.targetCount,
    required this.progress,
    required this.isCompleted,
    required this.rewardCoins,
    required this.rewardXp,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String category;
  final int targetCount;
  final int progress;
  final bool isCompleted;
  final int rewardCoins;
  final int rewardXp;

  factory CompanionMission.fromJson(Map<String, dynamic> json) {
    return CompanionMission(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'daily',
      targetCount: json['targetCount'] as int? ?? 1,
      progress: json['progress'] as int? ?? 0,
      isCompleted: json['isCompleted'] == true,
      rewardCoins: json['rewardCoins'] as int? ?? 0,
      rewardXp: json['rewardXp'] as int? ?? 0,
    );
  }
}

class CompanionMissionsBundle {
  const CompanionMissionsBundle({
    required this.category,
    required this.completedCount,
    required this.totalCount,
    required this.missions,
  });

  final String category;
  final int completedCount;
  final int totalCount;
  final List<CompanionMission> missions;

  factory CompanionMissionsBundle.fromJson(Map<String, dynamic> json) {
    final items = json['missions'] as List<dynamic>? ?? [];
    return CompanionMissionsBundle(
      category: json['category'] as String? ?? 'daily',
      completedCount: json['completedCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      missions: items
          .map((e) => CompanionMission.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CompanionCatalogItem {
  const CompanionCatalogItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.price,
    required this.iconEmoji,
    required this.isOwned,
    required this.isEquipped,
    this.previewUrl,
  });

  final String id;
  final String sku;
  final String name;
  final String category;
  final int price;
  final String iconEmoji;
  final bool isOwned;
  final bool isEquipped;
  final String? previewUrl;

  factory CompanionCatalogItem.fromJson(Map<String, dynamic> json) {
    return CompanionCatalogItem(
      id: json['id']?.toString() ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '📦',
      isOwned: json['isOwned'] == true,
      isEquipped: json['isEquipped'] == true,
      previewUrl: json['previewUrl'] as String?,
    );
  }
}

class CompanionOperationResult {
  const CompanionOperationResult({
    required this.success,
    this.message,
    this.state,
    this.action,
    this.missions,
    this.catalog,
    this.assets,
  });

  final bool success;
  final String? message;
  final CompanionState? state;
  final CompanionActionResult? action;
  final CompanionMissionsBundle? missions;
  final List<CompanionCatalogItem>? catalog;
  final CompanionAssets? assets;

  factory CompanionOperationResult.fail(String message) =>
      CompanionOperationResult(success: false, message: message);
}

/// CDN 3D asset URLs — Phase 2 companion rendering.
class CompanionAssets {
  const CompanionAssets({
    required this.version,
    required this.enable3D,
    required this.mascotGlbUrl,
    required this.roomSceneUrls,
    required this.mascotAnimations,
  });

  final String version;
  final bool enable3D;
  final String mascotGlbUrl;
  final Map<String, String> roomSceneUrls;
  final Map<String, String> mascotAnimations;

  String animationFor(String expression) =>
      mascotAnimations[expression] ?? mascotAnimations['idle'] ?? 'Survey';

  String? roomUrlFor(String theme) => roomSceneUrls[theme];

  /// GLB nhúng trong app — không cần CDN/R2 để chạy 3D.
  static const bundledMascotAsset = 'assets/companion/mascot.glb';

  String get effectiveMascotSrc {
    final url = mascotGlbUrl.trim();
    if (url.isEmpty) return bundledMascotAsset;
    if (url.startsWith('assets/')) return url;
    return url;
  }

  factory CompanionAssets.fromJson(Map<String, dynamic> json) {
    final roomRaw = json['roomSceneUrls'] as Map<String, dynamic>? ?? {};
    final animRaw = json['mascotAnimations'] as Map<String, dynamic>? ?? {};
    return CompanionAssets(
      version: json['version'] as String? ?? '1',
      enable3D: json['enable3D'] == true,
      mascotGlbUrl: json['mascotGlbUrl'] as String? ?? '',
      roomSceneUrls: roomRaw.map((k, v) => MapEntry(k, v.toString())),
      mascotAnimations: animRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Room background image assets — room_1..room_4.
  static const roomImageAssets = {
    'room_1': 'assets/companion/rooms/room_1.jpg',
    'room_2': 'assets/companion/rooms/room_2.jpg',
    'room_3': 'assets/companion/rooms/room_3.jpg',
    'room_4': 'assets/companion/rooms/room_4.jpg',
  };

  String? roomImageFor(String theme) => roomImageAssets[theme];

  static const fallback = CompanionAssets(
    version: '1',
    enable3D: true,
    mascotGlbUrl: bundledMascotAsset,
    roomSceneUrls: {},
    mascotAnimations: {
      'idle': 'Scene',
      'happy': 'Scene',
      'eat': 'Scene',
      'sad': 'Scene',
      'sleepy': 'Scene',
      'wave': 'Scene',
      'hungry': 'Scene',
    },
  );
}
