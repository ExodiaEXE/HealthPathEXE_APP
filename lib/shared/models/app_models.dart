enum AuthState { login, register, authenticated }

enum AuthProviderType { email, google, facebook }

enum ActiveTab { home, audio, companion, team, settings }

enum EnergyLevel { low, medium, high }

enum PaymentStep { plan, processing, success }

enum SettingsView {
  main,
  editProfile,
  changePassword,
  notifications,
  notificationInbox,
  history,
  wallet,
}

class PremiumInfo {
  const PremiumInfo({
    required this.productId,
    required this.productName,
    required this.benefits,
    required this.amountVnd,
    required this.paidWith,
    required this.paidAt,
    required this.expiresAt,
  });

  final String productId;
  final String productName;
  final List<String> benefits;
  final int amountVnd;
  final String paidWith;
  final DateTime paidAt;
  final DateTime expiresAt;
}

class HabitRecord {
  const HabitRecord({
    required this.date,
    required this.habits,
    this.energyLevel,
    this.rating,
  });

  final String date;
  final List<HabitItem> habits;
  final EnergyLevel? energyLevel;
  final int? rating;

  Map<String, dynamic> toJson() => {
        'date': date,
        'habits': habits.map((h) => h.toJson()).toList(),
        if (energyLevel != null) 'energyLevel': energyLevel!.name,
        if (rating != null) 'rating': rating,
      };

  factory HabitRecord.fromJson(Map<String, dynamic> json) => HabitRecord(
        date: json['date'] as String? ?? '',
        habits: (json['habits'] as List<dynamic>? ?? [])
            .map((e) => HabitItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        energyLevel: _energyFromName(json['energyLevel'] as String?),
        rating: json['rating'] as int?,
      );
}

class HabitItem {
  const HabitItem({required this.id, required this.text, this.done = false});

  final String id;
  final String text;
  final bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
      };

  factory HabitItem.fromJson(Map<String, dynamic> json) => HabitItem(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        done: json['done'] == true,
      );
}

EnergyLevel? _energyFromName(String? value) {
  if (value == null) return null;
  for (final level in EnergyLevel.values) {
    if (level.name == value) return level;
  }
  return null;
}

class UserProfile {
  const UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.email = 'user@healthpath.vn',
    this.phone = '',
    this.dob = '',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String dob;

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? dob,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
    );
  }

  bool get isComplete =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      phone.isNotEmpty &&
      dob.isNotEmpty;

  /// Tên hiển thị (họ + tên) — không dùng username/email tài khoản.
  String get displayName {
    final full = '$lastName $firstName'.trim();
    return full;
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'dob': dob,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? 'user@healthpath.vn',
        phone: json['phone'] as String? ?? '',
        dob: json['dob'] as String? ?? '',
      );
}

class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.text,
    this.category = 'other',
  });

  final String id;
  final String text;
  final String category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (category != 'other') 'category': category,
      };

  factory RoutineItem.fromJson(Map<String, dynamic> json) => RoutineItem(
        id: (json['id'] as String).toLowerCase(),
        text: json['text'] as String,
        category: (json['category'] as String?)?.toLowerCase() ?? 'other',
      );

  RoutineItem copyWith({String? id, String? text, String? category}) =>
      RoutineItem(
        id: id ?? this.id,
        text: text ?? this.text,
        category: category ?? this.category,
      );
}

class RoutineSuggestion {
  const RoutineSuggestion({
    required this.id,
    required this.text,
    required this.icon,
    required this.note,
  });

  final String id;
  final String text;
  final String icon;
  final String note;
}

class MoodTrack {
  const MoodTrack({
    required this.title,
    required this.artist,
    required this.emoji,
    required this.color,
    required this.category,
  });

  final String title;
  final String artist;
  final String emoji;
  final int color;
  final String category;
}

class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.color,
    required this.emoji,
    required this.categories,
    required this.recommendFor,
  });

  final int id;
  final String title;
  final String artist;
  final String duration;
  final int color;
  final String emoji;
  final List<String> categories;
  final List<EnergyLevel> recommendFor;
}
