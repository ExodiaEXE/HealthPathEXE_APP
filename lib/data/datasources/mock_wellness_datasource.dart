import 'package:health/shared/models/app_models.dart';

/// Nguồn dữ liệu wellness cục bộ (mock) — chỉ tầng data được phép truy cập.
abstract final class MockWellnessDataSource {
  static const habitsByEnergy = {
    EnergyLevel.low: [
      RoutineItem(id: 'l1', text: 'Thở sâu 3 phút'),
      RoutineItem(id: 'l2', text: 'Nhắm mắt thư giãn'),
      RoutineItem(id: 'l3', text: 'Nghe nhạc nhẹ 5 phút'),
    ],
    EnergyLevel.medium: [
      RoutineItem(id: 'm1', text: 'Giãn cơ cổ tại bàn'),
      RoutineItem(id: 'm2', text: 'Đi bộ 5 phút'),
      RoutineItem(id: 'm3', text: 'Viết 3 điều biết ơn'),
    ],
    EnergyLevel.high: [
      RoutineItem(id: 'h1', text: 'Giãn cơ toàn thân'),
      RoutineItem(id: 'h2', text: 'Đi bộ 15 phút'),
      RoutineItem(id: 'h3', text: 'Tập thể dục 10 phút'),
    ],
  };

  static const routineSuggestionPool = [
    RoutineSuggestion(id: 'rs1', text: 'Tập yoga 10 phút', icon: 'yoga', note: 'Tốt cho giảm căng thẳng'),
    RoutineSuggestion(id: 'rs2', text: 'Đọc sách 15 phút', icon: 'book', note: 'Thư giãn trí óc'),
    RoutineSuggestion(id: 'rs3', text: 'Thiền 5 phút', icon: 'brain', note: 'Tăng tập trung'),
    RoutineSuggestion(id: 'rs4', text: 'Ghi nhật ký', icon: 'pencil', note: 'Giải tỏa cảm xúc'),
    RoutineSuggestion(id: 'rs5', text: 'Uống nước ấm', icon: 'cup', note: 'Khởi động cơ thể'),
    RoutineSuggestion(id: 'rs6', text: 'Giãn cơ 5 phút', icon: 'stretch', note: 'Giảm đau cơ'),
    RoutineSuggestion(id: 'rs7', text: 'Nghe podcast', icon: 'headphones', note: 'Học điều mới'),
    RoutineSuggestion(id: 'rs8', text: 'Đi dạo 10 phút', icon: 'walk', note: 'Nâng cao năng lượng'),
    RoutineSuggestion(id: 'rs9', text: 'Tập thở bụng', icon: 'wind', note: 'Bình tĩnh tâm trí'),
    RoutineSuggestion(id: 'rs10', text: 'Viết mục tiêu ngày', icon: 'target', note: 'Định hướng rõ ràng'),
    RoutineSuggestion(id: 'rs11', text: 'Nghe nhạc thư giãn', icon: 'music', note: 'Giảm lo âu'),
    RoutineSuggestion(id: 'rs12', text: 'Tập plank 1 phút', icon: 'dumbbell', note: 'Tăng sức bền'),
  ];

  static const suggestionEmojis = {
    'yoga': '🧘',
    'book': '📚',
    'brain': '🧠',
    'pencil': '✏️',
    'cup': '☕',
    'stretch': '🧘',
    'headphones': '🎧',
    'walk': '🚶',
    'wind': '🌬️',
    'target': '🎯',
    'music': '🎵',
    'dumbbell': '🏋️',
  };

