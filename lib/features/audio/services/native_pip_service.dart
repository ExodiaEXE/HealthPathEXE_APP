import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// PiP Android native — ổn định hơn package `pip` trên emulator/máy thật.
abstract final class NativePipService {
  static const _channel = MethodChannel('vn.healthpath/pip');

  static final StreamController<bool> _pipModeController =
      StreamController<bool>.broadcast();

  static Stream<bool> get pipModeStream => _pipModeController.stream;

  static bool _inPipMode = false;
  static bool get inPipMode => _inPipMode;

  static bool _handlerReady = false;

  static void ensureInitialized() {
    if (!Platform.isAndroid) return;
    _ensureHandler();
  }

  static void _ensureHandler() {
    if (_handlerReady || !Platform.isAndroid) return;
    _handlerReady = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'willEnterPip':
        case 'pipModeChanged':
          _setInPipMode(call.arguments == true);
      }
    });
  }

  static void _setInPipMode(bool inPip) {
    if (_inPipMode == inPip) return;
    _inPipMode = inPip;
    _pipModeController.add(inPip);
  }

  static Future<bool> get isSupported async {
    if (!Platform.isAndroid) return false;
    _ensureHandler();
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get isInPipMode async {
    if (!Platform.isAndroid) return inPipMode;
    _ensureHandler();
    try {
      final native =
          await _channel.invokeMethod<bool>('isInPipMode') ?? inPipMode;
      _setInPipMode(native);
      return native;
    } catch (_) {
      return inPipMode;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    _ensureHandler();
    try {
      await _channel.invokeMethod<void>('setPipEnabled', enabled);
    } catch (_) {}
  }

  static Future<bool> enterPip() async {
    if (!Platform.isAndroid) return false;
    _ensureHandler();
    try {
      return await _channel.invokeMethod<bool>('enterPip') ?? false;
    } catch (_) {
      return false;
    }
  }
}
