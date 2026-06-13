import 'package:health/domain/entities/notification_entities.dart';
import 'package:health/domain/repositories/notification_repository.dart';

class FetchNotificationsUseCase {
  const FetchNotificationsUseCase(this._repository);
  final NotificationRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<NotificationOperationResult> call({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.fetchNotifications(
        unreadOnly: unreadOnly,
        page: page,
        pageSize: pageSize,
      );
}

class GetUnreadNotificationCountUseCase {
  const GetUnreadNotificationCountUseCase(this._repository);
  final NotificationRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<NotificationOperationResult> call() => _repository.getUnreadCount();
}

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<NotificationOperationResult> call(String id) =>
      _repository.markAsRead(id);
}

class MarkAllNotificationsReadUseCase {
  const MarkAllNotificationsReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<NotificationOperationResult> call() => _repository.markAllAsRead();
}

class DeleteNotificationUseCase {
  const DeleteNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  Future<NotificationOperationResult> call(String id) =>
      _repository.deleteNotification(id);
}

class FetchNotificationSettingsUseCase {
  const FetchNotificationSettingsUseCase(this._repository);
  final NotificationRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<NotificationOperationResult> call() => _repository.getSettings();
}

class UpdateNotificationSettingsUseCase {
  const UpdateNotificationSettingsUseCase(this._repository);
  final NotificationRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<NotificationOperationResult> call(NotificationSettingsRecord settings) =>
      _repository.updateSettings(settings);
}

class RegisterDeviceTokenUseCase {
  const RegisterDeviceTokenUseCase(this._repository);
  final NotificationRepository _repository;
  bool get isOnline => _repository.isOnline;

  Future<NotificationOperationResult> call({
    required String token,
    required String platform,
    String? deviceName,
  }) =>
      _repository.registerDeviceToken(
        token: token,
        platform: platform,
        deviceName: deviceName,
      );
}

class RemoveDeviceTokenUseCase {
  const RemoveDeviceTokenUseCase(this._repository);
  final NotificationRepository _repository;

  Future<NotificationOperationResult> call(String token) =>
      _repository.removeDeviceToken(token);
}
