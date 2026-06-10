import 'package:health/domain/entities/user_routine_entities.dart';

class CompleteRoutineResult {
  const CompleteRoutineResult({this.record, this.errorMessage, this.errorCode});

  final UserRoutineRecord? record;
  final String? errorMessage;
  final String? errorCode;

  bool get success => record != null;
}
