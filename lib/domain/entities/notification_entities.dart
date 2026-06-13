import 'package:flutter/material.dart';

class NotificationRecord {
  const NotificationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.sentAt,
    this.channel,
    this.data,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime sentAt;
  final String? channel;
  final String? data;

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] == true,
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      channel: json['channel'] as String?,
      data: json['data'] as String?,
    );
  }
}

class NotificationSettingsRecord {
  const NotificationSettingsRecord({
    this.dailyCheckin = true,
    this.streakReminder = true,
    this.groupActivity = true,
    this.challengeUpdates = true,
    this.promotions = true,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.inAppEnabled = true,
    this.quietFrom,
    this.quietUntil,
    this.soundEnabled = true,
  });

  final bool dailyCheckin;
  final bool streakReminder;
  final bool groupActivity;
  final bool challengeUpdates;
  final bool promotions;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final TimeOfDay? quietFrom;
  final TimeOfDay? quietUntil;
  final bool soundEnabled;

  factory NotificationSettingsRecord.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsRecord(
      dailyCheckin: json['dailyCheckin'] as bool? ?? true,
      streakReminder: json['streakReminder'] as bool? ?? true,
      groupActivity: json['groupActivity'] as bool? ?? true,
      challengeUpdates: json['challengeUpdates'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? true,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      inAppEnabled: json['inAppEnabled'] as bool? ?? true,
      quietFrom: _parseTime(json['quietFrom']),
      quietUntil: _parseTime(json['quietUntil']),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'dailyCheckin': dailyCheckin,
        'streakReminder': streakReminder,
        'groupActivity': groupActivity,
        'challengeUpdates': challengeUpdates,
        'promotions': promotions,
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'inAppEnabled': inAppEnabled,
        if (quietFrom != null) 'quietFrom': _formatTime(quietFrom!),
        if (quietUntil != null) 'quietUntil': _formatTime(quietUntil!),
      };

  NotificationSettingsRecord copyWith({
    bool? dailyCheckin,
    bool? streakReminder,
    bool? groupActivity,
    bool? challengeUpdates,
    bool? promotions,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
    TimeOfDay? quietFrom,
    TimeOfDay? quietUntil,
    bool? soundEnabled,
    bool clearQuietFrom = false,
    bool clearQuietUntil = false,
  }) {
    return NotificationSettingsRecord(
      dailyCheckin: dailyCheckin ?? this.dailyCheckin,
      streakReminder: streakReminder ?? this.streakReminder,
      groupActivity: groupActivity ?? this.groupActivity,
      challengeUpdates: challengeUpdates ?? this.challengeUpdates,
      promotions: promotions ?? this.promotions,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      quietFrom: clearQuietFrom ? null : (quietFrom ?? this.quietFrom),
      quietUntil: clearQuietUntil ? null : (quietUntil ?? this.quietUntil),
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  static TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;
    final parts = value.toString().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}

class NotificationOperationResult {
  const NotificationOperationResult({
    required this.success,
    this.message,
    this.notifications = const [],
    this.settings,
    this.unreadCount = 0,
    this.totalItems = 0,
  });

  final bool success;
  final String? message;
  final List<NotificationRecord> notifications;
  final NotificationSettingsRecord? settings;
  final int unreadCount;
  final int totalItems;

  factory NotificationOperationResult.fail(String message) =>
      NotificationOperationResult(success: false, message: message);
}
