enum AuthState { login, register, authenticated }

enum AuthProviderType { email, google, facebook }

enum ActiveTab { home, audio, team, settings }

enum EnergyLevel { low, medium, high }

enum PaymentStep { plan, method, input, otp, processing, success }

enum PaymentMethodType { momo, bank, visa }

enum SettingsView {
  main,
  editProfile,
  changePassword,
  notifications,
  history,
  wallet,
}

class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.maskedInfo,
    this.detail,
  });

  final String id;
  final PaymentMethodType type;
  final String label;
  final String maskedInfo;
  final String? detail;
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
}

class HabitItem {
  const HabitItem({required this.id, required this.text, this.done = false});

  final String id;
  final String text;
  final bool done;
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
}

class NotifSettings {
  const NotifSettings({this.pushEnabled = true, this.soundEnabled = true});

  final bool pushEnabled;
  final bool soundEnabled;

  NotifSettings copyWith({bool? pushEnabled, bool? soundEnabled}) {
    return NotifSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class RoutineItem {
  const RoutineItem({required this.id, required this.text});

  final String id;
  final String text;
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
