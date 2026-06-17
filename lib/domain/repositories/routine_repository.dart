import 'package:health/domain/entities/routine_entities.dart';

abstract class RoutineRepository {
  bool get isOnline;

  Future<List<RoutineModel>> fetchAllRoutines();
}
