import 'package:flutter/foundation.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/features/notifications/services/notification_hub_client.dart';

/// Kết nối SignalR `/hubs/notification` — nhận `ReceiveNotification` real-time.
class NotificationRealtimeService {
  final NotificationHubClient _client = NotificationHubClient();

  bool get isConnected => _client.isConnected;

  Future<void> connect({
    required String accessToken,
    required void Function(Map<String, dynamic> payload) onNotification,
  }) async {
    await disconnect();

    if (EnvConfig.useMockBackend || accessToken.isEmpty) return;

    final base = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final hubUrl =
        '$base/hubs/notification?access_token=${Uri.encodeComponent(accessToken)}';

    try {
      await _client.connect(hubUrl: hubUrl, onNotification: onNotification);
      if (kDebugMode) {
        debugPrint('NotificationRealtimeService: connected');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationRealtimeService: connect failed — $e');
      }
      rethrow;
    }
  }

  Future<void> disconnect() => _client.disconnect();
}
