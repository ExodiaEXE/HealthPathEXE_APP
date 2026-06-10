import 'package:flutter/material.dart';
import 'package:health/app/app_shell.dart';
import 'package:health/core/constants/app_colors.dart';
import 'package:health/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

/// Khởi động app: thử khôi phục phiên JWT qua use case domain.
class SessionBootstrap extends StatefulWidget {
  const SessionBootstrap({super.key});

  @override
  State<SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends State<SessionBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final app = context.read<AppStateProvider>();
    await app.tryRestoreSession();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    return const AppShell();
  }
}
