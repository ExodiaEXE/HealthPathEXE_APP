import 'package:health/domain/entities/notification_entities.dart';

abstract class NotificationRepository {
  bool get isOnline;

  Future<NotificationOperationResult> fetchNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  });

  Future<NotificationOperationResult> getUnreadCount();

  Future<NotificationOperationResult> markAsRead(String id);

  Future<NotificationOperationResult> markAllAsRead();

  Future<NotificationOperationResult> deleteNotification(String id);

  Future<NotificationOperationResult> getSettings();

  Future<NotificationOperationResult> updateSettings(
    NotificationSettingsRecord settings,
  );

  Future<NotificationOperationResult> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceName,
  });

  Future<NotificationOperationResult> removeDeviceToken(String token);
}
