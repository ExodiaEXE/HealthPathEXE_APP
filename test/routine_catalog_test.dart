import 'package:flutter_test/flutter_test.dart';
import 'package:health/core/constants/routine_catalog.dart';
import 'package:health/domain/entities/routine_entities.dart';

void main() {
  final catalog = [
    const RoutineModel(
      id: '1',
      title: 'Yoga buổi sáng cơ bản',
      category: 'yoga',
      difficulty: 'medium',
      durationMinutes: 15,
    ),
    const RoutineModel(
      id: '2',
      title: 'Đọc sách 15 phút',
      category: 'reading',
      difficulty: 'easy',
      durationMinutes: 15,
    ),
    const RoutineModel(
      id: '3',
      title: 'Thiền 5 phút',
      category: 'meditation',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    const RoutineModel(
      id: '4',
      title: 'Ghi nhật ký cảm xúc',
      category: 'reading',
      difficulty: 'easy',
      durationMinutes: 10,
    ),
    const RoutineModel(
      id: '5',
      title: 'Uống 1 ly nước sau khi thức dậy',
      category: 'other',
      difficulty: 'easy',
      durationMinutes: 2,
    ),
    const RoutineModel(
      id: '6',
      title: 'Giãn cơ cổ – vai tại bàn',
      category: 'exercise',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    const RoutineModel(
      id: '7',
      title: 'Nghe podcast 10 phút',
      category: 'reading',
      difficulty: 'easy',
      durationMinutes: 10,
    ),
    const RoutineModel(
      id: '8',
      title: 'Đi bộ nhẹ 10 phút',
      category: 'exercise',
      difficulty: 'easy',
      durationMinutes: 10,
    ),
    const RoutineModel(
      id: '9',
      title: 'Thở bụng 5 phút',
      category: 'breathing',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    const RoutineModel(
      id: '10',
      title: 'Viết mục tiêu 3 việc hôm nay',
      category: 'other',
      difficulty: 'easy',
      durationMinutes: 5,
    ),
    const RoutineModel(
      id: '11',
      title: 'Nghe nhạc thư giãn',
      category: 'other',
      difficulty: 'easy',
      durationMinutes: 10,
    ),
    const RoutineModel(
      id: '12',
      title: 'Plank giữ 1 phút',
      category: 'exercise',
      difficulty: 'hard',
      durationMinutes: 3,
    ),
  ];

  test('mệt + năng lượng thấp — ưu tiên yoga, thiền, thở, nhạc, nước', () {
    final picks = RoutineCatalog.pickHomeHighlights(
      catalog,
      energyKey: 'low',
      mood: 0,
    );
    expect(picks.length, 5);
    expect(picks[0].title, contains('Yoga'));
    expect(picks[1].title, contains('Thiền'));
    expect(picks[2].title, contains('Thở'));
    expect(picks[3].title, contains('nhạc'));
    expect(picks[4].title, contains('nước'));
  });

  test('căng thẳng + năng lượng cao — ưu tiên plank, đi bộ, giãn cơ', () {
    final picks = RoutineCatalog.pickHomeHighlights(
      catalog,
      energyKey: 'high',
      mood: 2,
    );
    expect(picks.length, 5);
    expect(picks[0].title, contains('Plank'));
    expect(picks[1].title, contains('Đi bộ'));
    expect(picks[2].title, contains('Giãn cơ'));
  });

  test('slot indices khớp remove-companion', () {
    expect(
      RoutineCatalog.suggestionSlotIndices(energyKey: 'medium', mood: null),
      [1, 3, 5, 7, 9],
    );
    expect(
      RoutineCatalog.suggestionSlotIndices(energyKey: null, mood: 1),
      [1, 3, 5, 7, 9],
    );
  });
}
