import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:health/app/session_bootstrap.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/core/di/app_dependencies.dart';
import 'package:health/core/theme/app_theme.dart';
import 'package:health/core/theme/hp_scroll_behavior.dart';
import 'package:health/features/audio/services/audio_playback_coordinator.dart';
import 'package:health/features/audio/services/native_pip_service.dart';
import 'package:health/core/navigation/app_navigator.dart';
import 'package:health/features/notifications/services/push_notification_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await PushNotificationService.initialize();
  await AudioPlaybackCoordinator.ensureInitialized();
  NativePipService.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HealthPathApp());
}

class HealthPathApp extends StatelessWidget {
  const HealthPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.create();

    return MultiProvider(
      providers: deps.providers(),
      child: MaterialApp(
        title: 'HealthPath',
        navigatorKey: AppNavigator.key,
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        scrollBehavior: const HpScrollBehavior(),
        home: const SessionBootstrap(),
      ),
    );
  }
}

/// Hiển thị trong debug banner hoặc auth screen — biết app đang nối backend hay demo.
extension HealthPathMode on BuildContext {
  bool get isBackendConnected => !EnvConfig.useMockBackend;
}
