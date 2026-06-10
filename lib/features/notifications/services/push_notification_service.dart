import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications + FCM push (FCM tùy chọn khi có Firebase config).
abstract final class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _localReady = false;
  static bool _fcmReady = false;
  static String? _lastToken;
  static void Function(RemoteMessage message)? _foregroundHandler;

  static bool get isAvailable => _localReady;

  static bool get fcmAvailable => _fcmReady;

  static String? get lastToken => _lastToken;

  static Future<bool> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    if (_localReady) return true;
    _foregroundHandler = onForegroundMessage;

    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _local.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) {},
      );

      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'healthpath_alerts',
          'Thông báo HealthPath',
          description: 'Nhắc thói quen, streak và hoạt động nhóm',
          importance: Importance.high,
        );
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      _localReady = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: local init failed — $e');
      }
      return false;
    }

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleForegroundMessage);
      _fcmReady = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: FCM skipped — $e');
      }
    }

    return true;
  }

  static Future<String?> requestPermissionAndGetToken() async {
    if (!_fcmReady) return null;
    try {
      if (Platform.isAndroid) {
        await FirebaseMessaging.instance.requestPermission();
      } else {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      _lastToken = await FirebaseMessaging.instance.getToken();
      return _lastToken;
    } catch (e) {
      if (kDebugMode) debugPrint('PushNotificationService: token failed — $e');
      return null;
    }
  }

  static Stream<String?> tokenRefreshStream() {
    if (!_fcmReady) return const Stream.empty();
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  /// Hiển thị trên status bar (SignalR / poll — không cần FCM).
  static Future<void> showInAppAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_localReady) return;

    const androidDetails = AndroidNotificationDetails(
      'healthpath_alerts',
      'Thông báo HealthPath',
      channelDescription: 'Nhắc thói quen, streak và hoạt động nhóm',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    await _local.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> showLocalFromRemote(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'HealthPath';
    final body = notification?.body ?? message.data['body'] ?? '';
    await showInAppAlert(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    unawaited(showLocalFromRemote(message));
    _foregroundHandler?.call(message);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
