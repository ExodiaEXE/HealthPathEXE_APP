import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/domain/entities/notification_entities.dart';
import 'package:health/domain/usecases/notification/notification_usecases.dart';

/// Fallback khi SignalR không kết nối — poll inbox mỗi 15s.
class NotificationPollingService {
  Timer? _timer;
  final Set<String> _seenIds = {};
  bool _seeded = false;

  void start({
    required FetchNotificationsUseCase fetch,
    required void Function(NotificationRecord record) onNew,
  }) {
    stop();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_poll(fetch, onNew)),
    );
    unawaited(_poll(fetch, onNew, seedOnly: !_seeded));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll(
    FetchNotificationsUseCase fetch,
    void Function(NotificationRecord record) onNew, {
    bool seedOnly = false,
  }) async {
    if (!fetch.isOnline) return;
    try {
      final res = await fetch(page: 1, pageSize: 30);
      if (!res.success) return;

      if (seedOnly || !_seeded) {
        _seenIds.addAll(res.notifications.map((n) => n.id));
        _seeded = true;
        return;
      }

      for (final record in res.notifications) {
        if (record.id.isEmpty || _seenIds.contains(record.id)) continue;
        _seenIds.add(record.id);
        onNew(record);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationPollingService: poll failed — $e');
    }
  }
}
