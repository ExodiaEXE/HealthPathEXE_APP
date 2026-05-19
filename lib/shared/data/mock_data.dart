import 'package:health/shared/models/app_models.dart';

abstract final class MockData {
  static const habitsByEnergy = {
    EnergyLevel.low: [
      RoutineItem(id: 'l1', text: 'Tho sau 3 phut'),
      RoutineItem(id: 'l2', text: 'Nham mat thu gian'),
      RoutineItem(id: 'l3', text: 'Nghe nhac nhe 5 phut'),
    ],
    EnergyLevel.medium: [
      RoutineItem(id: 'm1', text: 'Gian co co tai ban'),
      RoutineItem(id: 'm2', text: 'Di bo 5 phut'),
      RoutineItem(id: 'm3', text: 'Viet 3 dieu biet on'),
    ],
    EnergyLevel.high: [
      RoutineItem(id: 'h1', text: 'Gian co toan than'),
      RoutineItem(id: 'h2', text: 'Di bo 15 phut'),
      RoutineItem(id: 'h3', text: 'Tap the duc 10 phut'),
    ],
  };

  static const routineSuggestionPool = [
    RoutineSuggestion(id: 'rs1', text: 'Tap yoga 10 phut', icon: 'yoga', note: 'Tot cho giam cang thang'),
    RoutineSuggestion(id: 'rs2', text: 'Doc sach 15 phut', icon: 'book', note: 'Thu gian tri oc'),
    RoutineSuggestion(id: 'rs3', text: 'Thien 5 phut', icon: 'brain', note: 'Tang tap trung'),
    RoutineSuggestion(id: 'rs4', text: 'Ghi nhat ky', icon: 'pencil', note: 'Giai toa cam xuc'),
    RoutineSuggestion(id: 'rs5', text: 'Uong nuoc am', icon: 'cup', note: 'Khoi dong co the'),
    RoutineSuggestion(id: 'rs6', text: 'Gian co 5 phut', icon: 'stretch', note: 'Giam dau co'),
    RoutineSuggestion(id: 'rs7', text: 'Nghe podcast', icon: 'headphones', note: 'Hoc dieu moi'),
    RoutineSuggestion(id: 'rs8', text: 'Di dao 10 phut', icon: 'walk', note: 'Nang cao nang luong'),
    RoutineSuggestion(id: 'rs9', text: 'Tap tho bung', icon: 'wind', note: 'Binh tinh tam tri'),
    RoutineSuggestion(id: 'rs10', text: 'Viet muc tieu ngay', icon: 'target', note: 'Dinh huong ro rang'),
    RoutineSuggestion(id: 'rs11', text: 'Nghe nhac thu gian', icon: 'music', note: 'Giam lo au'),
    RoutineSuggestion(id: 'rs12', text: 'Tap plank 1 phut', icon: 'dumbbell', note: 'Tang suc ben'),
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
      MoodTrack(title: 'Tieng mua tinh lang', artist: 'Nature Sounds', emoji: '🌧️', color: 0xFF4A90C8, category: 'Nhe nhang'),
      MoodTrack(title: 'Piano buoi sang', artist: 'Keys & Soul', emoji: '🎹', color: 0xFF8A7EC8, category: 'Thu gian'),
      MoodTrack(title: 'Khong gian yen tinh', artist: 'Ambient World', emoji: '✨', color: 0xFF8A7EC8, category: 'Ambient'),
    ],
    1: [
      MoodTrack(title: 'Guitar nhe nhang', artist: 'Acoustic Lab', emoji: '🎸', color: 0xFF7AB86D, category: 'Acoustic'),
      MoodTrack(title: 'Song bien ban mai', artist: 'Ocean Studio', emoji: '🌊', color: 0xFFD4855A, category: 'Thien nhien'),
      MoodTrack(title: 'Tieng chim ban mai', artist: 'Nature Sounds', emoji: '🐦', color: 0xFF7AB86D, category: 'Thien nhien'),
    ],
    2: [
      MoodTrack(title: 'Giai dieu thien sau', artist: 'Meditation FM', emoji: '🧘', color: 0xFF5B8C4A, category: 'Thien'),
      MoodTrack(title: 'Nhip tho can bang', artist: 'Meditation FM', emoji: '💮', color: 0xFF5B8C4A, category: 'Thien'),
      MoodTrack(title: 'Tieng suoi chay', artist: 'Nature Sounds', emoji: '🌿', color: 0xFF4A90C8, category: 'Thien nhien'),
    ],
  };

  static const moods = [
    (emoji: '😩', label: 'Met'),
    (emoji: '😐', label: 'On'),
    (emoji: '😤', label: 'Cang thang'),
  ];

  static const energyOptions = [
    (level: EnergyLevel.low, label: 'Met', emoji: '🥱'),
    (level: EnergyLevel.medium, label: 'On', emoji: '😌'),
    (level: EnergyLevel.high, label: 'Tran day', emoji: '💪'),
  ];

  static const weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  static const allTracks = [
    AudioTrack(id: 1, title: 'Tieng mua tinh lang', artist: 'Nature Sounds', duration: '5:30', color: 0xFF4A90C8, emoji: '🌧️', categories: ['nature', 'soft'], recommendFor: [EnergyLevel.low]),
    AudioTrack(id: 2, title: 'Giai dieu thien sau', artist: 'Meditation FM', duration: '8:15', color: 0xFF5B8C4A, emoji: '🧘', categories: ['meditation'], recommendFor: [EnergyLevel.low, EnergyLevel.medium]),
    AudioTrack(id: 3, title: 'Song bien ban mai', artist: 'Ocean Studio', duration: '6:45', color: 0xFFD4855A, emoji: '🌊', categories: ['nature', 'ambient'], recommendFor: [EnergyLevel.medium]),
    AudioTrack(id: 4, title: 'Guitar nhe nhang', artist: 'Acoustic Lab', duration: '4:20', color: 0xFF7AB86D, emoji: '🎸', categories: ['acoustic', 'soft'], recommendFor: [EnergyLevel.medium, EnergyLevel.high]),
    AudioTrack(id: 5, title: 'Piano buoi sang', artist: 'Keys & Soul', duration: '5:00', color: 0xFF8A7EC8, emoji: '🎹', categories: ['soft', 'acoustic'], recommendFor: [EnergyLevel.low, EnergyLevel.medium]),
    AudioTrack(id: 6, title: 'Tieng suoi chay', artist: 'Nature Sounds', duration: '7:10', color: 0xFF4A90C8, emoji: '🌿', categories: ['nature', 'ambient'], recommendFor: [EnergyLevel.low]),
    AudioTrack(id: 7, title: 'Nhip tho can bang', artist: 'Meditation FM', duration: '10:00', color: 0xFF5B8C4A, emoji: '💮', categories: ['meditation'], recommendFor: [EnergyLevel.low, EnergyLevel.medium]),
    AudioTrack(id: 8, title: 'Ukulele vui tuoi', artist: 'Acoustic Lab', duration: '3:45', color: 0xFFD4855A, emoji: '🎵', categories: ['acoustic'], recommendFor: [EnergyLevel.high]),
    AudioTrack(id: 9, title: 'Khong gian yen tinh', artist: 'Ambient World', duration: '12:00', color: 0xFF8A7EC8, emoji: '✨', categories: ['ambient', 'meditation'], recommendFor: [EnergyLevel.low]),
    AudioTrack(id: 10, title: 'Tieng chim ban mai', artist: 'Nature Sounds', duration: '6:00', color: 0xFF7AB86D, emoji: '🐦', categories: ['nature'], recommendFor: [EnergyLevel.medium, EnergyLevel.high]),
  ];

  static const audioCategories = [
    ('all', 'Tat ca', '🎶'),
    ('soft', 'Nhe nhang', '🌸'),
    ('nature', 'Thien nhien', '🌿'),
    ('meditation', 'Thien', '🧘'),
    ('acoustic', 'Acoustic', '🎸'),
    ('ambient', 'Ambient', '🌌'),
  ];

  static const teamMembers = [
    (id: 1, name: 'Thanh vien 1', score: 6, avatar: 'T1', streak: 5, isMe: false),
    (id: 2, name: 'Thanh vien 2', score: 5, avatar: 'T2', streak: 3, isMe: false),
    (id: 3, name: 'Ban', score: 4, avatar: 'BN', streak: 5, isMe: true),
    (id: 4, name: 'Thanh vien 3', score: 3, avatar: 'T3', streak: 2, isMe: false),
  ];

  static const existingGroups = [
    (id: 'g1', name: 'Suc khoe moi ngay', members: 8, emoji: '🌿'),
    (id: 'g2', name: 'Yoga & Thien', members: 5, emoji: '🧘'),
    (id: 'g3', name: 'Chay bo Sai Gon', members: 12, emoji: '🏃'),
    (id: 'g4', name: 'Healthy Eating', members: 6, emoji: '🥗'),
    (id: 'g5', name: 'Early Birds', members: 4, emoji: '🌅'),
  ];

  static List<HabitRecord> generateMockHistory() {
    final records = <HabitRecord>[];
    final habits = [
      [const HabitItem(id: 'h-d1-1', text: 'Tho sau 3 phut', done: true), const HabitItem(id: 'h-d1-2', text: 'Nham mat thu gian', done: true)],
      [const HabitItem(id: 'h-d2-1', text: 'Gian co co tai ban', done: true), const HabitItem(id: 'h-d2-2', text: 'Di bo 5 phut')],
      [const HabitItem(id: 'h-d3-1', text: 'Gian co toan than', done: true), const HabitItem(id: 'h-d3-2', text: 'Di bo 15 phut', done: true)],
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