  static const moodTracks = {
    0: [
      MoodTrack(title: 'Tiếng mưa tĩnh lặng', artist: 'Âm thanh thiên nhiên', emoji: '🌧️', color: 0xFF4A90C8, category: 'Nhẹ nhàng'),
      MoodTrack(title: 'Piano buổi sáng', artist: 'Phím & Tâm hồn', emoji: '🎹', color: 0xFF8A7EC8, category: 'Thư giãn'),
      MoodTrack(title: 'Không gian yên tĩnh', artist: 'Không gian ambient', emoji: '✨', color: 0xFF8A7EC8, category: 'Không gian'),
    ],
    1: [
      MoodTrack(title: 'Guitar nhẹ nhàng', artist: 'Phòng thu acoustic', emoji: '🎸', color: 0xFF7AB86D, category: 'Guitar'),
      MoodTrack(title: 'Sóng biển ban mai', artist: 'Studio đại dương', emoji: '🌊', color: 0xFFD4855A, category: 'Thiên nhiên'),
      MoodTrack(title: 'Tiếng chim ban mai', artist: 'Âm thanh thiên nhiên', emoji: '🐦', color: 0xFF7AB86D, category: 'Thiên nhiên'),
    ],
    2: [
      MoodTrack(title: 'Giai điệu thiền sâu', artist: 'Đài thiền', emoji: '🧘', color: 0xFF5B8C4A, category: 'Thiền'),
      MoodTrack(title: 'Nhịp thở cân bằng', artist: 'Đài thiền', emoji: '💮', color: 0xFF5B8C4A, category: 'Thiền'),
      MoodTrack(title: 'Tiếng suối chảy', artist: 'Âm thanh thiên nhiên', emoji: '🌿', color: 0xFF4A90C8, category: 'Thiên nhiên'),
    ],
  };

  static const moods = [
    (emoji: '😩', label: 'Mệt'),
    (emoji: '😐', label: 'Ổn'),
    (emoji: '😤', label: 'Căng thẳng'),
  ];

  static const energyOptions = [
    (level: EnergyLevel.low, label: 'Mệt', emoji: '🥱'),
    (level: EnergyLevel.medium, label: 'Ổn', emoji: '😌'),
    (level: EnergyLevel.high, label: 'Tràn đầy', emoji: '💪'),
  ];

  static const weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  static const allTracks = [
    AudioTrack(id: 1, title: 'Tiếng mưa tĩnh lặng', artist: 'Âm thanh thiên nhiên', duration: '5:30', color: 0xFF4A90C8, emoji: '🌧️', categories: ['nature', 'soft'], recommendFor: [EnergyLevel.low]),
    AudioTrack(id: 2, title: 'Giai điệu thiền sâu', artist: 'Đài thiền', duration: '8:15', color: 0xFF5B8C4A, emoji: '🧘', categories: ['meditation'], recommendFor: [EnergyLevel.low, EnergyLevel.medium]),
    AudioTrack(id: 3, title: 'Sóng biển ban mai', artist: 'Studio đại dương', duration: '6:45', color: 0xFFD4855A, emoji: '🌊', categories: ['nature', 'ambient'], recommendFor: [EnergyLevel.medium]),
    AudioTrack(id: 4, title: 'Guitar nhẹ nhàng', artist: 'Phòng thu acoustic', duration: '4:20', color: 0xFF7AB86D, emoji: '🎸', categories: ['acoustic', 'soft'], recommendFor: [EnergyLevel.medium, EnergyLevel.high]),
    AudioTrack(id: 5, title: 'Piano buổi sáng', artist: 'Phím & Tâm hồn', duration: '5:00', color: 0xFF8A7EC8, emoji: '🎹', categories: ['soft', 'acoustic'], recommendFor: [EnergyLevel.low, EnergyLevel.medium]),
    AudioTrack(id: 6, title: 'Tiếng suối chảy', artist: 'Âm thanh thiên nhiên', duration: '7:10', color: 0xFF4A90C8, emoji: '🌿', categories: ['nature', 'ambient'], recommendFor: [EnergyLevel.low]),
    AudioTrack(id: 7, title: 'Nhịp thở cân bằng', artist: 'Đài thiền', duration: '10:00', color: 0xFF5B8C4A, emoji: '💮', categories: ['meditation'], recommendFor: [EnergyLevel.low, EnergyLevel.medium]),
    AudioTrack(id: 8, title: 'Ukulele vui tươi', artist: 'Phòng thu acoustic', duration: '3:45', color: 0xFFD4855A, emoji: '🎵', categories: ['acoustic'], recommendFor: [EnergyLevel.high]),
    AudioTrack(id: 9, title: 'Không gian yên tĩnh', artist: 'Không gian ambient', duration: '12:00', color: 0xFF8A7EC8, emoji: '✨', categories: ['ambient', 'meditation'], recommendFor: [EnergyLevel.low]),
    AudioTrack(id: 10, title: 'Tiếng chim ban mai', artist: 'Âm thanh thiên nhiên', duration: '6:00', color: 0xFF7AB86D, emoji: '🐦', categories: ['nature'], recommendFor: [EnergyLevel.medium, EnergyLevel.high]),
  ];

