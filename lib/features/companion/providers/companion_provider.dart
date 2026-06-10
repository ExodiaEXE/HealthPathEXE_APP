import 'package:flutter/foundation.dart';
import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/domain/usecases/companion/companion_usecases.dart';

class CompanionProvider extends ChangeNotifier {
  CompanionProvider({
    required FetchCompanionStateUseCase fetchState,
    required FetchCompanionAssetsUseCase fetchAssets,
    required FeedCompanionUseCase feed,
    required PetCompanionUseCase pet,
    required FetchCompanionMissionsUseCase fetchMissions,
    required FetchCompanionCatalogUseCase fetchCatalog,
    required PurchaseCompanionItemUseCase purchase,
    required EquipCompanionItemUseCase equip,
    required SetCompanionRoomThemeUseCase setRoomTheme,
  })  : _fetchState = fetchState,
        _fetchAssets = fetchAssets,
        _feed = feed,
        _pet = pet,
        _fetchMissions = fetchMissions,
        _fetchCatalog = fetchCatalog,
        _purchase = purchase,
        _equip = equip,
        _setRoomTheme = setRoomTheme;

  final FetchCompanionStateUseCase _fetchState;
  final FetchCompanionAssetsUseCase _fetchAssets;
  final FeedCompanionUseCase _feed;
  final PetCompanionUseCase _pet;
  final FetchCompanionMissionsUseCase _fetchMissions;
  final FetchCompanionCatalogUseCase _fetchCatalog;
  final PurchaseCompanionItemUseCase _purchase;
  final EquipCompanionItemUseCase _equip;
  final SetCompanionRoomThemeUseCase _setRoomTheme;

  CompanionState state = CompanionState.initial;
  CompanionAssets assets = CompanionAssets.fallback;
  bool loading = false;
  String? error;
  String? lastMessage;
  String petExpression = 'idle';

  CompanionMissionsBundle? missions;
  List<CompanionCatalogItem> catalog = [];

  Future<void> loadAssets() async {
    final res = await _fetchAssets();
    if (res.success && res.assets != null) {
      assets = res.assets!;
      notifyListeners();
    }
  }

  Future<void> loadState() async {
    loading = true;
    error = null;
    notifyListeners();
    final res = await _fetchState();
    loading = false;
    if (res.success && res.state != null) {
      state = res.state!;
      petExpression = state.mascotMood;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<bool> feedPet() async {
    final res = await _feed();
    if (res.success && res.state != null) {
      state = res.state!;
      petExpression = 'eat';
      lastMessage = res.message ?? res.action?.message;
      notifyListeners();
      return true;
    }
    lastMessage = res.message;
    notifyListeners();
    return false;
  }

  Future<bool> interactPet() async {
    final res = await _pet();
    if (res.success && res.state != null) {
      state = res.state!;
      petExpression = 'happy';
      lastMessage = res.message ?? res.action?.message;
      notifyListeners();
      return true;
    }
    lastMessage = res.message;
    notifyListeners();
    return false;
  }

  void onPetTapped() {
    petExpression = state.mascotMood == 'happy' ? 'wave' : 'happy';
    notifyListeners();
  }

  Future<void> loadMissions(String category) async {
    loading = true;
    notifyListeners();
    final res = await _fetchMissions(category);
    loading = false;
    if (res.success) {
      missions = res.missions;
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<void> loadCatalog(String? category) async {
    loading = true;
    notifyListeners();
    final res = await _fetchCatalog(category: category);
    loading = false;
    if (res.success) {
      catalog = res.catalog ?? [];
    } else {
      error = res.message;
    }
    notifyListeners();
  }

  Future<bool> buyItem(String sku) async {
    final res = await _purchase(sku);
    lastMessage = res.message;
    if (res.success) {
      await loadState();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> equipItem(String sku) async {
    final res = await _equip(sku);
    if (res.success && res.state != null) {
      state = res.state!;
      lastMessage = res.message;
      notifyListeners();
      return true;
    }
    lastMessage = res.message;
    notifyListeners();
    return false;
  }

  Future<bool> applyRoomTheme(String theme) async {
    final res = await _setRoomTheme(theme);
    if (res.success && res.state != null) {
      state = res.state!;
      notifyListeners();
      return true;
    }
    lastMessage = res.message;
    notifyListeners();
    return false;
  }
}
