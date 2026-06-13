import 'package:health/core/network/api_client.dart';
import 'package:health/data/datasources/mock_wellness_datasource.dart';
import 'package:health/domain/entities/routine_entities.dart';
import 'package:health/domain/repositories/routine_repository.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  RoutineRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  @override
  bool get isOnline => _api.hasBaseUrl;

  @override
  Future<List<RoutineModel>> fetchAllRoutines() async {
    if (!isOnline) return _mockFromLocalPool();

    final all = <RoutineModel>[];
    var page = 1;
    while (true) {
      final res = await _api.getJson('/api/Routine?page=$page&pageSize=50');
      if (res.json['success'] != true) {
        throw ApiException(
          res.json['message'] as String? ?? 'Không tải được danh sách thói quen.',
        );
      }
      final data = res.json['data'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];
      all.addAll(
        items.map((e) => RoutineModel.fromJson(e as Map<String, dynamic>)),
      );
      if (data['hasNext'] != true) break;
      page++;
    }
    return all;
  }

  List<RoutineModel> _mockFromLocalPool() {
    return MockWellnessDataSource.routineSuggestionPool.map((s) {
      final cat = _guessCategory(s.text);
      return RoutineModel(
        id: s.id,
        title: s.text,
        description: s.note,
        category: cat,
        difficulty: 'easy',
        durationMinutes: 10,
      );
    }).toList();
  }

  String _guessCategory(String title) {
    final t = title.toLowerCase();
    if (t.contains('yoga')) return 'yoga';
    if (t.contains('thiền')) return 'meditation';
    if (t.contains('thở')) return 'breathing';
    if (t.contains('đọc') || t.contains('podcast')) return 'reading';
    if (t.contains('đi bộ') || t.contains('plank') || t.contains('giãn cơ')) {
      return 'exercise';
    }
    return 'other';
  }
}
