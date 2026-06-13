import 'package:health/domain/entities/companion_entities.dart';
import 'package:health/domain/repositories/companion_repository.dart';

class FetchCompanionStateUseCase {
  const FetchCompanionStateUseCase(this._repo);
  final CompanionRepository _repo;
  bool get isOnline => _repo.isOnline;
  Future<CompanionOperationResult> call() => _repo.fetchState();
}

class FeedCompanionUseCase {
  const FeedCompanionUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call() => _repo.feed();
}

class PetCompanionUseCase {
  const PetCompanionUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call() => _repo.pet();
}

class FetchCompanionMissionsUseCase {
  const FetchCompanionMissionsUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call(String category) =>
      _repo.fetchMissions(category);
}

class FetchCompanionCatalogUseCase {
  const FetchCompanionCatalogUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call({String? category}) =>
      _repo.fetchCatalog(category);
}

class PurchaseCompanionItemUseCase {
  const PurchaseCompanionItemUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call(String sku) => _repo.purchase(sku);
}

class EquipCompanionItemUseCase {
  const EquipCompanionItemUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call(String sku) => _repo.equip(sku);
}

class SetCompanionRoomThemeUseCase {
  const SetCompanionRoomThemeUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call(String theme) =>
      _repo.setRoomTheme(theme);
}

class FetchCompanionAssetsUseCase {
  const FetchCompanionAssetsUseCase(this._repo);
  final CompanionRepository _repo;
  Future<CompanionOperationResult> call() => _repo.fetchAssets();
}