  static const audioCategories = [
    (id: 'all', label: 'Tất cả', emoji: '🎶'),
    (id: 'soft', label: 'Nhẹ nhàng', emoji: '🌸'),
    (id: 'nature', label: 'Thiên nhiên', emoji: '🌿'),
    (id: 'meditation', label: 'Thiền', emoji: '🧘'),
    (id: 'acoustic', label: 'Guitar', emoji: '🎸'),
    (id: 'ambient', label: 'Không gian', emoji: '🌌'),
  ];

  static const teamMembers = [
    (id: 1, name: 'Thành viên 1', score: 6, avatar: 'T1', streak: 5, isMe: false),
    (id: 2, name: 'Thành viên 2', score: 5, avatar: 'T2', streak: 3, isMe: false),
    (id: 3, name: 'Bạn', score: 4, avatar: 'BN', streak: 5, isMe: true),
    (id: 4, name: 'Thành viên 3', score: 3, avatar: 'T3', streak: 2, isMe: false),
  ];

  static const existingGroups = [
    (id: 'g1', name: 'Sức khỏe mỗi ngày', members: 8, emoji: '🌿'),
    (id: 'g2', name: 'Yoga & Thiền', members: 5, emoji: '🧘'),
    (id: 'g3', name: 'Chạy bộ Sài Gòn', members: 12, emoji: '🏃'),
    (id: 'g4', name: 'Ăn uống lành mạnh', members: 6, emoji: '🥗'),
    (id: 'g5', name: 'Dậy sớm cùng nhau', members: 4, emoji: '🌅'),
  ];

  static List<HabitRecord> generateMockHistory() {
    final records = <HabitRecord>[];
    final habits = [
      [const HabitItem(id: 'h-d1-1', text: 'Thở sâu 3 phút', done: true), const HabitItem(id: 'h-d1-2', text: 'Nhắm mắt thư giãn', done: true)],
      [const HabitItem(id: 'h-d2-1', text: 'Giãn cơ cổ tại bàn', done: true), const HabitItem(id: 'h-d2-2', text: 'Đi bộ 5 phút')],
      [const HabitItem(id: 'h-d3-1', text: 'Giãn cơ toàn thân', done: true), const HabitItem(id: 'h-d3-2', text: 'Đi bộ 15 phút', done: true)],
    ];
    const energies = [EnergyLevel.low, EnergyLevel.medium, EnergyLevel.high];
    for (var i = 3; i >= 1; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      records.add(HabitRecord(
        date: '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        habits: habits[3 - i],
        energyLevel: energies[3 - i],
        rating: 3 + (i % 3),
      ));
    }
    return records;
  }

  static List<RoutineSuggestion> getRoutineSuggestions(EnergyLevel? energy, int? mood) {
    final pool = List<RoutineSuggestion>.from(routineSuggestionPool);
    if (mood == 0 && energy == EnergyLevel.low) {
      return [pool[0], pool[2], pool[8], pool[10], pool[4]];
    }
    if (mood == 0) return [pool[0], pool[2], pool[4], pool[8], pool[10]];
    if (mood == 2 && energy == EnergyLevel.high) {
      return [pool[11], pool[7], pool[5], pool[9], pool[1]];
    }
    if (mood == 2) return [pool[3], pool[8], pool[5], pool[9], pool[2]];
    if (energy == EnergyLevel.low) return [pool[0], pool[2], pool[4], pool[8], pool[10]];
    if (energy == EnergyLevel.medium) return [pool[1], pool[3], pool[5], pool[7], pool[9]];
    if (energy == EnergyLevel.high) return [pool[5], pool[7], pool[9], pool[11], pool[1]];
    if (mood == 1) return [pool[1], pool[3], pool[5], pool[7], pool[9]];
    return pool.take(5).toList();
  }
}
