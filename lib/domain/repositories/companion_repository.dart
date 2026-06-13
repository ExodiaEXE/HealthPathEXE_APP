import 'package:health/domain/entities/companion_entities.dart';

abstract class CompanionRepository {
  bool get isOnline;

  Future<CompanionOperationResult> fetchState();
  Future<CompanionOperationResult> feed();
  Future<CompanionOperationResult> pet();
  Future<CompanionOperationResult> fetchMissions(String category);
  Future<CompanionOperationResult> fetchCatalog(String? category);
  Future<CompanionOperationResult> purchase(String sku);
  Future<CompanionOperationResult> equip(String sku);
  Future<CompanionOperationResult> setRoomTheme(String theme);
  Future<CompanionOperationResult> fetchAssets();
}
