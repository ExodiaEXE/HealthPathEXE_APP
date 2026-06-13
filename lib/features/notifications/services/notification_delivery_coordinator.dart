import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/core/navigation/app_navigator.dart';
import 'package:health/domain/entities/notification_entities.dart';
import 'package:health/domain/usecases/notification/notification_usecases.dart';
import 'package:health/features/notifications/services/notification_polling_service.dart';
import 'package:health/features/notifications/services/notification_realtime_service.dart';
import 'package:health/features/notifications/services/push_notification_service.dart';
import 'package:health/shared/widgets/app_snackbar.dart';

typedef NotificationDeliveryCallback = bool Function(NotificationRecord record);

/// Điều phối SignalR + poll fallback + local alert sau khi user đăng nhập.
abstract final class NotificationDeliveryCoordinator {
  static RegisterDeviceTokenUseCase? _registerToken;
  static RemoveDeviceTokenUseCase? _removeToken;
  static FetchNotificationsUseCase? _fetchNotifications;
  static Future<String?> Function()? _readAccessToken;

  static final NotificationRealtimeService _realtime =
      NotificationRealtimeService();
  static final NotificationPollingService _polling =
      NotificationPollingService();

  static StreamSubscription<String?>? _tokenRefreshSub;
  static NotificationDeliveryCallback? _onNotification;
  static String? _registeredFcmToken;
  static bool _pushInitialized = false;

  static void configure({
    required RegisterDeviceTokenUseCase registerToken,
    required RemoveDeviceTokenUseCase removeToken,
    required FetchNotificationsUseCase fetchNotifications,
    required Future<String?> Function() readAccessToken,
  }) {
    _registerToken = registerToken;
    _removeToken = removeToken;
    _fetchNotifications = fetchNotifications;
    _readAccessToken = readAccessToken;
  }

  static Future<void> ensurePushInitialized() async {
    if (_pushInitialized) return;
    _pushInitialized = await PushNotificationService.initialize(
      onForegroundMessage: _handleRemoteMessage,
    );
  }

  static Future<void> start({
    required NotificationDeliveryCallback onNotification,
  }) async {
    if (EnvConfig.useMockBackend) return;

    _onNotification = onNotification;
    await ensurePushInitialized();

    final accessToken = await _readAccessToken?.call();
    if (accessToken == null || accessToken.isEmpty) return;

    await _connectRealtime(accessToken);
    _startPolling(onNotification);
    await _registerFcmTokenIfNeeded();
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub =
        PushNotificationService.tokenRefreshStream().listen((token) {
      if (token != null && token.isNotEmpty) {
        unawaited(_registerFcmToken(token));
      }
    });
  }

  static Future<void> stop() async {
    _onNotification = null;
    _polling.stop();
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _realtime.disconnect();

    final token = _registeredFcmToken;
    _registeredFcmToken = null;
    if (token != null && token.isNotEmpty) {
      await _removeToken?.call(token);
    }
  }

  static void _startPolling(NotificationDeliveryCallback onNotification) {
    final fetch = _fetchNotifications;
    if (fetch == null || !fetch.isOnline) return;
    _polling.start(
      fetch: fetch,
      onNew: (record) => _deliver(record, fromPoll: true),
    );
  }

  static Future<void> _connectRealtime(String accessToken) async {
    try {
      await _realtime.connect(
        accessToken: accessToken,
        onNotification: _handleRealtimePayload,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationDeliveryCoordinator: SignalR failed — $e');
      }
    }
  }

  static Future<void> _registerFcmTokenIfNeeded() async {
    if (!PushNotificationService.fcmAvailable) return;
    final token = await PushNotificationService.requestPermissionAndGetToken();
    if (token == null || token.isEmpty) return;
    await _registerFcmToken(token);
  }

  static Future<void> _registerFcmToken(String token) async {
    final register = _registerToken;
    if (register == null || !register.isOnline) return;
    if (_registeredFcmToken == token) return;

    final res = await register(
      token: token,
      platform: Platform.isAndroid ? 'android' : 'ios',
      deviceName: Platform.operatingSystem,
    );
    if (res.success) {
      _registeredFcmToken = token;
    }
  }

  static void _handleRealtimePayload(Map<String, dynamic> json) {
    _deliver(NotificationRecord.fromJson(json));
  }

  static void _handleRemoteMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('id') || data.containsKey('title')) {
      _deliver(NotificationRecord.fromJson({
        'id': data['id'] ?? message.messageId ?? '',
        'type': data['type'] ?? 'promotion',
        'title': message.notification?.title ?? data['title'] ?? 'HealthPath',
        'body': message.notification?.body ?? data['body'] ?? '',
        'isRead': false,
        'sentAt': DateTime.now().toIso8601String(),
        'data': data['data'] ?? '{}',
      }));
      return;
    }
    _deliver(NotificationRecord(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'promotion',
      title: message.notification?.title ?? 'HealthPath',
      body: message.notification?.body ?? '',
      isRead: false,
      sentAt: DateTime.now(),
    ));
  }

  static void _deliver(NotificationRecord record, {bool fromPoll = false}) {
    final added = _onNotification?.call(record) ?? false;
    if (!added) return;

    unawaited(
      PushNotificationService.showInAppAlert(
        title: record.title,
        body: record.body,
      ),
    );
    final ctx = AppNavigator.key.currentContext;
    if (ctx != null && ctx.mounted) {
      AppSnackBar.show(ctx, '${record.title}\n${record.body}');
    } else if (kDebugMode && fromPoll) {
      debugPrint('NotificationDeliveryCoordinator: delivered via poll');
    }
  }
}
