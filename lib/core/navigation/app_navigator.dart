import 'package:flutter/material.dart';

/// Navigator gốc — dùng hiển thị toast / điều hướng từ service (FCM, SignalR).
abstract final class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}
