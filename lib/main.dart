import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/app/app_shell.dart';
import 'package:health/core/config/env_config.dart';
import 'package:health/core/security/jwt_auth_service.dart';
import 'package:health/core/security/secure_storage_service.dart';
import 'package:health/core/theme/app_theme.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final storage = SecureStorageService();
    final jwt = JwtAuthService(storage);

    return MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: storage),
        Provider<JwtAuthService>.value(value: jwt),
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(jwt),
        ),
      ],
      child: MaterialApp(
        title: 'HealthPath',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
        builder: (context, child) {
          if (EnvConfig.useMockBackend) return child!;
          return child!;
        },
      ),
    );
  }
}
