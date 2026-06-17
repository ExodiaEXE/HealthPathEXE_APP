import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// SignalR hub client tối giản — hỗ trợ cert dev (10.0.2.2 / localhost).
class NotificationHubClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  static const _recordSeparator = '\u001e';

  bool get isConnected => _channel != null;

  Future<void> connect({
    required String hubUrl,
    required void Function(Map<String, dynamic> payload) onNotification,
  }) async {
    await disconnect();

    final wsUrl = hubUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    HttpClient? customClient;
    if (!kIsWeb) {
      customClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) {
          final h = host.toLowerCase();
          return h == 'localhost' ||
              h == '10.0.2.2' ||
              h.startsWith('127.') ||
              h.startsWith('192.168.');
        };
    }

    final uri = Uri.parse(wsUrl);

    final socket = await WebSocket.connect(
      uri.toString(),
      customClient: customClient,
    );
    _channel = IOWebSocketChannel(socket);

    _channel!.sink.add('{"protocol":"json","version":1}$_recordSeparator');

    _sub = _channel!.stream.listen(
      (data) => _onData(data, onNotification),
      onError: (Object e) {
        if (kDebugMode) debugPrint('NotificationHubClient: stream error — $e');
      },
      onDone: () {
        if (kDebugMode) debugPrint('NotificationHubClient: disconnected');
      },
    );
  }

  void _onData(
    dynamic data,
    void Function(Map<String, dynamic> payload) onNotification,
  ) {
    final text = switch (data) {
      String s => s,
      List<int> bytes => utf8.decode(bytes),
      _ => data.toString(),
    };

    for (final part in text.split(_recordSeparator)) {
      if (part.trim().isEmpty) continue;
      try {
        final msg = jsonDecode(part) as Map<String, dynamic>;
        final type = msg['type'] as int?;
        switch (type) {
          case 1: // Invocation
            if (msg['target'] == 'ReceiveNotification') {
              final args = msg['arguments'] as List<dynamic>?;
              final raw = args?.isNotEmpty == true ? args!.first : null;
              if (raw is Map) {
                onNotification(Map<String, dynamic>.from(raw));
              }
            }
          case 6: // Ping
            _channel?.sink.add('{"type":6}$_recordSeparator');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationHubClient: parse — $e');
      }
    }
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
